function analyzeMovisensTemperature(SUBJECT, DATE)
% movisensTemperature analyzes the data from the Movisens sensors at the
% wrist, chest and thigh
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_wrist-left_tempskin.bin
%       /btmn_0000_actigraphy_thigh-left_tempskin.bin
%       /btmn_0000_actigraphy_chest_tempskin.bin
disp('Running analyzeMovisensTemperature...');

% Force input to be string.
SUBJECT = char(SUBJECT); 
DATE    = char(DATE);

PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_TIMESTAMPS = '/someren/recordings/btmn/import/';
OUTPUT_FOLDER   = ['/someren/projects/btmn/analysis/amb/movisens-temperature/', DATE, '/'];
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
tempChestPresent = 0;
tempThighPresent = 0;
tempWristPresent = 0;


% Create symlink names.
CHEST_TEMP = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_tempskin.bin'];
CHEST_XML  = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_unisens.xml'];
WRIST_TEMP = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_tempskin.bin'];
WRIST_XML  = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_unisens.xml'];
THIGH_TEMP = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_thigh-left_tempskin.bin'];
THIGH_XML  = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_thigh-left_unisens.xml'];


% Generate symbolic links on the fly in a /tmp folder.
% The folder is subject specific to avoid overlap during batch processing.
% Unisens data can only be loaded with the toolbox if the filenames are
% acc|ecg|press|temp|tempskin.bin and in the same folder as the
% unisens.xml.

% Create folder.
system(['mkdir ' SYMLINK_FOLDER]);


% Check if each file exists and load chest data.
if (exist(CHEST_TEMP, 'file') == 2) && (exist(CHEST_XML, 'file') == 2)
    
    tempChestPresent = 1;
       
    % Create symbolic links.
    status = system(['ln -s ' CHEST_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    status = system(['ln -s ' CHEST_TEMP ' ' SYMLINK_FOLDER 'tempskin.bin']);

    % Load data.
    temperatureChest = movisensRead([SYMLINK_FOLDER, 'tempskin.bin']);

    % Remove symbolic links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'tempskin.bin']);
    
end


% Check if each file exists and load wrist data.
if (exist(WRIST_TEMP, 'file') == 2) && (exist(WRIST_XML, 'file') == 2)
    
    tempWristPresent = 1;
    
    % Create symbolic links.
    system(['ln -s ' WRIST_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' WRIST_TEMP ' ' SYMLINK_FOLDER 'tempskin.bin']);

    % Load data
    temperatureWrist = movisensRead([SYMLINK_FOLDER, 'tempskin.bin']);

    % Remove symbolic links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'tempskin.bin']);

end


% Check if each file exists and load thigh data.
if (exist(THIGH_TEMP, 'file') == 2) && (exist(THIGH_XML, 'file') == 2)
    
    tempThighPresent = 1;
    
    % Create symbolic links.
    system(['ln -s ' THIGH_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    system(['ln -s ' THIGH_TEMP ' ' SYMLINK_FOLDER 'tempskin.bin']);

    % Load data
    temperatureThigh = movisensRead([SYMLINK_FOLDER, 'tempskin.bin']);

    % Remove symbolic links.
    system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    system(['rm ' SYMLINK_FOLDER 'tempskin.bin']);

end


% If any one file exists, proceed.
if tempChestPresent == 1 || tempThighPresent == 1 || tempWristPresent == 1
    
    
    % Generate labels for header.
    prefix = {'startTime', 'endTime'};
    suffix = {'rel', '15', '0'};
    times  = generateLabels(prefix, suffix);

    prefix = {'medTemperatureChest', 'medTemperatureWrist', 'medTemperatureThigh'};
    suffix = {'rel', '15', '0'};
    labels  = generateLabels(prefix, suffix);
    
    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_movisens-temperature_features.csv'], 'w');
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
        medTemperatureWrist = zeros(1,nSlots);
        medTemperatureThigh = zeros(1,nSlots);
        medTemperatureChest = zeros(1,nSlots);

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
            if tempChestPresent == 1
                
                temperatureChestData = getsampleusingtime(temperatureChest, startTime, endTime);
                [~,~,~,medTemperatureChest(timeSlot),~,~,~,~] = ...
                    getDescriptivesData(temperatureChestData);
                
            else
                
                medTemperatureChest(timeSlot) = NaN;
                
            end

            if tempWristPresent == 1
                
                temperatureWristData = getsampleusingtime(temperatureWrist, startTime, endTime);
                [~,~,~,medTemperatureWrist(timeSlot),~,~,~,~] = ...
                    getDescriptivesData(temperatureWristData);
            
            else
                
                medTemperatureWrist(timeSlot) = NaN;
            
            end

            if tempThighPresent == 1
                
                temperatureThighData = getsampleusingtime(temperatureThigh, startTime, endTime);
                [~,~,~,medTemperatureThigh(timeSlot),~,~,~,~] = ...
                    getDescriptivesData(temperatureThighData);
               
            else
                
                medTemperatureThigh(timeSlot) = NaN;
            
            end
            
        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_movisens-temperature_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ...
            repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], endTimes{:}), ... 
            medTemperatureChest, medTemperatureWrist, medTemperatureThigh);
        fclose(fid);

    end
    
end

% Remove the symlink folder.
system(['rmdir ' SYMLINK_FOLDER]);

end
