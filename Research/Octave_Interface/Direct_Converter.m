  ##PC to Game Boy printer, Raphael BOICHOT 2023/08/26
  ##this must be run with GNU Octave
  ##just run this script with images into the folder "Images"
  clc;
  clear;
  pkg load instrument-control
  pkg load image
  ##-------------------------------------------------------------
  palette=0xE4;##any value is possible
  intensity=0x7F;##0x00->0x7F
  margin=0x03; ##0 before margin, 3 after margins, used between images
  serial_port='COM8';
  margin=3;
  INIT = [0x88 0x33 0x01 0x00 0x00 0x00 0x01 0x00 0x00 0x00]; ##INT command
  PRNT_INI = [0x88 0x33 0x02 0x00 0x04 0x00 0x01 0x00 palette intensity];##, 0x2B, 0x01, 0x00, 0x00}; %PRINT without feed lines, default
  INQU = [0x88 0x33 0x0F 0x00 0x00 0x00 0x0F 0x00 0x00 0x00]; ##INQUIRY command
  EMPT = [0x88 0x33 0x04 0x00 0x00 0x00 0x04 0x00 0x00 0x00]; ##Empty data packet, mandatory for validate DATA packet
  DATA = [0x88 0x33 0x04 0x00 0x80 0x02]; ##DATA packet header, considering 640 bytes length by defaut (80 02), the footer is calculated onboard
  ##--------------------------------------------------------------
  PRNT = add_checksum(PRNT_INI);
  global arduinoObj
  ##arduinoObj = serialport(serial_port,'baudrate',115200,'parity','none','timeout',255); %set the Arduino com port here

  packets=0;
  DATA_BUFFER=[];
  imagefiles = dir('Images/*.png');## the default format is png, other are ignored
  nfiles = length(imagefiles);     ## Number of files found

  for k=1:1:nfiles
    currentfilename = imagefiles(k).name;
    a=imread(['Images/',currentfilename]);
    disp(['Converting image ',currentfilename,' in progress...'])
    figure(1)
    a=a(:,:,1);
    [hauteur, largeur, profondeur]=size(a);
    C=unique(a);

    if (length(C)>4 || not(largeur==160));
      a=imread(['Images/',currentfilename]);
      disp('Color image rectified');
      a=image_rectifier(a);
      [hauteur, largeur, profondeur]=size(a);
    end

    if length(C)==1;
      disp('Empty image -> neutralization !');
      a=zeros(hauteur, largeur);
    end

    if not(rem(hauteur,16)==0);##Fixing images not multiple of 16 pixels
      disp('Image height is not a multiple of 16 : fixing image');
      C=unique(a);
      new_lines=ceil(hauteur/16)*16-hauteur;
      color_footer=double(C(end));
      footer=color_footer.*ones(new_lines,largeur, profondeur);
      a=[a;footer];
      [hauteur, largeur, profondeur]=size(a);
    end

    disp(['Buffering image ',currentfilename,' into GB tile data...'])
    switch length(C)
      case 4;
        Black=C(1);
        Dgray=C(2);
        Lgray=C(3);
        White=C(4);
      case 3;
        Black=C(1);
        Dgray=C(2);
        White=C(3);
      case 2;
        Black=C(1);
        White=C(2);
        end;

        hor_tile=largeur/8;
        vert_tile=hauteur/8;
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
            for i=1:8
              for j=1:8
                if b(i,j)==Lgray;  V1(j)=('1'); V2(j)=('0');end
                if b(i,j)==Dgray;  V1(j)=('0'); V2(j)=('1');end
                if b(i,j)==White;  V1(j)=('0'); V2(j)=('0');end
                if b(i,j)==Black;  V1(j)=('1'); V2(j)=('1');end
              end
              O=[O,bin2dec(V1),bin2dec(V2)];
            end
            if tile==40
              imshow(a)
              h=rectangle('Position',[1 y_graph 160-1 16],'EdgeColor','r', 'LineWidth',3,'FaceColor', [0, 1, 0]);
              drawnow
              y_graph=y_graph+16;
              ##printing appends here, packets are sent by groups of 40 tiles
              DATA_READY=[DATA,O];
              DATA_READY = add_checksum(DATA_READY);
              packets=packets+1;
              disp(['Buffering DATA packet#',num2str(packets)]);
              ##--------printing loop-----------------------------
##              send_packet(INIT);
##              pause(0.1);##skip the first packet without
##              disp(['Sending DATA packet#',num2str(packets)]);
##              send_packet(DATA_READY);
##              send_packet(EMPT);##mandatory in the protocol
##              send_packet(PRNT);
##              pause(1);##Time for the printer head to print one line of 16 pixels
              ##---------------------------------------------------
              O=[];
              tile=0;
            end
            L=L+8;
            L_tile=L_tile+1;
            if L>=largeur
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
        ##--------printing loop-----------------------------
##        send_packet(INIT);
##        pause(0.1);
##        send_packet(EMPT);##mandatory in the protocol
##        disp('Sending PRNT command with margin');
##        PRNT_INI(8)=margin; ##prepare PRINT command with margin
##        PRNT = add_checksum(PRNT_INI);
##        send_packet(PRNT);
##        pause(margin);
##        PRNT_INI(8)=0x00; ##restore PRINT command without margin for next image
##        PRNT = add_checksum(PRNT_INI);
        ##---------------------------------------------------
      end

      disp('Closing serial port')
      arduinoObj=[];
      disp('End of printing')

