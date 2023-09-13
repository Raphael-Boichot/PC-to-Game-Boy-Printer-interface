/*Game boy Printer interface with Arduino, by Raphaël BOICHOT 2023/04/03

this code allows interfacing any program with a Pocket Printer via serial port
One byte must be sent to the printer via serial, then one byte must be read on the serial, and so on. The read/write sequence allows a control of the flow

The general protocol to use this code is like this: 
- send an INIT command (its shelf life is at least 10 seconds)
- Wait 200 ms
- send DATA packets
- send an empty DATA packets (no payload)
- send a PRINT data packets
- send INQU data packets until print is over 
*/

char byte_read;
bool bit_sent, bit_read;
int clk = 2;   // clock signal
int TX = 3;    // The data signal coming from the Arduino and goind to the printer (Sout on Arduino becomes Sin on the printer)
int RX = 5;    // The response bytes coming from printer going to Arduino (Sout from printer becomes Sin on the Arduino)
int LED = 13;  //to indicate a printer ready state
//invert TX/RX if it does not work, assuming that everything else is OK
void setup() {
  pinMode(clk, OUTPUT);
  pinMode(TX, OUTPUT);
  pinMode(LED, OUTPUT);
  pinMode(RX, INPUT_PULLUP);
  digitalWrite(clk, HIGH);
  digitalWrite(TX, LOW);
  Serial.begin(9600);
  while (!Serial) { ; }
  Serial.println("Waiting for data");
  while (Serial.available() > 0) {  //flush the buffer from any remaining data
    Serial.read();
  }
  digitalWrite(LED, HIGH);
}

void loop() {
  if (Serial.available() > 0) {
    Serial.write(printing(Serial.read()));
  }
}

char printing(char byte_sent) {  // this function prints bytes to the serial
  for (int i = 0; i <= 7; i++) {
    bit_sent = bitRead(byte_sent, 7 - i);
    digitalWrite(clk, LOW);
    digitalWrite(TX, bit_sent);
    digitalWrite(LED, bit_sent);
    delayMicroseconds(30);  //double speed mode
    digitalWrite(clk, HIGH);
    bit_read = (digitalRead(RX));
    bitWrite(byte_read, 7 - i, bit_read);
    delayMicroseconds(30);  //double speed mode
  }
  delayMicroseconds(0);  //optionnal delay between bytes, may be less than 1490 µs
  //  Serial.println(byte_sent, HEX);
  //  Serial.println(byte_read, HEX);
  return byte_read;
}
