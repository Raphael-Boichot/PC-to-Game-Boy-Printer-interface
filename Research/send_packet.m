function [keepalive, error]=send_packet(packet_TX)
global arduinoObj
packet_size=length(packet_TX);
for i=1:1:packet_size
    fwrite(arduinoObj,packet_TX(i),"uint8");
    pause(0.0001);
    out=[];
    out=fread(arduinoObj,1,"uint8");
    flush(arduinoObj);
    if i==packet_size-1;
      keepalive=out;
    end
    if i==packet_size;
      error=out;
    end
end
disp[('keepalive=',dec2hex(keepalive),' error=',dec2hex(error)]);
##output the last bytes only

