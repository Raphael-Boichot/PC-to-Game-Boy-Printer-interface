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
    send_packet(INIT);
    pause(0.2);%skips the first packet without
    for counter=1:1:number_packets
        DATA_READY=[DATA,DATA_packets_to_print(counter,:)];
        DATA_READY = add_checksum(DATA_READY);
        disp(['Sending ',num2str(counter),' DATA packet',]);
        send_packet(DATA_READY);
        if (rem(counter,9)==0)&&(counter~=number_packets)%memory full, printing
            %--------printing loop within an image if it has 9 packets or more-----------
            send_packet(EMPT);%mandatory in the protocol
            disp('Sending PRINT command without margin');
            send_packet(PRNT);
            pause(0.25);%time for the printer head to fire
            [response_packet]=send_packet(INQU);
            while not(ismember(0x06, response_packet))%resilient to packet misaligned
                pause(0.25);
                [response_packet]=send_packet(INQU);%first response is always 0x08 due to some serial oddity with Octave, flushing it
                disp(strjoin(cellstr(num2hex(response_packet))', ' '))
            end
            while ismember(0x06, response_packet)%while printer is busy printing...
                pause(0.25);
                [response_packet]=send_packet(INQU);
                disp(strjoin(cellstr(num2hex(response_packet))', ' '))
            end
            %---------------------------------------------------
        end
    end
    %%--------flushing loop-----------------------------
    send_packet(EMPT);%mandatory in the protocol
    disp('Sending PRINT command with margin');
    PRNT_INI(8)=margin; %prepare PRINT command with margin, always, as it is the end of an image
    PRNT = add_checksum(PRNT_INI);
    send_packet(PRNT);
    pause(0.25);%time for the printer head to fire
    [response_packet]=send_packet(INQU);
    while not(ismember(0x06, response_packet))%resilient to packet misaligned
        pause(0.25);
        [response_packet]=send_packet(INQU);%first response is always 0x08 due to some serial oddity with Octave, flushing it
        disp(strjoin(cellstr(num2hex(response_packet))', ' '))
    end
    while ismember(0x06, response_packet)%while printer is busy printing...
        pause(0.25);
        [response_packet]=send_packet(INQU);
        disp(strjoin(cellstr(num2hex(response_packet))', ' '))
    end
    packets=0;
    PRNT_INI(8)=0x00; %restore PRINT command without margin for next image
    PRNT = add_checksum(PRNT_INI);
    %---------------------------------------------------
end
disp('Closing serial port')
flush(arduinoObj);
arduinoObj=[];
disp('End of printing')
close all
