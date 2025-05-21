function [data_out]=add_lenght(data_in,length)
LSB=rem(length,256);%OK
MSB=rem(((length-LSB)/256),256);
data_out=[data_in(1:4),LSB,MSB,data_in(7:end)];

