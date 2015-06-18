% sleepAnalysis analyzes the wrist actigraphy data to extract sleep
% parameters.

% Path order is as follows:
% /data1/recordings/btmn/subject/0000
%   /actigraphy/raw
%       /btmn_0000_actigraphy_wrist-left_acc.bin
%       /btmn_0000_actigraphy_wrist-left_unisens.xml
clear all; close all; clc;

% Add path to actant scripts.
addpath(genpath('/Users/me/Code/matlab/actant/')); %'/Volumes/data2/projects/btmn/scripts/actant/'));

% Define folders.
PATH            = '/Volumes/data1/recordings/btmn/subjects/';
SUB_PATH        = '/actigraphy/raw/';
PATH_CSD        = '/Volumes/data2/projects/btmn/analysis/amb/sleep/csd/';
OUTPUT_FOLDER   = '/Volumes/data2/projects/btmn/analysis/amb/sleep/';
SIMLINK_FOLDER  = '/Users/me/Downloads/';
MISSING         = [5, 7, 10, 17, 18, 21, 29, 39];
ALL             = 1:44;
SUBJECTS        = setdiff(ALL, MISSING);

% Specify algorithm properties.
settings{1,1} = 'Algorithm';   settings{1, 2} = 'oakley';
settings{2,1} = 'Method';      settings{2, 2} = 'i';
settings{3,1} = 'Sensitivity'; settings{3, 2} = 'm';
settings{4,1} = 'Snooze';      settings{4, 2} = 'on';
settings{5,1} = 'Time window'; settings{5, 2} = 10; 

for iSubject = SUBJECTS
    
    % Subject string.
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Paths to files.
    WRIST_ACC = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_acc.bin'];
    WRIST_XML = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_actigraphy_wrist-left_unisens.xml'];
    CSD_FILE  = [PATH_CSD 'btmn_' SUBJECT '_csd_actigraphy.csv'];
    
    % Generate temporary symbolic links on the fly in a SIMLINK_FOLDER.
    % Links to the *acc.bin and the *unisens.xml need to be created.
    % Unisens data can only be loaded with the toolbox if the filenames are
    % acc|ecg|press|temp|tempskin.bin and in the same folder as the
    % unisens.xml.
    
    if (exist(WRIST_ACC, 'file') == 2) && (exist(WRIST_XML, 'file') == 2)
        
        % Create sym-links.
        status = system(['ln -s ' WRIST_XML ' ' SIMLINK_FOLDER 'unisens.xml']);
        status = system(['ln -s ' WRIST_ACC ' ' SIMLINK_FOLDER 'acc.bin']);
    
        % Load data.
        accWrist = movisensRead([SIMLINK_FOLDER, 'acc.bin']);
        
        % Remove sym-links.
        status = system(['rm ' SIMLINK_FOLDER 'unisens.xml']);
        status = system(['rm ' SIMLINK_FOLDER 'acc.bin']);
       
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
        fid = fopen([OUTPUT_FOLDER 'btmn_' sprintf('%04.0f', iSubject),...
                     '_sleepScores.txt'], 'w');

        % Put in the sleep variable headers first.
        fprintf(fid, '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s\n',...
                      sleepScores{:,1});

        % Load columns from vals and store as rows in txt, both strings and
        % numbers.
        for iRow = 2:size(sleepScores, 2)

            fprintf(fid, '%s, %s, %s, %s, %g, %s, %4.2f, %s, %4.2f, %4.2f, %4.2f, %4.2f, %g, %4.2f, %4.2f, %g, %4.2f, %g, %4.2f, %4.2f, %4.2f\n',...
                          sleepScores{:,iRow});

        end

        fclose(fid);
        
    end
    
end
