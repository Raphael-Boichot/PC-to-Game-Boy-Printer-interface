function [DATA_packets_to_print]=image_slicer(currentfilename)
close all
packets=0;
[a,map]=imread(currentfilename);
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
            x = [1, 160, 160, 1];             % X coordinates of rectangle corners
            y = [y_graph, y_graph, y_graph+16, y_graph+16];  % Y coordinates
            h = patch(x, y, [1 0 0]);         % Red fill
            set(h, 'EdgeColor', 'r', 'LineWidth', 1, 'FaceAlpha', 0.25);  % 50% transparent
            drawnow
            y_graph=y_graph+16;
            packets=packets+1;
            %printing appends here, packets are sent by groups of 40 tiles
            disp(['Buffering DATA packet#',num2str(packets)]);
            DATA_packets_to_print(packets,:)=O;
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
imshow(a)
colormap gray
pause(0.5)
close all