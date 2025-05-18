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
PRNT_INI = [0x88 0x33 0x02 0x00 0x04 0x00 0x01 0x00 palette intensity];%, 0x2B, 0x01, 0x00, 0x00}; %PRINT without feed lines, default
INQU = [0x88 0x33 0x0F 0x00 0x00 0x00 0x0F 0x00 0x00 0x00]; %INQUIRY command
EMPT = [0x88 0x33 0x04 0x00 0x00 0x00 0x04 0x00 0x00 0x00]; %Empty data packet, mandatory for validate DATA packet
DATA = [0x88 0x33 0x04 0x00 0x80 0x02]; %DATA packet header, considering 640 bytes length by defaut (80 02), the footer is calculated onboard
%--------------------------------------------------------------
PRNT = add_checksum(PRNT_INI);
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
    packets=0;
    DATA_BUFFER=[];
    imagefiles_png = dir('Images/*.png');
    imagefiles_jpg = dir('Images/*.jpg');
    imagefiles_jpeg = dir('Images/*.jpeg');
    imagefiles_bmp = dir('Images/*.bmp');
    imagefiles = [imagefiles_png; imagefiles_jpg; imagefiles_jpeg; imagefiles_bmp];
    nfiles = length(imagefiles);     % Number of files found

    for k=1:1:nfiles
        currentfilename = imagefiles(k).name;
        disp(['Converting image ',currentfilename,' in progress...'])
        [a,map]=imread(['Images/',currentfilename]);

        if not(isempty(map));%dealing with indexed images
            disp('Indexed image, converting to grayscale');
            a=ind2gray(a,map);
        end

        [height, width, layers]=size(a);
        if layers>1%dealing with color images
            disp('Color image, converting to grayscale');
            a=rgb2gray(a);
            [height, width, layers]=size(a);
        end
        C=unique(a);

        if (length(C)<=4 && height==160);%dealing with pixel perfect image, bad orientation
            disp('Bad orientation, image rotated');
            a=imrotate(a,270);
            [heigth, width,layers]=size(a);
        end

        if (length(C)<=4 && not(width==160));%dealing with pixel perfect upscaled/downscaled images
            disp('Image is 2 bpp or less, which is good, but bad size: fixing it');
            a=imresize(a,160/width,"nearest");
            [heigth, width,layers]=size(a);
        end

        if (length(C)>4 || not(width==160));%dealing with 8-bit images in general
            disp('8-bits image rectified and dithered with Bayer matrices');
            a=image_rectifier(a);
            [height, width, layers]=size(a);
        end

        if length(C)==1;%dealing with one color images
            disp('Empty image -> neutralization, will print full white');
            a=zeros(height, width);
        end

        if not(rem(height,16)==0);%Fixing images not multiple of 16 pixels
            disp('Image height is not a multiple of 16 : fixing image');
            C=unique(a);
            new_lines=ceil(height/16)*16-height;
            color_footer=double(C(end));
            footer=color_footer.*ones(new_lines,width, layers);
            a=[a;footer];
            [height, width, layers]=size(a);
        end

        [height, width, layers]=size(a);
        C=unique(a);
        disp(['Buffering image ',currentfilename,' into GB tile data...'])
        switch length(C)
            case 4;%4 colors, OK
                Black=C(1);
                Dgray=C(2);
                Lgray=C(3);
                White=C(4);
            case 3;%3 colors, sacrify LG (not well printed)
                Black=C(1);
                Dgray=C(2);
                Lgray=[];
                White=C(3);
            case 2;%2 colors, sacrify LG and DG
                Black=C(1)
                Dgray=[];
                Lgray=[];
                White=C(2);
        end;

        hor_tile=width/8;
        vert_tile=height/8;
        tile=0;
        H=1;
        L=1;
        H_tile=1;
        L_tile=1;
        O=[];
        y_graph=0;
        total_tiles=hor_tile*vert_tile;
        for x=1:1:hor_tile
            for y=1:1:vert_tile
                tile=tile+1;
                b=a((H:H+7),(L:L+7));
                for i = 1:8
                    V1 = repmat('0', 1, 8);  % Initialize binary string V1
                    V2 = repmat('0', 1, 8);  % Initialize binary string V2
                    for j = 1:8
                        if b(i,j) == Lgray
                            V1(j) = '1'; V2(j) = '0';
                        elseif b(i,j) == Dgray
                            V1(j) = '0'; V2(j) = '1';
                        elseif b(i,j) == White
                            V1(j) = '0'; V2(j) = '0';
                        elseif b(i,j) == Black
                            V1(j) = '1'; V2(j) = '1';
                        end
                    end
                    O = [O, bin2dec(V1), bin2dec(V2)];
                end
                if tile==40
                    imshow(a)
                    colormap gray
                    h=rectangle('Position',[1 y_graph 160-1 16],'EdgeColor','r', 'LineWidth',1,'FaceColor', [1, 0, 0]);
                    drawnow
                    y_graph=y_graph+16;
                    DATA_READY=[DATA,O];
                    DATA_READY = add_checksum(DATA_READY);
                    packets=packets+1;
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
                    %---------------------------------------------------
                    O=[];
                    tile=0;
                end
                L=L+8;
                L_tile=L_tile+1;
                if L>=width
                    L=1;
                    L_tile=1;
                    H=H+8;
                    H_tile=H_tile+1;
                end
            end
        end

        packets=packets+3;
        imshow(a)
        drawnow
        %%--------printing loop-----------------------------
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
else
    disp('No device found, check connecion !')
end
