function []=send_packet(packet_TX)
global arduinoObj
for i=1:1:length(packet_TX)
    fwrite(arduinoObj,packet_TX(i),"uint8");
    fread(arduinoObj,1,"uint8");
end
