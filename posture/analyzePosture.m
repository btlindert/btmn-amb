% analyzePosture analyzes the accelerometer data from the thigh and
% chest sensors to extract posture.

% Path order is as follows:
% /data1/recordings/btmn/subject/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_acc.bin (chest)
%       /btmn_0000_actigraphy_unisens.xml (chest)
%       /btmn_0000_actigraphy_thigh-left_acc.bin
%       /btmn_0000_actigraphy_thigh-left_unisens.xml
clear all; close all; clc

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/150430_behavior_blindert/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/posture/';
SIMLINK_FOLDER  = OUTPUT_FOLDER;
MISSING         = [5, 7, 10, 17, 18, 21, 29, 39];
ALL             = 1:44;
SUBJECTS        = setdiff(ALL, MISSING);

fprintf('SUBJECT: 0000, ALARM: 00\n');

for iSubject = SUBJECTS(16:end)
    
    % Since 'exist' does not work on tscollection objects we define vars to
    % specify if a var is present.
    accChestPresent = 0;
    accThighPresent = 0;

    % Subject string.
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Paths to files.
    CHEST_ACC = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_acc.bin'];
    CHEST_XML = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_unisens.xml'];
    THIGH_ACC = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_thigh-left_acc.bin'];
    THIGH_XML = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_thigh-left_unisens.xml'];

    % Generate temporary symbolic links on the fly in a SIMLINK_FOLDER.
    % Links to the *acc.bin and the *unisens.xml need to be created.
    % Unisens data can only be loaded with the toolbox if the filenames are
    % acc|ecg|press|temp|tempskin.bin and in the same folder as the
    % unisens.xml.
    
    % Check if each file exists and load.
    if (exist(CHEST_ACC, 'file') == 2) && (exist(CHEST_XML, 'file') == 2)
        
        % Create sym-links.
        status = system(['ln -s ' CHEST_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
        status = system(['ln -s ' CHEST_ACC ' ' SIMLINK_FOLDER 'acc.bin']);

        % Load data.
        accChest = movisensRead([SIMLINK_FOLDER, 'acc.bin']);
        accChestPresent = 1;
        
        % Remove sym-links.
        status = system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
        status = system(['rm ' SIMLINK_FOLDER 'acc.bin']);
       
    end
    
    if (exist(THIGH_ACC, 'file') == 2) && (exist(THIGH_XML, 'file') == 2)
       
        % Create sym-links.
        status = system(['ln -s ' THIGH_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
        status = system(['ln -s ' THIGH_ACC ' ' SIMLINK_FOLDER 'acc.bin']);
    
        % Load data.
        accThigh = movisensRead([SIMLINK_FOLDER, 'acc.bin']);
        accThighPresent = 1;  
        
        % Remove sym-links.
        status = system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
        status = system(['rm ' SIMLINK_FOLDER 'acc.bin']);
    end
       
    % Path to timestamps.
    TIMESTAMPS = [PATH_TIMESTAMPS 'btmn_' SUBJECT '_behavior_mobile_timestamps.csv'];

    % Load all the timestamps for this subject.
    [id, subjectId, alarmLabels, alarmCounter, formLabels, alarmTimestamps] ...
        = timestampRead(TIMESTAMPS);
         
    % Write headers to the output file.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_posture_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 7), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ... 
        'alarmTime', 'startTime', 'endTime', ...
        'posture');       
    fclose(fid);

    % Loop through all the samples.
    for iStamp = 1:numel(alarmTimestamps)

        % Progress update.
        ISTAMP = sprintf('%02.0f', iStamp);
        fprintf(['\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b%s, ALARM: %s\n'], SUBJECT, ISTAMP);
             
        % Alarm time stamp.
        alarmTime = alarmTimestamps(iStamp);

        % Get a 5 minute period of data around the phone alarms.
        startTime = alarmTime;
        endTime   = addtodate(alarmTime, 5, 'minute');

        % Not all files were collected so we test for the existence of the file
        % first.
        if accChestPresent == 1

            % Data.
            accChestData = getsampleusingtime(accChest, startTime, endTime);
       
        end
        
        if accThighPresent == 1

            % Data.
            accThighData = getsampleusingtime(accThigh, startTime, endTime);
            
        end
        
        if ~isempty(accChestData) && ~isempty(accThighData)

            classification = posture(accChestData, accThighData, 'off');
            
        else
            
            classification = 99;

        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};
        
        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_posture_features.csv'], 'a');
        fprintf(fid, '%4.0f, %4.0f, %s, %s, %s, %s, %s, %g\n', ...
                 iSubject, alarmCounter(iStamp), alarmLabel, formLabel, ... 
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                 classification);
        fclose(fid);

        %clear accThighData accChestData
        
    end
    
end