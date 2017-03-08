function analyzeBaroPressure(SUBJECT, DATE)
% analyzeBaroPressure analyzes the data from the Movisens sensors at the
% wrist, chest and thigh
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_wrist-left_press.bin
%       /btmn_0000_actigraphy_thigh-left_press.bin
%       /btmn_0000_actigraphy_chest_press.bin
disp('Running analyzeBaroPressure...');

% Force input to be string.
SUBJECT = char(SUBJECT);
DATE    = char(DATE);

PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_TIMESTAMPS = '/someren/recordings/btmn/import/';
OUTPUT_FOLDER   = ['/someren/projects/btmn/analysis/amb/baro-pressure/', DATE, '/'];
SYMLINK_FOLDER  = [OUTPUT_FOLDER SUBJECT '/'];


% Recursively find path to timestamps file.
files = subdir([PATH_TIMESTAMPS 'btmn_' SUBJECT '_behavior_mobile_timestamps.csv']);


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
pressChestPresent = 0;
pressThighPresent = 0;
pressWristPresent = 0;


% Create symlink names.
CHEST_PRESS = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_press.bin'];
CHEST_XML   = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_unisens.xml'];
WRIST_PRESS = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_press.bin'];
WRIST_XML   = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_unisens.xml'];
THIGH_PRESS = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_thigh-left_press.bin'];
THIGH_XML   = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_thigh-left_unisens.xml'];


% Generate symbolic links on the fly in a /tmp folder.
% The folder is subject specific to avoid overlap during batch processing.
% Unisens data can only be loaded with the toolbox if the filenames are
% acc|ecg|press|temp|tempskin.bin and in the same folder as the
% unisens.xml.

% Create folder.
system(['mkdir ' SYMLINK_FOLDER]);


% Check if each file exists and load chest data.
if (exist(CHEST_PRESS, 'file') == 2) && (exist(CHEST_XML, 'file') == 2)
    
    pressChestPresent = 1;
       
    % Create symbolic links.
    status = system(['ln -s ' CHEST_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    status = system(['ln -s ' CHEST_PRESS ' ' SYMLINK_FOLDER 'press.bin']);

    % Load data.
    pressChest = movisensRead([SYMLINK_FOLDER, 'press.bin']);

    % Remove symbolic links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'press.bin']);
    
end


% Check if each file exists and load wrist data.
if (exist(WRIST_PRESS, 'file') == 2) && (exist(WRIST_XML, 'file') == 2)
    
    pressWristPresent = 1;
    
    % Create symbolic links.
    system(['ln -s ' WRIST_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' WRIST_PRESS ' ' SYMLINK_FOLDER 'press.bin']);

    % Load data
    pressWrist = movisensRead([SYMLINK_FOLDER, 'press.bin']);

    % Remove symbolic links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'press.bin']);

end


% Check if each file exists and load thigh data.
if (exist(THIGH_PRESS, 'file') == 2) && (exist(THIGH_XML, 'file') == 2)
    
    pressThighPresent = 1;
    
    % Create symbolic links.
    system(['ln -s ' THIGH_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' THIGH_PRESS ' ' SYMLINK_FOLDER 'tempskin.bin']);

    % Load data
    pressThigh = movisensRead([SYMLINK_FOLDER, 'tempskin.bin']);

    % Remove symbolic links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'tempskin.bin']);

end


% If any one file exists, proceed.
if pressChestPresent == 1 || pressThighPresent == 1 || pressWristPresent == 1
    
    
    % Generate labels for header.
    prefix = {'startTime', 'endTime'};
    suffix = {'rel', '15', '0'};
    times  = generateLabels(prefix, suffix);

    prefix = {'medBaroPressureChest', 'medBaroPressureWrist', 'medBaroPressureThigh'};
    suffix = {'rel', '15', '0'};
    labels  = generateLabels(prefix, suffix);
    
    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_baro-pressure_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 6), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', times, labels);              
    fclose(fid);

    % Loop through all the alarms.
    for iStamp = 1:numel(alarmTimestamps)
        
        % Alarm timestamp.
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
        medPressWrist = zeros(1,nSlots);
        medPressThigh = zeros(1,nSlots);
        medPressChest = zeros(1,nSlots);

        % Loop though time slots.
        for timeSlot = 1:nSlots

            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            startTimes{timeSlot} = datestr(startTime, 'dd-mm-yyyy HH:MM');
            endTimes{timeSlot}   = datestr(endTime, 'dd-mm-yyyy HH:MM');
            
            % Not all files were collected so we test for the existence of the file
            % first.          
            if pressChestPresent == 1
                
                pressChestData = getsampleusingtime(pressChest, startTime, endTime);
                [~,~,~,medPressChest(timeSlot),~,~,~,~] = getDescriptivesData(pressChestData);
                
            else
                
                medPressChest(timeSlot) = NaN;
                
            end

            if pressWristPresent == 1
                
                pressWristData = getsampleusingtime(pressWrist, startTime, endTime);
                [~,~,~,medPressWrist(timeSlot),~,~,~,~] = getDescriptivesData(pressWristData);        
            
            else
                
                medPressWrist(timeSlot) = NaN;
            
            end

            if pressThighPresent == 1
                
                pressThighData = getsampleusingtime(pressThigh, startTime, endTime);
                [~,~,~,medPressThigh(timeSlot),~,~,~,~] = getDescriptivesData(pressThighData);        
            
            else
                
                medPressThigh(timeSlot) = NaN;
            
            end
            
        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_baro-pressure_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ...
            repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], endTimes{:}), ... 
            medPressChest, medPressWrist, medPressThigh);
        fclose(fid);

    end
    
end

% Remove the symlink folder.
system(['rmdir ' SYMLINK_FOLDER]);

end
