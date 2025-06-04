%PC to Game Boy printer, Raphael BOICHOT 2023/08/26
%this must be run with GNU Octave
%just run this script with images into the folder "Images"
clc;
clear;

disp('-----------------------------------------------------------')
disp('|Beware, this code is for GNU Octave ONLY !!!             |')
disp('-----------------------------------------------------------')

try
    pkg load instrument-control
    pkg load image
end

%-------------------------------------------------------------
palette=0xE4;%any value is possible
intensity=0x40;%0x00->0x7F, 0x40 is default
margin=3;%0 before margin, 3 after margins, used between images
INIT = [0x88 0x33 0x01 0x00 0x00 0x00 0x01 0x00 0x00 0x00]; %INT command
PRNT_INI = [0x88 0x33 0x02 0x00 0x04 0x00 0x01 0x00 palette intensity];%, 0x2B, 0x01, 0x00, 0x00}; %PRINT without feed lines, default
INQU = [0x88 0x33 0x0F 0x00 0x00 0x00 0x0F 0x00 0x00 0x00]; %INQUIRY command
EMPT = [0x88 0x33 0x04 0x00 0x00 0x00 0x04 0x00 0x00 0x00]; %Empty data packet, mandatory for validate DATA packet
DATA = [0x88 0x33 0x04 0x00 0x80 0x02]; %DATA packet header, considering 640 bytes length by defaut (80 02), the footer is calculated onboard
%--------------------------------------------------------------
PRNT = add_checksum(PRNT_INI);
global arduinoObj
global Arduino_baudrate
Arduino_baudrate=9600;
% === Setup Serial Port ===
arduinoPort = detectArduino();
arduinoObj = serialport(arduinoPort,'baudrate',Arduino_baudrate, 'Parity', 'none', 'Timeout', 2);
pause(2.5);% allows the Arduino to reboot before sending data
fread(arduinoObj,8);%clear the port from some buffered shit, flush command does not work here, no idea why
packets=0;
DATA_BUFFER=[];
imagefiles = [dir('Images/*.png'); dir('Images/*.jpg'); dir('Images/*.jpeg'); dir('Images/*.bmp'); dir('Images/*.gif')];
nfiles = length(imagefiles);     % Number of files found
for k=1:1:nfiles
    %read(arduinoObj, arduinoObj.NumBytesAvailable, "uint8");%clear receiving buffer
    currentfilename = imagefiles(k).name;
    disp(['Converting image ',currentfilename,' in progress...'])
    [DATA_packets_to_print]=image_slicer(['Images/',currentfilename]);%transform image into Game Boy tiles
    [number_packets,~]=size(DATA_packets_to_print);%get the number of packets to print (40 tiles)
    pause(0.25);%let that poor GNU Octave recover

    for counter=1:1:number_packets
        DATA_READY=[DATA,DATA_packets_to_print(counter,:)];
        DATA_READY = add_checksum(DATA_READY);
        %printing appends here, packets are sent by groups of 40 tiles
        disp(['Buffering DATA packet#',num2str(packets)]);
        %--------printing loop-----------------------------
        send_packet(INIT);
        pause(0.2);%skips the first packet without
        disp(['Sending DATA packet#',num2str(packets)]);
        send_packet(DATA_READY);
        send_packet(EMPT);%mandatory in the protocol
        send_packet(PRNT);
        for i=1:1:13
            pause(0.1);%Time for the printer head to print one line of 16 pixels
            [response_packet]=send_packet(INQU);
            disp(strjoin(cellstr(num2hex(response_packet))', ' '))
        end
        pause(0.2);
    end
    %---------------------------------------------------

    %%--------flushing loop-----------------------------
    send_packet(INIT);
    pause(0.2);
    send_packet(EMPT);%mandatory in the protocol
    disp('Sending PRNT command with margin');
    PRNT_INI(8)=margin; %prepare PRINT command with margin
    PRNT = add_checksum(PRNT_INI);
    send_packet(PRNT);
    for i=1:1:13*margin
        pause(0.1);%Time for the printer head to print one line of 16 pixels
        [response_packet]=send_packet(INQU);
        disp(strjoin(cellstr(num2hex(response_packet))', ' '))
    end
    PRNT_INI(8)=0x00; %restore PRINT command without margin for next image
    PRNT = add_checksum(PRNT_INI);
    pause(0.2);
    %---------------------------------------------------
end
disp('Closing serial port')
flush(arduinoObj);
arduinoObj=[];
disp('End of printing')
close all
