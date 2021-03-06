/**
 * This class is automatically generated by mig. DO NOT EDIT THIS FILE.
 * This class implements a Java interface to the 'PrintCounterReadingMsg'
 * message type.
 */

public class PrintCounterReadingMsg extends net.tinyos.message.Message {

    /** The default size of this message type in bytes. */
    public static final int DEFAULT_MESSAGE_SIZE = 7;

    /** The Active Message type associated with this message. */
    public static final int AM_TYPE = 13;

    /** Create a new PrintCounterReadingMsg of size 7. */
    public PrintCounterReadingMsg() {
        super(DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /** Create a new PrintCounterReadingMsg of the given data_length. */
    public PrintCounterReadingMsg(int data_length) {
        super(data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new PrintCounterReadingMsg with the given data_length
     * and base offset.
     */
    public PrintCounterReadingMsg(int data_length, int base_offset) {
        super(data_length, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new PrintCounterReadingMsg using the given byte array
     * as backing store.
     */
    public PrintCounterReadingMsg(byte[] data) {
        super(data);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new PrintCounterReadingMsg using the given byte array
     * as backing store, with the given base offset.
     */
    public PrintCounterReadingMsg(byte[] data, int base_offset) {
        super(data, base_offset);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new PrintCounterReadingMsg using the given byte array
     * as backing store, with the given base offset and data length.
     */
    public PrintCounterReadingMsg(byte[] data, int base_offset, int data_length) {
        super(data, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new PrintCounterReadingMsg embedded in the given message
     * at the given base offset.
     */
    public PrintCounterReadingMsg(net.tinyos.message.Message msg, int base_offset) {
        super(msg, base_offset, DEFAULT_MESSAGE_SIZE);
        amTypeSet(AM_TYPE);
    }

    /**
     * Create a new PrintCounterReadingMsg embedded in the given message
     * at the given base offset and length.
     */
    public PrintCounterReadingMsg(net.tinyos.message.Message msg, int base_offset, int data_length) {
        super(msg, base_offset, data_length);
        amTypeSet(AM_TYPE);
    }

    /**
    /* Return a String representation of this message. Includes the
     * message type name and the non-indexed field values.
     */
    public String toString() {
      String s = "Message <PrintCounterReadingMsg> \n";
      try {
        s += "  [flag=0x"+Long.toHexString(get_flag())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [nodeid=0x"+Long.toHexString(get_nodeid())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [counter=0x"+Long.toHexString(get_counter())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      try {
        s += "  [voltage_reading=0x"+Long.toHexString(get_voltage_reading())+"]\n";
      } catch (ArrayIndexOutOfBoundsException aioobe) { /* Skip field */ }
      return s;
    }

    // Message-type-specific access methods appear below.

    /////////////////////////////////////////////////////////
    // Accessor methods for field: flag
    //   Field type: short, unsigned
    //   Offset (bits): 0
    //   Size (bits): 8
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'flag' is signed (false).
     */
    public static boolean isSigned_flag() {
        return false;
    }

    /**
     * Return whether the field 'flag' is an array (false).
     */
    public static boolean isArray_flag() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'flag'
     */
    public static int offset_flag() {
        return (0 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'flag'
     */
    public static int offsetBits_flag() {
        return 0;
    }

    /**
     * Return the value (as a short) of the field 'flag'
     */
    public short get_flag() {
        return (short)getUIntBEElement(offsetBits_flag(), 8);
    }

    /**
     * Set the value of the field 'flag'
     */
    public void set_flag(short value) {
        setUIntBEElement(offsetBits_flag(), 8, value);
    }

    /**
     * Return the size, in bytes, of the field 'flag'
     */
    public static int size_flag() {
        return (8 / 8);
    }

    /**
     * Return the size, in bits, of the field 'flag'
     */
    public static int sizeBits_flag() {
        return 8;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: nodeid
    //   Field type: int, unsigned
    //   Offset (bits): 8
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'nodeid' is signed (false).
     */
    public static boolean isSigned_nodeid() {
        return false;
    }

    /**
     * Return whether the field 'nodeid' is an array (false).
     */
    public static boolean isArray_nodeid() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'nodeid'
     */
    public static int offset_nodeid() {
        return (8 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'nodeid'
     */
    public static int offsetBits_nodeid() {
        return 8;
    }

    /**
     * Return the value (as a int) of the field 'nodeid'
     */
    public int get_nodeid() {
        return (int)getUIntBEElement(offsetBits_nodeid(), 16);
    }

    /**
     * Set the value of the field 'nodeid'
     */
    public void set_nodeid(int value) {
        setUIntBEElement(offsetBits_nodeid(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'nodeid'
     */
    public static int size_nodeid() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'nodeid'
     */
    public static int sizeBits_nodeid() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: counter
    //   Field type: int, unsigned
    //   Offset (bits): 24
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'counter' is signed (false).
     */
    public static boolean isSigned_counter() {
        return false;
    }

    /**
     * Return whether the field 'counter' is an array (false).
     */
    public static boolean isArray_counter() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'counter'
     */
    public static int offset_counter() {
        return (24 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'counter'
     */
    public static int offsetBits_counter() {
        return 24;
    }

    /**
     * Return the value (as a int) of the field 'counter'
     */
    public int get_counter() {
        return (int)getUIntBEElement(offsetBits_counter(), 16);
    }

    /**
     * Set the value of the field 'counter'
     */
    public void set_counter(int value) {
        setUIntBEElement(offsetBits_counter(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'counter'
     */
    public static int size_counter() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'counter'
     */
    public static int sizeBits_counter() {
        return 16;
    }

    /////////////////////////////////////////////////////////
    // Accessor methods for field: voltage_reading
    //   Field type: int, unsigned
    //   Offset (bits): 40
    //   Size (bits): 16
    /////////////////////////////////////////////////////////

    /**
     * Return whether the field 'voltage_reading' is signed (false).
     */
    public static boolean isSigned_voltage_reading() {
        return false;
    }

    /**
     * Return whether the field 'voltage_reading' is an array (false).
     */
    public static boolean isArray_voltage_reading() {
        return false;
    }

    /**
     * Return the offset (in bytes) of the field 'voltage_reading'
     */
    public static int offset_voltage_reading() {
        return (40 / 8);
    }

    /**
     * Return the offset (in bits) of the field 'voltage_reading'
     */
    public static int offsetBits_voltage_reading() {
        return 40;
    }

    /**
     * Return the value (as a int) of the field 'voltage_reading'
     */
    public int get_voltage_reading() {
        return (int)getUIntBEElement(offsetBits_voltage_reading(), 16);
    }

    /**
     * Set the value of the field 'voltage_reading'
     */
    public void set_voltage_reading(int value) {
        setUIntBEElement(offsetBits_voltage_reading(), 16, value);
    }

    /**
     * Return the size, in bytes, of the field 'voltage_reading'
     */
    public static int size_voltage_reading() {
        return (16 / 8);
    }

    /**
     * Return the size, in bits, of the field 'voltage_reading'
     */
    public static int sizeBits_voltage_reading() {
        return 16;
    }

}
