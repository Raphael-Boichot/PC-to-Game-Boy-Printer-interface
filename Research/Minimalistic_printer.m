%PC to Game Boy printer, Raphael BOICHOT 2023/08/26
%this must be run with GNU Octave
%just run this script with images into the folder "Images"
clc;
clear;

disp('-----------------------------------------------------------')
disp('|Beware, this code is for GNU Octave ONLY !!!             |')
disp('-----------------------------------------------------------')

pkg load instrument-control
pkg load image

%-------------------------------------------------------------
palette=0xE4;%any value is possible
intensity=0x40;%0x00->0x7F, 0x40 is default
margin=3;%0 before margin, 3 after margins, used between images
INIT = [0x88 0x33 0x01 0x00 0x00 0x00 0x01 0x00 0x00 0x00]; %INT command
PRNT_INI = [0x88 0x33 0x02 0x00 0x04 0x00 0x01 margin palette intensity];%, 0x2B, 0x01, 0x00, 0x00}; %PRINT without feed lines, default
INQU = [0x88 0x33 0x0F 0x00 0x00 0x00 0x0F 0x00 0x00 0x00]; %INQUIRY command
EMPT = [0x88 0x33 0x04 0x00 0x00 0x00 0x04 0x00 0x00 0x00]; %Empty data packet, mandatory for validate DATA packet
DATA = [0x88 0x33 0x04 0x00 0x80 0x02]; %DATA packet header, considering 640 bytes length by defaut (80 02), the footer is calculated onboard
%--------------------------------------------------------------
PRNT = add_checksum(PRNT_INI);
packet_lenght=640;
DATA = add_checksum([DATA, uint8(0xFF*rand(1,packet_lenght))]);
DATA = add_lenght(DATA,packet_lenght);
global arduinoObj
list = serialportlist;
valid_port=[];
protocol_failure=1;
for i =1:1:length(list)
    disp(['Testing port ',char(list(i)),'...'])
    s = serialport(char(list(i)),'BaudRate',9600);
    set(s, 'timeout',2);
    flush(s);
    response=char(read(s, 100));
    if ~isempty(response)
        if not(isempty(strfind(response,"Waiting")))
            disp(['Arduino detected on port ',char(list(i))])
            valid_port=char(list(i));
            beep ()
            protocol_failure=0;
        end
    end
    clear s
end
if protocol_failure==0
    arduinoObj = serialport(valid_port,'baudrate',9600,'parity','none','timeout',255); %set the Arduino com port here
    pause(2.5);% allows the Arduino to reboot before sending data
    fread(arduinoObj,8);%clear the port from some buffered shit, flush command does not work here, no idea why
    %--------printing loop-----------------------------
    send_packet(INIT);
    pause(0.1)
    send_packet(INQU);
    send_packet(DATA);
    send_packet(EMPT);%mandatory in the protocol
    send_packet(PRNT);
    send_packet(INQU);
    %---------------------------------------------------
    disp('Closing serial port')
    flush(arduinoObj);
    arduinoObj=[];
    disp('End of printing')
    close all
else
    disp('No device found, check connection with the Arduino !')
    disp('// If you''re using the Game Boy Printer emulator at:')
    disp('// https://github.com/mofosyne/arduino-gameboy-printer-emulator')
    disp('// switch the printer ON before connecting the Arduino')
    disp('// It has to detect a valid printer to boot in printer interface mode')
end
