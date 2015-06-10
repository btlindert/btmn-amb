function data = movisensRead(fileName)
% MOVISENSREAD loads data from a movisens .bin file 
%
% Argument:
%   fileName - fully specified file name (i.e. including path) to Movisens file 
%
% Results:
%   data - time series of data if 'ECG', 'PRESS', 'TEMP', 'SKINTEMP' 
%        - time series collection (x,y,z) data if 'ACC'
% Copyright (c) 2014-2015 Bart te Lindert


% Split fileName into parts.
[path, name, ext] = fileparts(fileName);

if ~strcmpi(ext, '.bin')
    error('File has to be .bin')
    return 
end

% Extract start time from the unisens.xml file.
str       = movisensXmlRead([path '/unisens.xml']); 
startTime = str.Attributes(4).Value;
startTime = datenum(startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'); % note T in the middle!

% Load lsbValues.
[ecgLsbValue, accLsbValue, tempskinLsbValue, tempLsbValue, pressLsbValue] = ...
    movisensGetLsbValue(str);

% ACC
if strcmpi(name, 'acc')
    % Get data.
    data = unisens_get_data(path, 'acc.bin', 'all');
    data = data.*accLsbValue;

    % Generate time stamps.
    increment = 1/64*1000;
    N = size(data, 1);
    endTime = addtodate(startTime, fix(increment*(N-1)), 'millisecond');
    time = linspace(startTime, endTime, N);
    
    % Create time series.
    accx = timeseries(data(:,1), time, 'Name', 'ACCX');
    accx.DataInfo.Unit  = 'mg';
    accx.TimeInfo.Units = 'milliseconds';
    
    accy = timeseries(data(:,2), time, 'Name', 'ACCY');
    accy.DataInfo.Unit  = 'mg';
    accy.TimeInfo.Units = 'milliseconds';
    
    accz = timeseries(data(:,3), time, 'Name', 'ACCZ');
    accz.DataInfo.Unit  = 'mg';
    accz.TimeInfo.Units = 'milliseconds';
    
    data = tscollection({accx, accy, accz});
    
% ECG
elseif strcmpi(name, 'ecg')
    % Get data.
    data = unisens_get_data(path, 'ecg.bin', 'all');
    data = data.*ecgLsbValue;
    
    % Generate time stamps.
    increment = 1/1024*1000;
    N = numel(data);
    endTime = addtodate(startTime, fix(increment*(N-1)), 'millisecond');
    time = linspace(startTime, endTime, N);
    
    % Create time series.
    data = timeseries(data, time, 'Name', 'ECG');
    data.DataInfo.Unit  = 'mV';
    data.TimeInfo.Units = 'milliseconds';

% PRESS
elseif strcmpi(name, 'press')
    % Create PRESS timeseries.
    data = unisens_get_data(path, 'press.bin', 'all');
    data = data.*pressLsbValue;
    
    % Generate time stamps.
    increment = 1/8*1000;
    N = numel(data);
    endTime = addtodate(startTime, fix(increment*(N-1)), 'millisecond');
    time = linspace(startTime, endTime, N);
    
    % Create time series.
    data = timeseries(data, time, 'Name', 'PRESS');
    data.DataInfo.Unit  = 'Pa';
    data.TimeInfo.Units = 'milliseconds';

% TEMP
elseif strcmpi(name, 'temp')
    % Create TEMP timeseries.
    data = unisens_get_data(path, 'temp.bin', 'all');
    data = data.*tempLsbValue;
    
    % Generate time stamps.
    increment = 1000;
    N = numel(data);
    endTime = addtodate(startTime, fix(increment*(N-1)), 'millisecond');
    time = linspace(startTime, endTime, N);
    
    % Create time series.
    data = timeseries(data, time, 'Name', 'TEMP');
    data.DataInfo.Unit  = 'Celsius';
    data.TimeInfo.Units = 'milliseconds';

% TEMPSKIN
elseif strcmpi(name, 'tempskin')
    % Create TEMPSKIN timeseries.
    data = unisens_get_data(path, 'tempskin.bin', 'all');
    data = data.*tempskinLsbValue;
    
    % Generate time stamps.
    increment = 1/2*1000;
    N = numel(data);
    endTime = addtodate(startTime, fix(increment*(N-1)), 'millisecond');
    time = linspace(startTime, endTime, N);
    
    % Create time series.
    data = timeseries(data, time, 'Name', 'TEMP');
    data.DataInfo.Unit  = 'Celsius';
    data.TimeInfo.Units = 'milliseconds';

end