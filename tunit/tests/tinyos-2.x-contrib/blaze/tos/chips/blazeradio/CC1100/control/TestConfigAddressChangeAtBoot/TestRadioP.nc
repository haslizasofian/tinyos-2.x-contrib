
#include "TestCase.h"

/**
 * @author David Moss
 */
module TestRadioP {
  uses {
    interface TestControl as SetUpOneTime;
    interface TestControl as TearDownOneTime;
    
    interface TestCase as TestActiveMessageAddress;
    
    interface ActiveMessageAddress;
    interface SplitControl;
    interface AMPacket;
    interface AMSend;
    interface Receive;
    interface BlazeConfig;
    interface PacketAcknowledgements;
    interface Timer<TMilli>;
    interface State;
    interface Leds;
  }
}

implementation {
  
  bool transmitter;
  
  message_t myMsg;
  
  uint8_t attempts;
  
  uint8_t synced = 0;
  
  enum {
    S_IDLE,
    S_SETUPONETIME,
    S_TESTINUSEDUTYCYCLE,
    S_TEARDOWNONETIME,
  };
  
  enum {
    MAX_ATTEMPTS = 100,
    GROUP = 50,
    TRANSMIT_ID = 1000,
    RECEIVE_ID = 1001,
    
  };
  
  /***************** Prototypes ****************/
  task void sendMsg();
  
  /***************** SetUp Events ****************/
  event void SetUpOneTime.run() {
    call State.forceState(S_SETUPONETIME);
    transmitter = (call ActiveMessageAddress.amAddress() == 0);
    attempts = 0;
    call PacketAcknowledgements.requestAck(&myMsg);
    
    if(transmitter) {
      call ActiveMessageAddress.setAddress(GROUP, TRANSMIT_ID);
    } else {
      call ActiveMessageAddress.setAddress(GROUP, RECEIVE_ID);
    }
    
  }
  
  event void TearDownOneTime.run() {
    call State.forceState(S_TEARDOWNONETIME);
    if(call SplitControl.stop() != SUCCESS) {
      call TearDownOneTime.done();
    }
  }
  
  /***************** SplitControl Events ****************/
  event void SplitControl.startDone(error_t error) {
    call Leds.led2On();
    call State.toIdle();
    call SetUpOneTime.done();
    
  }
  
  event void SplitControl.stopDone(error_t error) {
    call Leds.led2Off();
    call TearDownOneTime.done();
  }
  
  /***************** TestActiveMessageAddress Events ****************/
  /**
   * We just changed the node's address and group in the ActiveMessageAddress
   * interface.  Verify those changes got propagated to the Blaze hardware.
   */
  event void TestActiveMessageAddress.run() {
    assertEquals("Wrong number of commits", 1, synced);
    post sendMsg();
  }
  
    
  
  /***************** AMSend Events ****************/
  event void AMSend.sendDone(message_t *msg, error_t error) {
    attempts++;
    if(!call PacketAcknowledgements.wasAcked(msg)) {
      if(attempts > MAX_ATTEMPTS) {
        assertFail("No ack! Address change failed");
        call TestActiveMessageAddress.done();
        return;
        
      } else {
        post sendMsg();
      }
      
    } else {
      assertSuccess();
      call TestActiveMessageAddress.done();
    }
    
  }
  
  /***************** Receive Events ****************/
  event message_t *Receive.receive(message_t *msg, void *payload, uint8_t len) {
    return msg;
  }
  
  /***************** Commit Events ****************/
  event void BlazeConfig.commitDone( ) {
    call Leds.led1On();
    synced++;
    
    
    if(call SplitControl.start() != SUCCESS) {
      call State.toIdle();
      call SetUpOneTime.done();
    }
    
  }
  
  async event void ActiveMessageAddress.changed() {
  }
  
  /***************** Timer Events ****************/
  event void Timer.fired() {
  }
  
  /***************** Tasks ****************/
  task void sendMsg() {
    if(call AMSend.send(RECEIVE_ID, &myMsg, TOSH_DATA_LENGTH) != SUCCESS) {
      post sendMsg();
    }
  }
  
}