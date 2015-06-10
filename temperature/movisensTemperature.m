% movisensTemperature analyzes the data from the Movisens sensors at the
% wrist, chest and thigh

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_wrist-left_tempskin.bin
%       /btmn_0000_actigraphy_thigh-left_tempskin.bin
%       /btmn_0000_actigraphy_chest_tempskin.bin
clear all; close all; clc;

%PATH            = '/data1/recordings/btmn/subjects/';
%SUB_PATH        = '/actigraphy/raw/';
PATH1           = '/Volumes/data1/recordings/btmn/import/140806_actigraphy_blindert/';
PATH2           = '/Volumes/data1/recordings/btmn/import/141205_actigraphy_blindert/';
PATH3           = '/Volumes/data1/recordings/btmn/import/150120_actigraphy_blindert/';
PATH_TIMESTAMPS = '/Volumes/data1/projects/btmn/analysis/amb/behavior_timestamps/';
OUTPUT_FOLDER   = '/Volumes/data2/projects/btmn/analysis/amb/movisens-temperature/';
SIMLINK_FOLDER  = '/Users/me/Data/btmn/tmp/';

SUBJECTS1 = [1:4, 9, 11, 14];
SUBJECTS2 = [5, 6, 8, 12, 13, 15, 16, 19:20, 22:28, 31:35, 38, 43];
SUBJECTS3 = [36:37, 40:42, 44];
% Select subjects.
for iSubject = SUBJECTS3;
    
    % Subject string.
    SUBJECT = sprintf('%04.0f', iSubject);

    % Path to timestamps.
    TIMESTAMPS = [PATH_TIMESTAMPS 'btmn_' SUBJECT '_behavior_mobile_timestamps.csv'];

    % Load all the timestamps for this subject. Use the finger temperature
    % timestamps, because it has all samples across the 24h day as well as
    % the correct date.
    [id, subjectId, alarmLabels, alarmCounter, formLabels, alarmTimestamps] ...
        = timestampRead2(TIMESTAMPS);
    
    % Generate symbolic links on the fly in a /tmp folder.
    % Unisens data can only be loaded with the toolbox if the filenames are
    % acc|ecg|press|temp|tempskin.bin and in the same folder as the
    % unisens.xml.
    CHEST_TEMP = ['btmn_' SUBJECT '_actigraphy_chest_tempskin.bin'];
    CHEST_XML  = ['btmn_' SUBJECT '_actigraphy_chest_unisens.xml'];
    WRIST_TEMP = ['btmn_' SUBJECT '_actigraphy_wrist-left_tempskin.bin'];
    WRIST_XML  = ['btmn_' SUBJECT '_actigraphy_wrist-left_unisens.xml'];
    THIGH_TEMP = ['btmn_' SUBJECT '_actigraphy_thigh-left_tempskin.bin'];
    THIGH_XML  = ['btmn_' SUBJECT '_actigraphy_thigh-left_unisens.xml'];

    %UNISENS_FOLDER = [PATH SUBJECT SUB_PATH];
    
    % Load CHEST data.   
%     status = system(['ln -s ' UNISENS_FOLDER CHEST_XML ' ',...
%         SIMLINK_FOLDER 'unisens.xml']);
%     status = system(['ln -s ' UNISENS_FOLDER CHEST_TEMP ' ',...
%         SIMLINK_FOLDER 'tempskin.bin']);

    system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SIMLINK_FOLDER 'tempskin.bin']);
    system(['ln -s ' PATH3 CHEST_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' PATH3 CHEST_TEMP ' ' SIMLINK_FOLDER 'tempskin.bin']);
    
        temperatureChest = unisens_get_data(SIMLINK_FOLDER, 'tempskin.bin', 'all');

        % Extract start time from the unisens.xml file.
        str       = movisens.movisensXmlRead([SIMLINK_FOLDER 'unisens.xml']); 
        startTime = str.Attributes(4).Value;
        startTime = datenum(startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'); % note T in the middle!

        % Generate timestamps.
        % Sampling rate is fixed at 64 Hz.
        increment = 1/2*1000; % milliseconds
        N         = numel(temperatureChest); 
        endTime   = addtodate(startTime, fix(increment*(N-1)), 'millisecond'); 
        time      = linspace(startTime, endTime, N);

        % Create timeseries object.
        temperatureChest = timeseries(temperatureChest./100, time, 'Name', 'TEMP');
        temperatureChest.DataInfo.Unit  = 'mg';
        temperatureChest.TimeInfo.Units = 'milliseconds';
    
    
    % Load WRIST data.
    system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SIMLINK_FOLDER 'tempskin.bin']);
    system(['ln -s ' PATH3 WRIST_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' PATH3 WRIST_TEMP ' ' SIMLINK_FOLDER 'tempskin.bin']);
    
        temperatureWrist = unisens_get_data(SIMLINK_FOLDER, 'tempskin.bin', 'all');

        % Extract start time from the unisens.xml file.
        str       = movisens.movisensXmlRead([SIMLINK_FOLDER 'unisens.xml']); 
        startTime = str.Attributes(4).Value;
        startTime = datenum(startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'); % note T in the middle!

        % Generate timestamps.
        increment = 1/2*1000; % milliseconds
        N         = numel(temperatureWrist); 
        endTime   = addtodate(startTime, fix(increment*(N-1)), 'millisecond'); 
        time      = linspace(startTime, endTime, N);

        % Create timeseries object.
        temperatureWrist = timeseries(temperatureWrist./100, time, 'Name', 'TEMP');
        temperatureWrist.DataInfo.Unit  = 'mg';
        temperatureWrist.TimeInfo.Units = 'milliseconds';

    % Load THIGH data.
    system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SIMLINK_FOLDER 'tempskin.bin']);
    system(['ln -s ' PATH3 THIGH_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' PATH3 THIGH_TEMP ' ' SIMLINK_FOLDER 'tempskin.bin']);
    
        temperatureThigh = unisens_get_data(SIMLINK_FOLDER, 'tempskin.bin', 'all');

        % Extract start time from the unisens.xml file.
        str       = movisens.movisensXmlRead([SIMLINK_FOLDER 'unisens.xml']); 
        startTime = str.Attributes(4).Value;
        startTime = datenum(startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'); % note T in the middle!

        % Generate timestamps.
        increment = 1/2*1000; % milliseconds
        N         = numel(temperatureThigh); 
        endTime   = addtodate(startTime, fix(increment*(N-1)), 'millisecond'); 
        time      = linspace(startTime, endTime, N);

        % Create timeseries object.
        temperatureThigh = timeseries(temperatureThigh./100, time, 'Name', 'TEMP');
        temperatureThigh.DataInfo.Unit  = 'mg';
        temperatureThigh.TimeInfo.Units = 'milliseconds';

    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_skin-temperature_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 9), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', 'startTime', 'endTime', ...
        'meanTemperatureChest', 'meanTemperatureWrist', 'meanTemperatureThigh');              
    fclose(fid);
        
    for iStamp = 1:numel(alarmTimestamps)
    
        % Alarm timestamp.
        alarmTime = alarmTimestamps(iStamp);
        
        % Get 20 minute period of data around the phone alarms;
        % Add 5 min; subtract 15 min.
        startTime = addtodate(alarmTime, -15, 'minute');
        endTime   = addtodate(alarmTime, 5, 'minute');
        
        if exist('temperatureChest', 'var')
            temperatureChestData = getsampleusingtime(temperatureChest, startTime, endTime);
            meanTemperatureChest = mean(temperatureChestData);
        else
            meanTemperatureChest = [];
        end
        
        if exist('temperatureWrist', 'var')
            temperatureThighData = getsampleusingtime(temperatureWrist, startTime, endTime);
            meanTemperatureWrist = mean(temperatureThighData);        
        else
            meanTemperatureWrist = [];
        end
        
        if exist('temperatureThigh', 'var')
            temperatureThighData = getsampleusingtime(temperatureThigh, startTime, endTime);
            meanTemperatureThigh = mean(temperatureThighData);        
        else
            meanTemperatureThigh = [];
        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel = formLabels{iStamp};
        
        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_skin-temperature_features.csv'], 'a');
        fprintf(fid, '%4.0f, %4.0f, %s, %s, %s, %s, %s, %4.2f, %4.2f, %4.2f\n', ...
                 iSubject, alarmCounter(iStamp), alarmLabel, formLabel, ...
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                 meanTemperatureChest, meanTemperatureWrist, meanTemperatureThigh);
        fclose(fid);
             
    end

end
