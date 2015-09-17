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

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/activity/';


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

    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_activity_features.csv'], 'w');
    fprintf(fid, [repmat('%s,', 1, 34), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ... 
        'alarmTime', ...
        'meanActChest60', 'meanActChest45', 'meanActChest30', 'meanActChest15', 'meanActChest0', ...
        'sumActChest60' , 'sumActChest45' , 'sumActChest30' , 'sumActChest15' , 'sumActChest0' , ...
        'meanActThigh60', 'meanActThigh45', 'meanActThigh30', 'meanActThigh15', 'meanActThigh0', ...
        'sumActThigh60' , 'sumActThigh45' , 'sumActThigh30' , 'sumActThigh15' , 'sumActThigh0' , ...
        'meanActWrist60', 'meanActWrist45', 'meanActWrist30', 'meanActWrist15', 'meanActWrist0', ...
        'sumActWrist60' , 'sumActWrist45' , 'sumActWrist30' , 'sumActWrist15' , 'sumActWrist0'); 
    fclose(fid);
    
    
    % Loop through all the samples.
    for iStamp = 1:numel(alarmTimestamps)

        % Alarm timeStamp.
        alarmTime = alarmTimestamps(iStamp);

        % Declare vars.
        meanActChest = zeros(1,5);
        sumActChest  = zeros(1,5);
        meanActThigh = zeros(1,5);
        sumActThigh  = zeros(1,5);
        meanActWrist = zeros(1,5);
        sumActWrist  = zeros(1,5);

        % Onset and offset of analysis periods.
        onset  = [-60, -45, -30, -15, 0];
        offset = [-45, -30, -15, 0, 5];

        for timeSlot = 1:5
  
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');
            
            % Not all files were collected so we test for the existence of the file
            % first.
            if accChestPresent == 1

                % Get data around alarm.
                actChestData = getsampleusingtime(accChest, startTime, endTime);

                if ~isempty(actChestData.Data)

                    % Features.
                    meanActChest(timeSlot) = mean(actChestData);
                    sumActChest(timeSlot)  = sum(actChestData);
                    
                else % NaN

                    meanActChest(timeSlot) = NaN;
                    sumActChest(timeSlot)  = NaN;                  
                    
                end

            end

            
            if accThighPresent == 1

                % Get data around alarm.
                actThighData = getsampleusingtime(accThigh, startTime, endTime);

                if ~isempty(actThighData.Data)

                    % Features. 
                    meanActThigh(timeSlot) = mean(actThighData);
                    sumActThigh(timeSlot)  = sum(actThighData);

                else % NaN
                    
                    meanActThigh(timeSlot) = NaN;
                    sumActThigh(timeSlot)  = NaN;
                    
                end

            end

            
            if accWristPresent == 1

                % Get data around the alarm.
                actWristData = getsampleusingtime(accWrist, startTime, endTime);

                if ~isempty(actWristData.Data)

                    % Features.
                    meanActWrist(timeSlot) = mean(actWristData);
                    sumActWrist(timeSlot)  = sum(actWristData);

                else % NaN
                    
                    meanActWrist(timeSlot) = NaN;
                    sumActWrist(timeSlot)  = NaN;
                   
                end

            end

        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_activity_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, %s, %s, %s, ', repmat('%8.4f, ', 1, 29), '%8.4f\n'], ...
                 SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ... 
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 meanActChest, sumActChest, ...
                 meanActThigh, sumActThigh, ...
                 meanActWrist, sumActWrist);
        fclose(fid);

    end
    
end

% Remove the symlink folder.
system(['rmdir ' SYMLINK_FOLDER]);

end