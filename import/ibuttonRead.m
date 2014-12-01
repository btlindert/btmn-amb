function [temp humidity] = ibuttonRead(filename)
% IBUTTONREAD loads data from an iButton csv file 
% filename is a .csv file with 3 columns:
% [Date/Time Unit Value]
%
% Argument:
%   filename - path to ibutton file 
%
% Results:
%   temp - timesseries of temperature 
%
% Copyright (c) 2014 Bart te Lindert

format = '%s%s%s';
fid    = fopen(filename);
C      = textscan(fid, format, 'delimiter', ',', 'headerlines', 20); 
fclose(fid);

time = C{1,1};
temp = C{1,3};

time = datenum(time, 'mm/dd/yy HH:MM:SS PM');
temp = str2double(temp);

temp = timeseries(temp, time, 'Name', 'TEMP');
temp.DataInfo.Unit  = 'Celsius';
temp.TimeInfo.Units = 'minutes';