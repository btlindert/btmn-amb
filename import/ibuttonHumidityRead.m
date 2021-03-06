function humidity = ibuttonHumidityRead(filename)
% IBUTTONREAD loads data from an iButton csv/txt file 
% filename is a file with 3 columns:
% [Date/Time, Uni,t Value]
%
% Argument:
%   filename - path to humidity data file 
%
% Results:
%   humidity - timeseries of humidity 
%
% Copyright (c) 2014 Bart te Lindert

ext = filename(end-3:end);

% If file is .csv
if strcmpi(ext, '.csv')
       
    format = '%s%s%s';
    fid    = fopen(filename);
    C      = textscan(fid, format, 'delimiter', ',', 'headerlines', 20); 
    fclose(fid);

    time     = C{1,1};
    humidity = C{1,3};

    time = datenum(time, 'mm/dd/yy HH:MM:SS PM');
    humidity = str2double(humidity);

    humidity = timeseries(humidity, time, 'Name', 'HUMID');
    humidity.DataInfo.Unit  = '%RH';
    humidity.TimeInfo.Units = 'minutes';

% File is a .txt
elseif strcmpi(ext, '.txt')
    
    format = '%s%s%s';
    fid    = fopen(filename);
    C      = textscan(fid, format, 'delimiter', ','); 
    fclose(fid);

    time     = C{1,1};
    humidity = C{1,3};

    time = datenum(time, 'mm/dd/yy HH:MM:SS PM');
    humidity = str2double(humidity);

    humidity = timeseries(humidity, time, 'Name', 'HUMID');
    humidity.DataInfo.Unit  = '%RH';
    humidity.TimeInfo.Units = 'minutes';
end