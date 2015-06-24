function movisensTemperature(SUBJECT)
% movisensTemperature analyzes the data from the Movisens sensors at the
% wrist, chest and thigh
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_wrist-left_tempskin.bin
%       /btmn_0000_actigraphy_thigh-left_tempskin.bin
%       /btmn_0000_actigraphy_chest_tempskin.bin

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_TIMESTAMPS = '/data1/projects/btmn/import/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/movisens-temperature/';
SIMLINK_FOLDER  = [OUTPUT_FOLDER SUBJECT];


% Force input to be string.
SUBJECT = char(SUBJECT);


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

% Generate symbolic links on the fly in a /tmp folder.
% The folder is subject specific to avoid overlap during batch processing.
% Unisens data can only be loaded with the toolbox if the filenames are
% acc|ecg|press|temp|tempskin.bin and in the same folder as the
% unisens.xml.

% Create folder.
system(['mkdir ' SYMLINK_FOLDER]);

% Create symlink names.
CHEST_TEMP = ['btmn_' SUBJECT '_actigraphy_chest_tempskin.bin'];
CHEST_XML  = ['btmn_' SUBJECT '_actigraphy_chest_unisens.xml'];
WRIST_TEMP = ['btmn_' SUBJECT '_actigraphy_wrist-left_tempskin.bin'];
WRIST_XML  = ['btmn_' SUBJECT '_actigraphy_wrist-left_unisens.xml'];
THIGH_TEMP = ['btmn_' SUBJECT '_actigraphy_thigh-left_tempskin.bin'];
THIGH_XML  = ['btmn_' SUBJECT '_actigraphy_thigh-left_unisens.xml'];

%% CHEST DATA.

% Create symbolic links.
system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
system(['rm ' SIMLINK_FOLDER 'tempskin.bin']);
system(['ln -s ' PATH SUBJECT SUB_PATH CHEST_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
system(['ln -s ' PATH SUBJECT SUB_PATH CHEST_TEMP ' ' SIMLINK_FOLDER 'tempskin.bin']);

% Load data.
temperatureChest = movisensRead(SIMLINK_FOLDER, 'tempskin.bin');


%% WRIST DATA.

% Create symbolic links.
system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
system(['rm ' SIMLINK_FOLDER 'tempskin.bin']);
system(['ln -s ' PATH SUBJECT SUB_PATH WRIST_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
system(['ln -s ' PATH SUBJECT SUB_PATH WRIST_TEMP ' ' SIMLINK_FOLDER 'tempskin.bin']);


% Load data
temperatureWrist = movisensRead(SIMLINK_FOLDER, 'tempskin.bin');


%% THIGH DATA.

% Create symbolic links.
system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
system(['rm ' SIMLINK_FOLDER 'tempskin.bin']);
system(['ln -s ' PATH SUBJECT SUB_PATH THIGH_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
system(['ln -s ' PATH SUBJECT SUB_PATH THIGH_TEMP ' ' SIMLINK_FOLDER 'tempskin.bin']);


% Load data
temperatureThigh = movisensRead(SIMLINK_FOLDER, 'tempskin.bin');

%% ANALYZE DATA
% % If any one file exists, proceed.
% if exist('temperatureChest', 'var') || exist('temperatureWrist', 'var') || exist('temperatureThigh', 'var')
%     
%     % Open file and write headers.
%     fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_skin-temperature_features.csv'], 'w');
%     fprintf(fid, [repmat('%s, ', 1, 9), '%s\n'],...
%         'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
%         'alarmTime', 'startTime', 'endTime', ...
%         'meanTemperatureChest', 'meanTemperatureWrist', 'meanTemperatureThigh');              
%     fclose(fid);
% 
%     % Loop through all the alarms.
%     for iStamp = 1:numel(alarmTimestamps)
%         
%         % Alarm timestamp.
%         alarmTime = alarmTimestamps(iStamp);
% 
%         % Declare vars.
%         meanTemperatureWrist = zeros(1,5);
%         meanTemperatureThigh = zeros(1,5);
%         meanTemperatureChest = zeros(1,5);
%         
%         % Onset and offset of analysis periods.
%         onset  = [-60, -45, -30, -15, 0];
%         offset = [-45, -30, -15, 0, 5];
%         
% 
%         % Loop though time slots.
%         for timeSlot = 1:5
% 
%             % Get 15 minute periods of data prior to the phone alarms
%             % plus 5 minutes during the task
%             startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
%             endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');
%             
%             if exist('temperatureChest', 'var')
%                 temperatureChestData = getsampleusingtime(temperatureChest, startTime, endTime);
%                 meanTemperatureChest = mean(temperatureChestData);
%             else
%                 meanTemperatureChest = [];
%             end
% 
%             if exist('temperatureWrist', 'var')
%                 temperatureThighData = getsampleusingtime(temperatureWrist, startTime, endTime);
%                 meanTemperatureWrist = mean(temperatureThighData);        
%             else
%                 meanTemperatureWrist = [];
%             end
% 
%             if exist('temperatureThigh', 'var')
%                 temperatureThighData = getsampleusingtime(temperatureThigh, startTime, endTime);
%                 meanTemperatureThigh = mean(temperatureThighData);        
%             else
%                 meanTemperatureThigh = [];
%             end
%             
%         end
%         
%         % Write data to txt file.
%         alarmLabel = alarmLabels{iStamp};
%         formLabel = formLabels{iStamp};
% 
%         fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_skin-temperature_features.csv'], 'a');
%         fprintf(fid, '%4.0f, %4.0f, %s, %s, %s, %s, %s, %4.2f, %4.2f, %4.2f\n', ...
%                  iSubject, alarmCounter(iStamp), alarmLabel, formLabel, ...
%                  datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
%                  datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
%                  datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
%                  meanTemperatureChest, meanTemperatureWrist, meanTemperatureThigh);
%         fclose(fid);
% 
%     end
%     
% end

end
