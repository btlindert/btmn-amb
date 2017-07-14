function [red, green, blue, cs, cla, lux, activity, redband, greenband, ...
    blueband, redbandRaw, greenbandRaw, bluebandRaw, calibVals] = rgbRead(file)
% RGBREAD loads data from a Dimesimeter txt file 
% filename is a  _header.txt file with 5 columns:
% [Time	Red Green Blue Activity]
%
% Argument:
%   filename - path to dimesimeter _header.txt file 
%
% Results:
%   red          - time series with red light (lux)
%   green        - time series with green light (lux)
%   blue         - time series with blue light (lux)
%   cs           - time series with circadian stimulus
%   cla          - time series with circadian light
%   lux          - time series with lux 
%   activity     - time series with activity
%   redband      - time series with redband from the _header.txtx
%   greenband    - time series with greenband from the _header.txt
%   blueband     - time series with blueband from the _header.txt
%   redbandRaw   - time series with redband from .txt
%   greenbandRaw - time series with greenband from .txt
%   bluebandRaw  - time series with blueband from .txt
%   calibValues  - struct with calibration values
%
% Copyright (c) 2017 Bart te Lindert
[filePath, fileName] = fileparts(file);

% Load calibration values.
fid = fopen(file);
str = textscan(fid, '%s%s%s', 'headerlines', 0, 'delimiter', '\t');
fclose(fid);

% Process header data. See Guide Dimesimeter for description of the values.
rgb = regexp(str{1,1}{1,1}, '\s', 'split');
rgb = str2double(strrep(rgb, '#', ''));
calibVals.r  = rgb(1,1);
calibVals.g  = rgb(1,2);
calibVals.b  = rgb(1,3);
calibVals.kp = str2double(strrep(str{1,1}{2,1},'#', ''));
calibVals.cp = str2double(str{1,1}{3,1});
calibVals.bc = str2double(str{1,1}{4,1});
calibVals.xa = str2double(strrep(str{1,1}{5,1}, '#', ''));
calibVals.ya = str2double(strrep(str{1,1}{8,1}, '#', ''));
calibVals.za = str2double(strrep(str{1,1}{11,1}, '#', ''));
calibVals.ap = str2double(str{1,2}{2,1});
calibVals.kc = str2double(str{1,2}{3,1});
calibVals.cc = str2double(str{1,2}{4,1});
calibVals.xb = str2double(str{1,2}{5,1});
calibVals.yb = str2double(str{1,2}{8,1});
calibVals.zb = str2double(str{1,2}{11,1});
calibVals.bp = str2double(str{1,3}{2,1});
calibVals.ac = str2double(str{1,3}{3,1});
calibVals.by = str2double(str{1,3}{4,1});
calibVals.xc = str2double(str{1,3}{5,1});
calibVals.yc = str2double(str{1,3}{8,1});
calibVals.zc = str2double(str{1,3}{11,1});

% Load timeseries data.
fid = fopen(file);
str = textscan(fid, '%s%s%s%s%s', 'headerlines', 6, 'delimiter', ' ');
fclose(fid);

% Columns time, red, green, blue, activity.
% data.timeQ     = str2double(str{1}); 
data.redband   = str2double(str{2});
data.greenband = str2double(str{3});
data.blueband  = str2double(str{4});
data.activity  = str2double(str{5});

% Convert to colors and lux ...
data.red     = calibVals.r*calibVals.ap*data.redband;
data.green   = calibVals.g*calibVals.bp*data.greenband;
data.blue    = calibVals.b*calibVals.cp*data.blueband;
data.lux     = calibVals.kp*(data.red + data.green + data.blue);

% Calculate CLA.
idx           = find((calibVals.b*data.blueband) >= (calibVals.by*data.lux));
data.cla      = calibVals.cc*calibVals.b*data.blueband;
data.cla(idx) = (calibVals.ac*calibVals.b*data.blueband(idx)) - (calibVals.bc*data.lux(idx));

% Calculate CS.
data.cs = 0.75 - (0.75./(1+(data.cla./215.75).^0.864)); 

% Calculate Activity.
data.activity = sqrt(data.activity)*0.0156;

% Now the date has to be extracted from the raw .txt file i.e without the
% _header extension.
fileName = strrep(fileName, '_header', '');
calibVals.rawFile = [filePath filesep fileName '.txt'];

% For some odd reason the 3rd to 8th sample represent the year, month, day,
% hour, minute and interval respectively.
fid = fopen(calibVals.rawFile);
rawData = textscan(fid, '%f');
fclose(fid);

rawData = rawData{1,1};

year     = rawData(3);
month    = rawData(4);
day      = rawData(5);
hour     = rawData(6);
minute   = rawData(7);
calibVals.interval = rawData(8);

% Calculate the start date.
calibVals.start = [ num2str(hour, '%02.0f'), ':', num2str(minute, '%02.0f'), ':00', ' ', num2str(month, '%02.0f'), '/', num2str(day, '%02.0f'), '/', num2str(year)];

% While we are at it, we could verify the calculation of the redband,
% blueband, greenband and activity values in the _header file. 
% for i = 24:8:length(rawData)
%     
%     j = i/8 - 2;   % output enumerator
%     obs = i/8 - 3; % observation count - 1 (minutes to add to start time)
%     
%     data.time(j)         = datenum(calibVals.start) + (int/86400)*obs;
%     data.redbandRaw(j)   = 256*rawData(i - 7) + rawData(i - 6);
%     data.greenbandRaw(j) = 256*rawData(i - 5) + rawData(i - 4);
%     data.bluebandRaw(j)  = 256*rawData(i - 3) + rawData(i - 2);
%     data.activityRaw(j)  = 256*rawData(i - 1) + rawData(i);
%     
%     if(mod(data.activityRaw(j), 2) > 0) % If and odd number ...
%         data.redbandRaw(j)   = data.redbandRaw(j)/5;   % Equal to data.redband
%         data.greenbandRaw(j) = data.greenbandRaw(j)/5; % Equal to data.greenband
%         data.bluebandRaw(j)  = data.bluebandRaw(j)/5;  % Equal to data.blueband
%     end
%     data.activityRaw(j) = data.activityRaw(j)/2;   
%     
% end
% data.activityRaw = sqrt(double(data.activityRaw))*0.0156; % Equal to data.activity

% Let's speed this up...
rawDataShaped     = rawData(17:end);
rawDataShaped     = reshape(rawDataShaped, [8, length(rawDataShaped)/8]);
data.redbandRaw   = 256*rawDataShaped(1,:) + rawDataShaped(2,:);
data.greenbandRaw = 256*rawDataShaped(3,:) + rawDataShaped(4,:);
data.bluebandRaw  = 256*rawDataShaped(5,:) + rawDataShaped(6,:);
data.activityRaw  = 256*rawDataShaped(7,:) + rawDataShaped(8,:);

if(mod(data.activityRaw, 2) > 0) % If odd number ...
    data.redbandRaw   = data.redbandRaw/5;   % Equal to data.redband
    data.greenbandRaw = data.greenbandRaw/5; % Equal to data.greenband
    data.bluebandRaw  = data.bluebandRaw/5;  % Equal to data.blueband
end
data.activityRaw = data.activityRaw/2;   
data.activityRaw = sqrt(double(data.activityRaw))*0.0156; % Equal to data.activity
data.time        = datenum(calibVals.start) + (calibVals.interval/86400).*(0:length(data.redbandRaw));


% There is one more thing to fix. The _processed.txt file tends to have
% fewer lines than the _header.txt file. At a certain point the _header
% just writes gibberish to the file which should be checked and eliminated.
% They can be identified by RBG = 13107 and activity = 32767
endOfData = find(data.redband == 13107, 1, 'first');

if isempty(endOfData)
    endOfData = length(data.redband);
else
    endOfData = endOfData - 1;
end

% Let's limit all data series to the valid range of observations.
data.time = data.time(1:endOfData);

% Create timeseries.
red = timeseries(data.red(1:endOfData), data.time, 'Name', 'RED');
red.DataInfo.Unit  = '';
red.TimeInfo.Units = 'minutes';

blue = timeseries(data.blue(1:endOfData), data.time, 'Name', 'BLUE');
blue.DataInfo.Unit  = '';
blue.TimeInfo.Units = 'minutes';

green = timeseries(data.green(1:endOfData), data.time, 'Name', 'GREEN');
green.DataInfo.Unit  = '';
green.TimeInfo.Units = 'minutes';

cs = timeseries(data.cs(1:endOfData), data.time, 'Name', 'CS');
cs.DataInfo.Unit  = '';
cs.TimeInfo.Units = 'minutes';

cla = timeseries(data.cla(1:endOfData), data.time, 'Name', 'CLA');
cla.DataInfo.Unit  = '';
cla.TimeInfo.Units = 'minutes';

lux = timeseries(data.lux(1:endOfData), data.time, 'Name', 'LUX');
lux.DataInfo.Unit  = '';
lux.TimeInfo.Units = 'minutes';

activity = timeseries(data.activity(1:endOfData), data.time, 'Name', 'ACT');
activity.DataInfo.Unit  = '';
activity.TimeInfo.Units = 'minutes';

redband = timeseries(data.redband(1:endOfData), data.time, 'Name', 'REDband');
redband.DataInfo.Unit  = '';
redband.TimeInfo.Units = 'minutes';

blueband = timeseries(data.blueband(1:endOfData), data.time, 'Name', 'BLUEband');
blueband.DataInfo.Unit  = '';
blueband.TimeInfo.Units = 'minutes';

greenband = timeseries(data.greenband(1:endOfData), data.time, 'Name', 'GREENband');
greenband.DataInfo.Unit  = '';
greenband.TimeInfo.Units = 'minutes';

redbandRaw = timeseries(data.redbandRaw(1:endOfData), data.time, 'Name', 'REDbandRaw');
redbandRaw.DataInfo.Unit  = '';
redbandRaw.TimeInfo.Units = 'minutes';

bluebandRaw = timeseries(data.bluebandRaw(1:endOfData), data.time, 'Name', 'BLUEbandRaw');
bluebandRaw.DataInfo.Unit  = '';
bluebandRaw.TimeInfo.Units = 'minutes';

greenbandRaw = timeseries(data.greenbandRaw(1:endOfData), data.time, 'Name', 'GREENbandRaw');
greenbandRaw.DataInfo.Unit  = '';
greenbandRaw.TimeInfo.Units = 'minutes';

end