function analyzeActivity(SUBJECT)
% analyzeActivity analyzes the accelerometer data from the thigh, wrist and
% chest sensors.
%
% Path order is as follows:
% /data1/recordings/btmn/subject/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_acc.bin (chest)
%       /btmn_0000_actigraphy_unisens.xml (chest)
%       /btmn_0000_actigraphy_thigh-left_acc.bin
%       /btmn_0000_actigraphy_thigh-left_unisens.xml
%       /btmn_0000_actigraphy_wrist-left_acc.bin
%       /btmn_0000_actigraphy_wrist-left_unisens.xml

PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_TIMESTAMPS = '/someren/recordings/btmn/import/';
OUTPUT_FOLDER   = '/someren/projects/btmn/analysis/amb/activity/';


% Force input to be string.
SUBJECT = char(SUBJECT);


% Path to symlink folder.
SYMLINK_FOLDER  = [OUTPUT_FOLDER SUBJECT '/'];


% Recursively find path to timestamps file.
files = subdir([PATH_TIMESTAMPS, 'btmn_' SUBJECT '_behavior_mobile_timestamps.csv']);


% Proceed if there is only 1 file.
if size(files, 1) == 1

    TIMESTAMPS = files(1).name;

    % Only proceed if the timestamps file exists as a file.
    if exist(TIMESTAMPS, 'file') ~= 2

        return 

    end
    
else

    error('No or multiple timestamp files for subject %s', SUBJECT)

end


% Load all the timestamps for this subject.
[~, ~, alarmLabels, alarmCounter, formLabels, alarmTimestamps] ...
    = timestampRead(TIMESTAMPS);

    
% Since 'exist' does not work on tscollection objects we define vars to
% specify if a var is present.
accChestPresent = 0;
accThighPresent = 0;
accWristPresent = 0;
 

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


% Create the symlink folder.
system(['mkdir ' SYMLINK_FOLDER]);    


% Check if each file exists and load chest data.
if (exist(CHEST_ACC, 'file') == 2) && (exist(CHEST_XML, 'file') == 2)

    accChestPresent = 1;

    % Create sym-links.
    system(['ln -s ' CHEST_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' CHEST_ACC ' ' SYMLINK_FOLDER 'acc.bin']);

    % Load data.
    chest = movisensRead([SYMLINK_FOLDER, 'acc.bin']);

    % Create SVM time series.
    data = (sqrt(chest.accx.Data.^2 + chest.accy.Data.^2 + ...
        chest.accz.Data.^2));
    accChest = timeseries(data, chest.Time, 'name', 'SVM');

    % Remove sym-links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'acc.bin']);

end


% Check if each file exists and load thigh data.
if (exist(THIGH_ACC, 'file') == 2) && (exist(THIGH_XML, 'file') == 2)

    accThighPresent = 1;

    % Create sym-links.
    system(['ln -s ' THIGH_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' THIGH_ACC ' ' SYMLINK_FOLDER 'acc.bin']);

    % Load data.
    thigh = movisensRead([SYMLINK_FOLDER, 'acc.bin']);

    % Create SVM time series.
    data = (sqrt(thigh.accx.Data.^2 + thigh.accy.Data.^2 + ...
        thigh.accz.Data.^2));
    accThigh = timeseries(data, thigh.Time, 'name', 'SVM');  

    % Remove sym-links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'acc.bin']);

end


% Check if each file exists and load wrist data.
if (exist(WRIST_ACC, 'file') == 2) && (exist(WRIST_XML, 'file') == 2)

    accWristPresent = 1;

    % Create sym-links.
    system(['ln -s ' WRIST_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' WRIST_ACC ' ' SYMLINK_FOLDER 'acc.bin']);

    % Load data.
    wrist = movisensRead([SYMLINK_FOLDER, 'acc.bin']);

    % Create SVM time series.
    data = (sqrt(wrist.accx.Data.^2 + wrist.accy.Data.^2 + ...
        wrist.accz.Data.^2));
    accWrist = timeseries(data, wrist.Time, 'name', 'SVM');

    % Remove sym-links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'acc.bin']);

end 


% If one of the files exists, proceed.
if accChestPresent == 1 || accThighPresent == 1 || accWristPresent == 1

    % Generate labels for header.
    prefix = {'medActChest', 'sumActChest', 'medActThigh', 'sumActThigh', 'medActWrist', 'sumActWrist'};
    suffix = {'rel', '15', '0'};
    labels  = generateLabels(prefix, suffix);
    
    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_activity_features.csv'], 'w');
    fprintf(fid, [repmat('%s,', 1, 5), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ... 
        'alarmTime', labels); 
    fclose(fid);
    
    
    % Loop through all the samples.
    for iStamp = 1:numel(alarmTimestamps)

        % Alarm timeStamp.
        alarmTime = alarmTimestamps(iStamp);

        % Calculate time relative to previous alarm (etime in seconds, rel in minutes).
        if iStamp > 1
            % Previous alarm timestamp.
            prevTime = alarmTimestamps(iStamp-1);
            
            rel = fix(etime(datevec(alarmTime), datevec(prevTime))/60);
        else
            % For first alarm, there is no previous alarm...
            rel = 0;
        end
 
        % Onset and offset of analysis periods.
        onset  = [-1*rel, -15, 0];
        offset = [0, 0, 5];
        
        nSlots = numel(onset);
        
        % Declare vars.
        medActChest = zeros(1,nSlots);
        sumActChest = zeros(1,nSlots);
        medActThigh = zeros(1,nSlots);
        sumActThigh = zeros(1,nSlots);
        medActWrist = zeros(1,nSlots);
        sumActWrist = zeros(1,nSlots);

        for timeSlot = 1:nSlots
  
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');
            
            startTimes{timeSlot} = datestr(startTime, 'dd-mm-yyyy HH:MM');
            endTimes{timeSlot}   = datestr(endTime, 'dd-mm-yyyy HH:MM');
            
            % Not all files were collected so we test for the existence of the file
            % first.
            if accChestPresent == 1

                % Get data around alarm.
                actChestData = getsampleusingtime(accChest, startTime, endTime);

                if ~isempty(actChestData.Data)

                    % Features.
                    [~,~,~,medActChest(timeSlot),~,~,sumActChest(timeSlot),~] = ...
                        getDescriptivesData(actChestData); 
                    
                else % NaN

                    medActChest(timeSlot) = NaN;
                    sumActChest(timeSlot) = NaN;                  
                    
                end

            end

            
            if accThighPresent == 1

                % Get data around alarm.
                actThighData = getsampleusingtime(accThigh, startTime, endTime);

                if ~isempty(actThighData.Data)

                    % Features. 
                    [~,~,~,medActThigh(timeSlot),~,~,sumActThigh(timeSlot),~] = ...
                        getDescriptivesData(actThighData); 

                else % NaN
                    
                    medActThigh(timeSlot) = NaN;
                    sumActThigh(timeSlot) = NaN;
                    
                end

            end

            
            if accWristPresent == 1

                % Get data around the alarm.
                actWristData = getsampleusingtime(accWrist, startTime, endTime);

                if ~isempty(actWristData.Data)

                    % Features.
                    [~,~,~,medActWrist(timeSlot),~,~,sumActWrist(timeSlot),~] = ...
                        getDescriptivesData(actWristData);        
            
                else % NaN
                    
                    medActWrist(timeSlot) = NaN;
                    sumActWrist(timeSlot) = NaN;
                   
                end

            end

        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_activity_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ... 
            repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ... 
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], endTimes{:}), ...
            medActChest, sumActChest, ...
            medActThigh, sumActThigh, ...
            medActWrist, sumActWrist);
        fclose(fid);

    end
    
end

% Remove the symlink folder.
system(['rmdir ' SYMLINK_FOLDER]);

end