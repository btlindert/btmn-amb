function analyzeSleep(SUBJECT)
% sleepAnalysis analyzes the wrist actigraphy data to extract sleep
% parameters.
%
% Path order is as follows:
% /data1/recordings/btmn/subject/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_wrist-left_acc.bin
%       /btmn_0000_actigraphy_wrist-left_unisens.xml


% Add path to actant scripts.
addpath(genpath('/someren/projects/btmn/scripts/actant/')); 

% Define folders.
PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_CSD        = '/someren/projects/btmn/analysis/amb/sleep/csd/';
OUTPUT_FOLDER   = '/someren/projects/btmn/analysis/amb/sleep/';


% Force input to be string.
SUBJECT = char(SUBJECT);


% Path to symlink folder.
SYMLINK_FOLDER  = [OUTPUT_FOLDER SUBJECT '/'];


% Specify algorithm properties.
settings{1,1} = 'Algorithm';   settings{1, 2} = 'oakley';
settings{2,1} = 'Method';      settings{2, 2} = 'i';
settings{3,1} = 'Sensitivity'; settings{3, 2} = 'm';
settings{4,1} = 'Snooze';      settings{4, 2} = 'on';
settings{5,1} = 'Time window'; settings{5, 2} = 10; 


% Paths to files.
WRIST_ACC = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_acc.bin'];
WRIST_XML = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_unisens.xml'];
CSD_FILE  = [PATH_CSD 'btmn_' SUBJECT '_csd_actigraphy.csv'];


% Generate temporary symbolic links on the fly in a SIMLINK_FOLDER.
% Links to the *acc.bin and the *unisens.xml need to be created.
% Unisens data can only be loaded with the toolbox if the filenames are
% acc|ecg|press|temp|tempskin.bin and in the same folder as the
% unisens.xml.

% Create the symlink folder.
status = system(['mkdir ' SYMLINK_FOLDER]);  

if (exist(WRIST_ACC, 'file') == 2) && (exist(WRIST_XML, 'file') == 2)

    
    % Create sym-links.
    status = system(['ln -s ' WRIST_XML ' ' SYMLINK_FOLDER 'unisens.xml']);
    status = system(['ln -s ' WRIST_ACC ' ' SYMLINK_FOLDER 'acc.bin']);

    
    % Load data.
    accWrist = movisensRead([SYMLINK_FOLDER, 'acc.bin']);

    
    % Remove sym-links.
    status = system(['rm ' SYMLINK_FOLDER 'unisens.xml']);
    status = system(['rm ' SYMLINK_FOLDER 'acc.bin']);

    
    % Select only the accz data.
    accZ = accWrist.accz;           
    clear accWrist

    
    % Convert to counts.
    counts = movisensCounts(accZ);   %%% THRESHOLD = 18 APPEARS OKAY FOR MOVISENS ACC TOO 290515 

    
    % Load sleep diary data.
    fid = fopen(CSD_FILE, 'r');
    tmp = textscan(fid, '%s%s%s%s%s%s%s%s',...
            'Headerlines', 1,...
            'Delimiter'  , ',');
    fclose(fid);

    
    % Restructure to nDays-by-8.
    for iDay = 1:numel(tmp{1})

        for iColumn = 1:8

            csdData(iDay, iColumn) = tmp{iColumn}(iDay);

        end

    end
    
    
    % Score sleep parameters.
    [~, sleepScores] = actant_oakley(counts, settings, csdData);

    
    % Open file to write data to. 
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT,...
                 '_sleep_features.csv'], 'w');

    
    % Put in the sleep variable headers first.
    fprintf(fid, '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s\n',...
        'subjectId', 'csdInBedTime', 'csdLightsOffTime', 'csdWakeTime', 'csdOutOfBedTime', 'timeInBed', 'sleepOnsetTime', 'sleepOnsetLatency', ...
        'finalWakeTime', 'assumedSleepTime', 'snoozeTime1', 'snoozeTime2', 'wakeAfterSleepOnset', 'actualSleepTime', 'sleepEfficiency1', ...
        'sleepEfficiency2', 'numberOfWakeBouts', 'meanWakeBoutTime', 'numberOfSleepBouts', 'meanSleepBoutTime', 'mobileTime', 'immobileTime');

    
    % Load columns from vals and store as rows in txt, both strings and
    % numbers.
    for iRow = 2:size(sleepScores, 2)

        fprintf(fid, '%s, %s, %s, %s, %s, %g, %s, %4.2f, %s, %4.2f, %4.2f, %4.2f, %4.2f, %g, %4.2f, %4.2f, %g, %4.2f, %g, %4.2f, %4.2f, %4.2f\n',...
                      SUBJECT, sleepScores{:,iRow});

    end

    
    fclose(fid);

    
end
 
% Remove the symlink folder.
status = system(['rmdir ' SYMLINK_FOLDER]);

end
