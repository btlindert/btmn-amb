% analyzeActivity analyzes the accelerometer data from the thigh, wrist and
% chest sensors.

% Path order is as follows:
% /data1/recordings/btmn/subject/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_acc.bin (chest)
%       /btmn_0000_actigraphy_unisens.xml (chest)
%       /btmn_0000_actigraphy_thigh-left_acc.bin
%       /btmn_0000_actigraphy_thigh-left_unisens.xml
%       /btmn_0000_actigraphy_wrist-left_acc.bin
%       /btmn_0000_actigraphy_wrist-left_unisens.xml

PATH            = '/Volumes/data1/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_TIMESTAMPS = '/Volumes/data1/recordings/btmn/import/150430_behavior_blindert/';
OUTPUT_FOLDER   = '/Volumes/data2/projects/btmn/analysis/amb/activity/';
MISSING         = [5, 7, 10, 17, 18, 21, 29, 39];
ALL             = 1:44;
SUBJECTS        = setdiff(ALL, MISSING);

for iSubject = 1%SUBJECTS
    
    % Since 'exist' does not work on tscollection objects we define vars to
    % specify if a var is present.
    accChestPresent = 0;
    accThighPresent = 0;
    accWristPresent = 0;
    
    % Subject string.
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Paths to files.
    CHEST_ACC = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_acc.bin'];
    CHEST_XML = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_unisens.xml'];
    WRIST_ACC = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_acc.bin'];
    WRIST_XML = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_unisens.xml'];
    THIGH_ACC = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_thigh-left_acc.bin'];
    THIGH_XML = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_thigh-left_unisens.xml'];

    % Generate temporary symbolic links on the fly in a SIMLINK_FOLDER.
    % Links to the *acc.bin and the *unisens.xml need to be created.
    % Unisens data can only be loaded with the toolbox if the filenames are
    % acc|ecg|press|temp|tempskin.bin and in the same folder as the
    % unisens.xml.
    tic
    % Check if each file exists and load chest data.
    if (exist(CHEST_ACC, 'file') == 2) && (exist(CHEST_XML, 'file') == 2)
        
        accChestPresent = 1;
        
        % Create sym-links.
        status = system(['ln -s ' CHEST_XML ' ' OUTPUT_FOLDER 'unisens.xml']);
        status = system(['ln -s ' CHEST_ACC ' ' OUTPUT_FOLDER 'acc.bin']);

        % Load data.
        chest = movisensRead([OUTPUT_FOLDER, 'acc.bin']);
        
        % Create SVM time series.
        data = (sqrt(chest.accx.Data.^2 + chest.accy.Data.^2 + ...
            chest.accz.Data.^2));
        accChest = timeseries(data, chest.Time, 'name', 'SVM');
        
        % Remove sym-links.
        status = system(['rm ' OUTPUT_FOLDER 'unisens.xml']);
        status = system(['rm ' OUTPUT_FOLDER 'acc.bin']);
        
    end
    toc
    tic
    % Check if each file exists and load thigh data.
    if (exist(THIGH_ACC, 'file') == 2) && (exist(THIGH_XML, 'file') == 2)
       
        accThighPresent = 1;
        
        % Create sym-links.
        status = system(['ln -s ' THIGH_XML ' ' OUTPUT_FOLDER 'unisens.xml']);
        status = system(['ln -s ' THIGH_ACC ' ' OUTPUT_FOLDER 'acc.bin']);
    
        % Load data.
        thigh = movisensRead([OUTPUT_FOLDER, 'acc.bin']);
        
        % Create SVM time series.
        data = (sqrt(thigh.accx.Data.^2 + thigh.accy.Data.^2 + ...
            thigh.accz.Data.^2));
        accThigh = timeseries(data, thigh.Time, 'name', 'SVM');  
        
        % Remove sym-links.
        status = system(['rm ' OUTPUT_FOLDER 'unisens.xml']);
        status = system(['rm ' OUTPUT_FOLDER 'acc.bin']);
        
    end
    toc
    tic
    % Check if each file exists and load wrist data.
    if (exist(WRIST_ACC, 'file') == 2) && (exist(WRIST_XML, 'file') == 2)
        
        accWristPresent = 1;
        
        % Create sym-links.
        status = system(['ln -s ' WRIST_XML ' ' OUTPUT_FOLDER 'unisens.xml']);
        status = system(['ln -s ' WRIST_ACC ' ' OUTPUT_FOLDER 'acc.bin']);
    
        % Load data.
        wrist = movisensRead([OUTPUT_FOLDER, 'acc.bin']);
        
        % Create SVM time series.
        data = (sqrt(wrist.accx.Data.^2 + wrist.accy.Data.^2 + ...
            wrist.accz.Data.^2));
        accWrist = timeseries(data, wrist.Time, 'name', 'SVM');
        
        % Remove sym-links.
        status = system(['rm ' OUTPUT_FOLDER 'unisens.xml']);
        status = system(['rm ' OUTPUT_FOLDER 'acc.bin']);
        
    end 
    toc
    % Path to timestamps.
    TIMESTAMPS = [PATH_TIMESTAMPS 'btmn_' SUBJECT '_behavior_mobile_timestamps.csv'];

    % Load all the timestamps for this subject.
    [id, subjectId, alarmLabels, alarmCounter, formLabels, alarmTimestamps] ...
        = timestampRead(TIMESTAMPS);
         
    % Write headers to the output file.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_activity_features.csv'], 'w');
    fprintf(fid, [repmat('%s,', 1, 18), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ... 
        'alarmTime', 'startTime', 'endTime', ...
        'actThighMean', 'actThighMed', 'actThighSum', 'actThighMax', ...
        'actChestMean', 'actChestMed', 'actChestSum', 'actChestMax', ...
        'actWristMean', 'actWristMed', 'actWristSum', 'actWristMax');       
    fclose(fid);

    % Loop through all the samples.
    for iStamp = 1:numel(alarmTimestamps)
    
        tic
        % Alarm timeStamp.
        alarmTime = alarmTimestamps(iStamp);

        % Get 20 minute period of data around the phone alarms.
        startTime = addtodate(alarmTime, -15, 'minute');
        endTime   = addtodate(alarmTime, 5, 'minute');

        actChestMean = [];
        actChestMed = [];
        actChestSum = [];
        actChestMax = []; 
        
        actThighMean = [];
        actThighMed = [];
        actThighSum = [];
        actThighMax = [];
        
        actWristMean = [];
        actWristMed = [];
        actWristSum = [];
        actWristMax = [];
            
        % Not all files were collected so we test for the existence of the file
        % first.
        if accChestPresent == 1

            % Get data around alarm.
            actChestData = getsampleusingtime(accChest, startTime, endTime);

            if ~isempty(actChestData.Data)
                
                % Features.
                actChestMean = mean(actChestData);
                actChestMed  = median(actChestData);
                actChestSum  = sum(actChestData);
                actChestMax  = max(actChestData);
                
            end
            
        end
        
        if accThighPresent == 1

            % Get data around alarm.
            actThighData = getsampleusingtime(accThigh, startTime, endTime);
            
            if ~isempty(actThighData.Data)
              
                % Features. 
                actThighMean = mean(actThighData);
                actThighMed  = median(actThighData);
                actThighSum  = sum(actThighData);
                actThighMax  = max(actThighData);

            end

        end
        
        if accWristPresent == 1

            % Get data around the alarm.
            actWristData = getsampleusingtime(accWrist, startTime, endTime);
            
            if ~isempty(actWristData.Data)
                
                % Features.
                actWristMean = mean(actWristData);
                actWristMed  = median(actWristData);
                actWristSum  = sum(actWristData);
                actWristMax  = max(actWristData);

            end
            
        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};
        
        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_activity_features.csv'], 'a');
        fprintf(fid, ['%4.0f, %4.0f, %s, %s, %s, %s, %s, ', repmat('%8.4f, ', 1, 11) ,'%8.4f\n'], ...
                 iSubject, alarmCounter(iStamp), alarmLabel, formLabel, ... 
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                 actThighMean, actThighMed, actThighSum, actThighMax, ...
                 actChestMean, actChestMed, actChestSum, actChestMax, ...
                 actWristMean, actWristMed, actWristSum, actWristMax);
        fclose(fid);

        toc
        
    end
    
end
