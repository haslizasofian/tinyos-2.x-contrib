/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 *
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */


/**
 * Active message implementation on top of the CC2420 radio. This
 * implementation uses the 16-bit addressing mode of 802.15.4: the
 * only additional byte it adds is the AM id byte, as the first byte
 * of the data payload.
 *
 * @author Philip Levis
 * @version $Revision$ $Date$
 */

#include "CC2420.h"

module CC2420ActiveMessageP @safe() {
  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface SendNotifier[am_id_t id];
    interface RadioBackoff[am_id_t id];
  }

  uses {
    interface Send as SubSend;
    interface Receive as SubReceive;
    interface CC2420Packet;
    interface CC2420PacketBody;
    interface CC2420Config;
    interface ActiveMessageAddress;
    interface RadioBackoff as SubBackoff;
  }
}
implementation {

  /***************** AMSend Commands ****************/
  command error_t AMSend.send[am_id_t id](am_addr_t addr,
					  message_t* msg,
					  uint8_t len) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader( msg );

    dbg("AM", "CC2420AM: AMSend.send()\n");

    if (len > call Packet.maxPayloadLength()) {
      return ESIZE;
    }

    //mab
    //header->length = 0xaf;
    //header->fcf = 0xfa;
    //header->fcf = 0x88cf;
    //

    header->type = id;
    header->dest = addr;
    header->destpan = call CC2420Config.getPanAddr();
    header->src = call AMPacket.address();

    signal SendNotifier.aboutToSend[id](addr, msg);

    //dbg("AM", "CC2420AM: AMSend.send()2\n");
    return call SubSend.send( msg, len );
  }

  command error_t AMSend.cancel[am_id_t id](message_t* msg) {
    return call SubSend.cancel(msg);
  }

  command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
    return call Packet.maxPayloadLength();
  }

  command void* AMSend.getPayload[am_id_t id](message_t* m, uint8_t len) {
    return call Packet.getPayload(m, len);
  }

  /***************** AMPacket Commands ****************/
  command am_addr_t AMPacket.address() {
    return call ActiveMessageAddress.amAddress();
  }

  command am_addr_t AMPacket.destination(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->dest;
  }

  command am_addr_t AMPacket.source(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->src;
  }

  command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->dest = addr;
  }

  command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->src = addr;
  }

  command bool AMPacket.isForMe(message_t* amsg) {
    return (call AMPacket.destination(amsg) == call AMPacket.address() ||
	    call AMPacket.destination(amsg) == AM_BROADCAST_ADDR);
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    return header->type;
  }

  command void AMPacket.setType(message_t* amsg, am_id_t type) {
    cc2420_header_t* header = call CC2420PacketBody.getHeader(amsg);
    header->type = type;
  }

  command am_group_t AMPacket.group(message_t* amsg) {
    return (call CC2420PacketBody.getHeader(amsg))->destpan;
  }

  command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {
    // Overridden intentionally when we send()
    (call CC2420PacketBody.getHeader(amsg))->destpan = grp;
  }

  command am_group_t AMPacket.localGroup() {
    return call CC2420Config.getPanAddr();
  }


  /***************** Packet Commands ****************/
  command void Packet.clear(message_t* msg) {
    memset(call CC2420PacketBody.getHeader(msg), 0x0, sizeof(cc2420_header_t));
    memset(call CC2420PacketBody.getMetadata(msg), 0x0, sizeof(cc2420_metadata_t));
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    return (call CC2420PacketBody.getHeader(msg))->length - CC2420_SIZE;
  }

  command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
    (call CC2420PacketBody.getHeader(msg))->length  = len + CC2420_SIZE;
  }

  command uint8_t Packet.maxPayloadLength() {
    return TOSH_DATA_LENGTH;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }


  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t* msg, error_t result) {
      //printf("CC2420: sim_signal_sendDone!!!!!!!\n");
    signal AMSend.sendDone[call AMPacket.type(msg)](msg, result);
  }


  /***************** SubReceive Events ****************/
  event message_t* SubReceive.receive(message_t* msg, void* payload, uint8_t len) {

    if(!(call CC2420PacketBody.getMetadata(msg))->crc) {
      return msg;
    }

    if (call AMPacket.isForMe(msg)) {
      return signal Receive.receive[call AMPacket.type(msg)](msg, payload, len);
    }
    else {
      return signal Snoop.receive[call AMPacket.type(msg)](msg, payload, len);
    }
  }


  /***************** ActiveMessageAddress Events ****************/
  async event void ActiveMessageAddress.changed() {
  }

  /***************** CC2420Config Events ****************/
  event void CC2420Config.syncDone( error_t error ) {
  }


  /***************** RadioBackoff ***********************/

  async event void SubBackoff.requestInitialBackoff(message_t *msg) {
    signal RadioBackoff.requestInitialBackoff[(TCAST(cc2420_header_t* ONE,
        (uint8_t*)msg + offsetof(message_t, data) - sizeof(cc2420_header_t)))->type](msg);
  }

  async event void SubBackoff.requestCongestionBackoff(message_t *msg) {
    signal RadioBackoff.requestCongestionBackoff[(TCAST(cc2420_header_t* ONE,
        (uint8_t*)msg + offsetof(message_t, data) - sizeof(cc2420_header_t)))->type](msg);
  }
  async event void SubBackoff.requestCca(message_t *msg) {
    // Lower layers than this do not configure the CCA settings
    signal RadioBackoff.requestCca[(TCAST(cc2420_header_t* ONE,
        (uint8_t*)msg + offsetof(message_t, data) - sizeof(cc2420_header_t)))->type](msg);
  }

  async command void RadioBackoff.setInitialBackoff[am_id_t amId](uint16_t backoffTime) {
    call SubBackoff.setInitialBackoff(backoffTime);
  }

  /**
   * Must be called within a requestCongestionBackoff event
   * @param backoffTime the amount of time in some unspecified units to backoff
   */
  async command void RadioBackoff.setCongestionBackoff[am_id_t amId](uint16_t backoffTime) {
    call SubBackoff.setCongestionBackoff(backoffTime);
  }


  /**
   * Enable CCA for the outbound packet.  Must be called within a requestCca
   * event
   * @param ccaOn TRUE to enable CCA, which is the default.
   */
  async command void RadioBackoff.setCca[am_id_t amId](bool useCca) {
    call SubBackoff.setCca(useCca);
  }



  /***************** Defaults ****************/
  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
    return msg;
  }

  default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
  }

  default event void SendNotifier.aboutToSend[am_id_t amId](am_addr_t addr, message_t *msg) {
  }
  default async event void RadioBackoff.requestInitialBackoff[am_id_t id](
      message_t *msg) {
  }

  default async event void RadioBackoff.requestCongestionBackoff[am_id_t id](
      message_t *msg) {
  }

  default async event void RadioBackoff.requestCca[am_id_t id](
      message_t *msg) {
  }

    message_t buffer;
    message_t* bufferPointer = &buffer;

    void active_message_deliver_handle(sim_event_t* evt) {
	message_t* m = (message_t*)evt->data;
	uint8_t len;
	void* payload;
	dbg("Packet", "Delivering packet to %i at %s\n", (int)sim_node(), sim_time_string());

	memcpy(bufferPointer, m, sizeof(message_t));
	len = call Packet.payloadLength(bufferPointer);
	payload = call Packet.getPayload(bufferPointer, call Packet.maxPayloadLength());

	bufferPointer = signal SubReceive.receive(bufferPointer, payload, len);
    }

    sim_event_t* allocate_deliver_event(int node, message_t* msg, sim_time_t t) {
	sim_event_t* evt = (sim_event_t*)malloc(sizeof(sim_event_t));
	evt->mote = node;
	evt->time = t;
	evt->handle = active_message_deliver_handle;
	evt->cleanup = sim_queue_cleanup_event;
	evt->cancelled = 0;
	evt->force = 0;
	evt->data = msg;
	return evt;
    }

    void active_message_deliver(int node, message_t* msg, sim_time_t t) @C() @spontaneous() {
	sim_event_t* evt = allocate_deliver_event(node, msg, t);
	sim_queue_insert(evt);
    }
}
