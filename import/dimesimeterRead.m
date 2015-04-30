function [lux, cla, cs, act, x, y] = dimesimeterRead(filename)
% DIMESIMETERREAD loads data from a Dimesimeter txt file 
% filename is a  _dimeprocessed.txt file with 7 columns:
% [Time	Lux	CLA	CS	Activity	x	y]
%
% Argument:
%   filename - path to dimesimeter file 
%
% Results:
%   lux - timeseries of lux 
%   cla - timeseries of circadian lux
%   cs  - timeseries of circadian stimulus
%   act - timeseries of activity counts
%   x   - timeseries of x activity
%   y   - timeseries of y activity
%
% For more details on CS see: Rea et al. 2005 213.
%
% Copyright (c) 2014 Bart te Lindert

format = '%s%s%s%s%s%s%s';
fid    = fopen(filename);
C      = textscan(fid, format, 'delimiter', '\t', 'headerlines', 1); 
fclose(fid);

time = datenum(C{1,1}, 'HH:MM:SS mm/dd/yy'); 
lux  = str2double(C{1,2});
cla  = str2double(C{1,3});
cs   = str2double(C{1,4});
act  = str2double(C{1,5});
x    = str2double(C{1,6});
y    = str2double(C{1,7});

% Create timeseries.
% Lux.
lux = timeseries(lux, time, 'Name', 'LUX');
lux.DataInfo.Unit  = 'lux';
lux.TimeInfo.Units = 'minutes';

% Circadian lux.
cla = timeseries(cla, time, 'Name', 'CLA');
cla.DataInfo.Unit  = 'Weighted lux';
cla.TimeInfo.Units = 'minutes';

% Circadian stimulus.
cs = timeseries(cs, time, 'Name', 'CS');
cs.DataInfo.Unit  = 'Weighted W/m^2';
cs.TimeInfo.Units = 'minutes';

% Activity.
act = timeseries(act, time, 'Name', 'ACT');
act.DataInfo.Unit  = 'counts';
act.TimeInfo.Units = 'minutes';

% X.
x = timeseries(x, time, 'Name', 'X');
x.DataInfo.Unit  = 'lux';
x.TimeInfo.Units = 'minutes';

% Y.
y = timeseries(y, time, 'Name', 'Y');
y.DataInfo.Unit  = 'lux';
y.TimeInfo.Units = 'minutes';

