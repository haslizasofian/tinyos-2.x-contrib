/*
 * Copyright (c) 2005-2006 Rincon Research Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Rincon Research Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * RINCON RESEARCH OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

#include "Blaze.h"
#include "Acknowledgements.h"
#include "Fcf.h"
#include "RadioStackPacket.h"

/**
 * This module takes care of manipulating the FCF byte to specify the 
 * type of outbound packet.  It also manipulates the FCF byte to include
 * acknowledgements, and waits for an acknowledgement before signaling
 * sendDone() if it needs to.
 *
 * Acknowledgments MUST be checked immediately at sendDone() before
 * the next packet is sent since we don't allocate space in the message_t
 * to store the wasAcked boolean.  If we need to store each ack response
 * in the message, the FCF byte would be the place to do it.
 *
 * @author David Moss
 */
 
module AcknowledgementsP {
  provides {
    interface Send;
    interface AckDetails;
    interface PacketAcknowledgements;
    interface AckReceive;
  }
  
  uses {
    interface BlazePacketBody;
    interface Send as SubSend;
    interface ChipSpiResource;
    interface Alarm<T32khz,uint16_t> as AckWaitTimer;
    interface AckReceive as SubAckReceive;
    
    interface Leds;
  }
}

implementation {

  enum {
    S_IDLE,
    S_SENDING_ACK,
    S_ACK_WAIT,
    S_SEND_DONE,
  };
  
    
  /** Need a state to know if the timer fire is ours, and for Chip SPI abort */
  norace uint8_t state = S_IDLE;
  
  /** TRUE if the current message was acknowledged */
  bool wasAcked;
  
  
  /***************** Prototypes ****************/
  task void sendDone();
  
  /***************** Send Commands ****************/
  /**
   * By this point, the length should already be set in the message itself.
   * @param msg the message to send
   * @param len IGNORED
   * @return SUCCESS if we're going to try to send the message.
   *     FAIL if you need to reevaluate your code
   */
  command error_t Send.send(message_t* msg, uint8_t len) {
    error_t error;
    
    if(state != S_IDLE) {
      // Still waiting for the last ack
      return EBUSY;
    }
    
    call PacketAcknowledgements.requestAck(RADIO_STACK_PACKET);
    
    (call BlazePacketBody.getHeader(msg))->fcf |= ( FRAME_TYPE_DATA << FCF_FRAME_TYPE );
    
    wasAcked = FALSE;
        
    if((error = call SubSend.send(RADIO_STACK_PACKET, len)) != SUCCESS) {
      atomic state = S_IDLE;
    }
    
    return error;
  }

  command error_t Send.cancel(message_t* msg) {
    return FAIL;
  }

  command uint8_t Send.maxPayloadLength() { 
    return call SubSend.maxPayloadLength();
  }

  command void *Send.getPayload(message_t* msg, uint8_t len) {
    return call SubSend.getPayload(msg, len);
  }
  
  /***************** PacketAcknowledgements Commands ****************/
  async command error_t PacketAcknowledgements.requestAck( message_t *msg ) {
    (call BlazePacketBody.getHeader( msg ))->fcf |= 1 << FCF_ACK_REQ;
    return SUCCESS;
  }
  
  async command error_t PacketAcknowledgements.noAck( message_t *msg ) {
    return FAIL;
  }
  
  async command bool PacketAcknowledgements.wasAcked(message_t *msg) {
    return wasAcked;
  }
  
  
  /***************** AckDetails Commands ****************/
  async command bool AckDetails.shouldAck(message_t *msg) {
    blaze_header_t *header = call BlazePacketBody.getHeader(msg);
    return ((( header->fcf >> FCF_ACK_REQ ) & 0x01) == 1) 
        && (header->dest != AM_BROADCAST_ADDR);
  }
  
  
  /***************** BackoffTimer Events ****************/
  async event void AckWaitTimer.fired() {
    // Our ack wait period expired with no luck...
    atomic state = S_SEND_DONE;

#if BLAZE_ENABLE_TIMING_LEDS
    call Leds.led1Off();
#endif
    
    call ChipSpiResource.attemptRelease();
    post sendDone();
  }
  
  
  /***************** SubSend Events ****************/
  event void SubSend.sendDone(message_t *msg, error_t error) {
    atomic state = S_ACK_WAIT;

#if BLAZE_ENABLE_TIMING_LEDS
    call Leds.led1On();
#endif

    call AckWaitTimer.start(BLAZE_ACK_WAIT);
  }
  
  /***************** SubAckReceive Events ****************/
  async event void SubAckReceive.receive( blaze_ack_t *ack ) {
    blaze_header_t *header = call BlazePacketBody.getHeader(RADIO_STACK_PACKET);
    
    if(state == S_ACK_WAIT) {
      if((ack->dest == header->src || ack->dest == AM_BROADCAST_ADDR) &&
          ack->src == header->dest &&
              ack->dsn == header->dsn) {
        
        // This is our acknowledgement
        wasAcked = TRUE;
        
        signal AckReceive.receive(ack);
        
#if BLAZE_ENABLE_TIMING_LEDS
    call Leds.led1Toggle();
    call Leds.led1Toggle();
#endif

      }
    }
  }
  
  /***************** ChipSpiResource Events ***************/
  /**
   * The SPI bus is about to be automatically released.  Modules that aren't
   * using the SPI bus but still want the SPI bus to stick around must call
   * abortRelease() within the event.
   */
  async event void ChipSpiResource.releasing() {   
    if(state == S_SENDING_ACK || state == S_ACK_WAIT) {
      // Csma is trying to release the SPI bus. Let the chip own the SPI bus
      // so it's immediately available when Receive needs it.
      call ChipSpiResource.abortRelease();
    }
  }
  
  /***************** Tasks ****************/
  task void sendDone() {
    atomic state = S_IDLE;
    signal Send.sendDone(RADIO_STACK_PACKET, SUCCESS);
  }
  
  
  /***************** Defaults ****************/
  default async event void AckReceive.receive( blaze_ack_t *ack) { }
}
