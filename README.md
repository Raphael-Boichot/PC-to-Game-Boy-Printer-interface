# PC to Game Boy Printer interface

The most cheap and basic device you can imagine to print something from a PC to a Game Boy Printer ! The Arduino code is the same used in the [GBCamera-Android-Manager](https://github.com/Raphael-Boichot/GBCamera-Android-Manager). The code originates from an [SD based version](https://github.com/Raphael-Boichot/The-Arduino-SD-Game-Boy-Printer) which is technically more complicated and requires and SD shield.

## Parts needed

- An [Arduino Uno](https://fr.aliexpress.com/item/32848546164.html);
- The [cheapest Game Boy serial cable you can find](https://fr.aliexpress.com/item/32698407220.html) as you will cut it. **Important note:** SIN and SOUT are crossed internally so never trust what wires you get. Use a multimeter to identify wires. Cross SIN and SOUT if the device does not work at the end.
- If you want something on the neat side, you can use a serial port breakout board instead of cutting a cable, there are tons of them on internet.

## Pinout 

![Game Boy Printer to Arduino Uno pinout](Pictures/Pinout.png)

The pinout uses only 4 wires, so it's very easy. SIN and SOUT may be crossed so a non working setup may just due to this.

## How to use it

Well, this is as simple as it sounds:
- Install the [Arduino IDE](https://www.arduino.cc/en/software) and [GNU Octave](https://octave.org/);
- clone the repo locally;
- Flash the [Arduino code](https://github.com/Raphael-Boichot/PC-to-Game-Boy-Printer-interface/blob/main/Arduino_interface/Arduino_interface.ino) to your Arduino Uno;
- Drop some images 160 pixels width, multiple of 16 pixel height, 4 shades of gray (or less) in the [image folder](https://github.com/Raphael-Boichot/PC-to-Game-Boy-Printer-interface/tree/main/Octave_Interface/Images). 1x screenshots from emulators and images from Game Boy Camera does the job perfectly;
- Connect the Game Boy Printer to the Arduino. Nothing indicates if wiring is OK, trust yourself;
- Open [the Octave code](https://github.com/Raphael-Boichot/PC-to-Game-Boy-Printer-interface/blob/main/Octave_Interface/Direct_Converter.m), select the COM port corresponding to your Arduino board and run the code from the GNU Octave Launcher;
- Enjoy you pictures !

![Game Boy Printer to Arduino Uno pinout](Pictures/Principle.png)

## Example of fancy use

![Fancy use](Pictures/Setup.jpg)

## Known flaws

This code prints one packet after the other and uses a fixed timer inbetween packets to let time to the printer to print. It could use a detection from busy byte from the printer, it could stuff packets by groups of 9, it could take advantage from extra features from the print command. It does not do all of that, it does the job, that's all.

