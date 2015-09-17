function analyzePosture(SUBJECT)
% analyzePosture analyzes the accelerometer data from the thigh and
% chest sensors to extract posture.
%
% Path order is as follows:
% /data1/recordings/btmn/subject/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_acc.bin (chest)
%       /btmn_0000_actigraphy_unisens.xml (chest)
%       /btmn_0000_actigraphy_thigh-left_acc.bin
%       /btmn_0000_actigraphy_thigh-left_unisens.xml

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/150430_behavior_blindert/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/posture/';


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


% Create the symlink folder.
status = system(['mkdir ' SYMLINK_FOLDER]);   


% Check if each file exists and load.
if (exist(CHEST_ACC, 'file') == 2) && (exist(CHEST_XML, 'file') == 2)

    % Create sym-links.
    status = system(['ln -s ' CHEST_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    status = system(['ln -s ' CHEST_ACC ' ' SYMLINK_FOLDER 'acc.bin']);

    % Load data.
    accChest = movisensRead([SYMLINK_FOLDER, 'acc.bin']);
    accChestPresent = 1;

    % Remove sym-links.
    status = system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    status = system(['rm ' SYMLINK_FOLDER 'acc.bin']);

end


% Check if each file exists and load thigh data.
if (exist(THIGH_ACC, 'file') == 2) && (exist(THIGH_XML, 'file') == 2)

    % Create sym-links.
    status = system(['ln -s ' THIGH_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    status = system(['ln -s ' THIGH_ACC ' ' SYMLINK_FOLDER 'acc.bin']);

    % Load data.
    accThigh = movisensRead([SYMLINK_FOLDER, 'acc.bin']);
    accThighPresent = 1;  

    % Remove sym-links.
    status = system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    status = system(['rm ' SYMLINK_FOLDER 'acc.bin']);
    
end

% Generate labels for header.
suffix = {'60', '45', '30', '15', '0'};
prefix = {'posture', 'standing', 'sitting', 'supine', 'right', 'prone', ...
          'left', 'dynamic'};   
labels = generateLabels(prefix, suffix);

% Only proceed if both chest and thigh data exist.
if accChestPresent == 1 && accThighPresent == 1

    % Write headers to the output file.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_posture_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 5), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ... 
        'alarmTime', labels);       
    fclose(fid);

    % Loop through all the samples.
    for iStamp = 1:numel(alarmTimestamps)

   
        % Alarm time stamp.
        alarmTime = alarmTimestamps(iStamp);
        
        
        % Declare vars.
        classification = zeros(1,5);
        standing       = zeros(1,5);
        sitting        = zeros(1,5);
        supine         = zeros(1,5);
        right          = zeros(1,5);
        prone          = zeros(1,5);
        left           = zeros(1,5);
        dynamic        = zeros(1,5);
        
        
        % Onset and offset of analysis periods.
        onset  = [-60, -45, -30, -15, 0];
        offset = [-45, -30, -15, 0, 5];

        
        for timeSlot = 1:5
            
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');
            
            % Data.
            accChestData = getsampleusingtime(accChest, startTime, endTime);
            accThighData = getsampleusingtime(accThigh, startTime, endTime);

            if ~isempty(accChestData) && ~isempty(accThighData)

                [classification(timeSlot), standing(timeSlot), sitting(timeSlot), ...
                    supine(timeSlot), right(timeSlot), prone(timeSlot), ...
                    left(timeSlot), dynamic(timeSlot)] = posture(accChestData, accThighData, 'off');

            else

                classification(timeSlot) = NaN;
                standing(timeSlot)       = NaN;
                sitting(timeSlot)        = NaN;
                supine(timeSlot)         = NaN;
                right(timeSlot)          = NaN;
                prone(timeSlot)          = NaN;
                left(timeSlot)           = NaN;
                dynamic(timeSlot)        = NaN;

            end

        end
        
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};
        
        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_posture_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, %s, %s, %s, ', repmat('%g, ', 1, numel(prefix)*numel(suffix)-1), '%g\n'], ...
                 SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ... 
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 classification, standing, sitting, supine, right, prone, ...
                 left, dynamic);
        fclose(fid);
    
    end

end
   
% Remove the symlink folder.
status = system(['rmdir ' SYMLINK_FOLDER]);

end