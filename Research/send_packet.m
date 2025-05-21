function [response_packet]=send_packet(packet_TX)
global arduinoObj
for i=1:1:length(packet_TX)
    fwrite(arduinoObj,packet_TX(i));
    response_packet(i)=fread(arduinoObj,1);
end
response_packet = auto_shifting(response_packet);

