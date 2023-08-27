# A simple PC to Game Boy Printer interface with an Arduino

The most cheap and basic setup you can imagine to print something from a PC to a Game Boy Printer ! The Arduino code is the same used in the [GBCamera-Android-Manager](https://github.com/Raphael-Boichot/GBCamera-Android-Manager). The code originates from an [SD based version](https://github.com/Raphael-Boichot/The-Arduino-SD-Game-Boy-Printer) which is technically more complicated and requires and SD shield. This project requires nothing but an Arduino.

Here GNU Octave is used to encode images into Game Boy Tile Format, make legit printer packets with correct checksums and send them to the serial port in correct order. The Arduino acts as a luxury level shifter. It turns the serial data sent to the Arduino into an SPI protocol compatible with the printer, in particular regarding timings. 

![Game Boy Printer to Arduino Uno pinout](Pictures/Principle.png)

## Parts needed

- An [Arduino Uno](https://fr.aliexpress.com/item/32848546164.html);
- The [cheapest Game Boy serial cable you can find](https://fr.aliexpress.com/item/32698407220.html) as you will cut it. **Important note:** SIN and SOUT are crossed internally so never trust what wires you get. Use a multimeter to identify wires. Cross SIN and SOUT if the device does not work at the end;
- If you want something on the neat side, you can use a serial port breakout board instead of cutting a cable, there are tons of them on internet for cheap.

## Pinout 

![Game Boy Printer to Arduino Uno pinout](Pictures/Pinout.png)

The pinout uses only 4 wires, so it's very easy to make ! Why not hooking SOUT to D4 ? I use this configuration for other related projects so this weird choice, but you are of course free to change the pinout.

## How to use it

Well, this is as simple as it sounds:
- Install the [Arduino IDE](https://www.arduino.cc/en/software) and [GNU Octave](https://octave.org/);
- Clone the repo locally;
- Flash the [Arduino code](https://github.com/Raphael-Boichot/PC-to-Game-Boy-Printer-interface/blob/main/Arduino_interface/Arduino_interface.ino) to your Arduino Uno;
- Drop some images **160 pixels width, 4 shades of gray (or less), png format (mandatory)**, in the [image folder](https://github.com/Raphael-Boichot/PC-to-Game-Boy-Printer-interface/tree/main/Octave_Interface/Images). 1x screenshots from emulators and images from Game Boy Camera does the job perfectly;
- Connect the Game Boy Printer to the Arduino and the Arduino to the PC. Nothing indicates if wiring is OK, trust yourself;
- Open [the Octave code](https://github.com/Raphael-Boichot/PC-to-Game-Boy-Printer-interface/blob/main/Octave_Interface/Direct_Converter.m), select the [COM port corresponding to your Arduino board](https://github.com/Raphael-Boichot/PC-to-Game-Boy-Printer-interface/blob/e13f0a8247043a577f75674304a3ea3e64e7e601/Octave_Interface/Direct_Converter.m#L10) and run the code from the GNU Octave Launcher;
- Enjoy your washed-out pictures !
- It does not work ? Inverse SIN and SOUT and check for some error on serial in Octave console then retry !

## Example of fancy use

![Fancy use](Pictures/Setup.jpg)

Do not trust the image which displays an Arduino Uno packed with wires as it is also used for [this project](https://github.com/Raphael-Boichot/Play-with-the-Game-Boy-Camera-Mitsubishi-M64282FP-sensor) or [this other project](https://github.com/Raphael-Boichot/A-penultimate-Arduino-DHT22-recorder), the pinout is really as simple as described.

## Known flaws

This code prints one packet after the other and uses a fixed timer inbetween packets to let time to the printer to print. It could use a detection from busy state from the printer and stuff packets by groups of 9 like the SD version. It does not all of that now (maybe one day).

