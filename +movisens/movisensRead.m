function data = movisensRead(filename)
% MOVISENSREAD loads data from a movisens bin file 
% filename is a .bin file with X columns:
% [  ]
%
% Argument:
%   filename - path to movisens file 
%
% Results:
%   temp - timesseries of data 
%
% Copyright (c) 2014 Bart te Lindert

if strcmpi(filename(end-6:end), 'acc.bin')
    % Create ACC timeseries.
    data = unisens_get_data(filename, 'acc.bin', 'all');
    data = timeseries(data, time, 'Name', 'ACC'); %%%time?
    data.DataInfo.Unit  = 'mg';
    data.TimeInfo.Units = 'milliseconds';
    
elseif strcmpi(filename(end-6:end), 'ecg.bin')
    % Create ECG timeseries.
    data = unisens_get_data(filename, 'ecg.bin', 'all');
    data = timeseries(data, time, 'Name', 'ECG'); %%%time?
    data.DataInfo.Unit  = 'mV';
    data.TimeInfo.Units = 'milliseconds';

elseif strcmpi(filename(end-8:end), 'press.bin')
    % Create PRESS timeseries.
    data = unisens_get_data(filename, 'press.bin', 'all');
    data = timeseries(data, time, 'Name', 'PRESS'); %%%time?
    data.DataInfo.Unit  = '';
    data.TimeInfo.Units = 'milliseconds';

elseif strcmpi(filename(end-7:end), 'temp.bin')
    % Create TEMP timeseries.
    data = unisens_get_data(filename, 'temp.bin', 'all');
    data = timeseries(data, time, 'Name', 'TEMP'); %%%time?
    data.DataInfo.Unit  = 'C';
    data.TimeInfo.Units = 'milliseconds';

elseif strcmpi(filename(end-11:end), 'tempskin.bin')
    % Create TEMPSKIN timeseries.
    data = unisens_get_data(filename, 'tempskin.bin', 'all');
    data = timeseries(data, time, 'Name', 'TEMP'); %%%time? TEMPSKIN
    data.DataInfo.Unit  = 'C';
    data.TimeInfo.Units = 'milliseconds';

end