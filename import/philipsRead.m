function temp = philipsRead(filename)
% PHILIPSTEMPREAD loads data from a philips temp csv/txt file 
% filename is a .txt file with 2 columns:
% [date/time    temp]
%
% Argument:
%   filename - path to philipstemp file 
%
% Results:
%   temp - timesseries of data 
%
% Copyright (c) 2014 Bart te Lindert

format = '%s%s%s';
fid    = fopen(filename);
C      = textscan(fid, format, 'delimiter', ',', 'headerlines', 20); 
fclose(fid);

time = C{1,1};
temp = C{1,3};

time = datenum(time, 'dd-mm-yy HH:MM:SS.FFF');
temp = str2double(temp); % 4 digit number, divide by 100 for actual temp
temp = temp./100;

temp = timeseries(temp, time, 'Name', 'TEMP');
temp.DataInfo.Unit  = 'Celsius';
temp.TimeInfo.Units = 'minutes';