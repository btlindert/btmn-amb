function temperature = ibuttonTemperatureRead(filename)
% IBUTTONTEMPERATUREREAD loads data from an iButton csv/txt file 
% filename is a file with 3 columns:
% [Date/Time, Unit, Value]
%
% Argument:
%   filename - path to temperature data file 
%
% Results:
%   temperature - timeseries of temperature
%
% Copyright (c) 2014 Bart te Lindert

ext = filename(end-3:end);

% If file is .csv
if strcmpi(ext, '.csv')
       
    format = '%s%s%s';
    fid    = fopen(filename);
    C      = textscan(fid, format, 'delimiter', ',', 'headerlines', 20); 
    fclose(fid);

    time        = C{1,1};
    temperature = C{1,3};

    time = datenum(time, 'mm/dd/yy HH:MM:SS PM');
    temperature = str2double(temperature);

    temperature = timeseries(temperature, time, 'Name', 'TEMP');
    temperature.DataInfo.Unit  = 'Celsius';
    temperature.TimeInfo.Units = 'minutes';

% File is a .txt
elseif strcmpi(ext, '.txt')
    
    format = '%s%s%s';
    fid    = fopen(filename);
    C      = textscan(fid, format, 'delimiter', ','); 
    fclose(fid);

    time     = C{1,1};
    temperature = C{1,3};

    time = datenum(time, 'mm/dd/yy HH:MM:SS PM');
    temperature = str2double(temperature);

    temperature = timeseries(temperature, time, 'Name', 'TEMP');
    temperature.DataInfo.Unit  = 'Celsius';
    temperature.TimeInfo.Units = 'minutes';
    
end