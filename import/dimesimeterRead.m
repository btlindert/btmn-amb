function [lux, act] = dimesimeterRead(filename)
% DIMESIMETERREAD loads data from a Dimesimeter txt file 
% filename is a  _dimeprocessed.txt file with 7 columns:
% [Time	Lux	CLA	CS	Activity	x	y]
%
% Argument:
%   filename - path to dimesimeter file 
%
% Results:
%   lux - timesseries of lux 
%   act - timeseries of activity counts
%
% Copyright (c) 2014 Bart te Lindert

format = '%s%s%s%s%s%s%s';
fid    = fopen(filename);
C      = textscan(fid, format, 'delimiter', '\t', 'headerlines', 1); 
fclose(fid);

time     = C{1,1};
lux      = C{1,2};
activity = C{1,5};

% Convert strings to nums/doubles.
time = datenum(time, 'HH:MM:SS mm/dd/yy');
lux  = str2double(lux);
act  = str2double(activity);

% Create timeseries.
lux = timeseries(lux, time, 'Name', 'LUX');
lux.DataInfo.Unit  = 'lux';
lux.TimeInfo.Units = 'minutes';

act = timeseries(act, time, 'Name', 'ACT');
act.DataInfo.Unit  = 'counts';
act.TimeInfo.Units = 'minutes';
