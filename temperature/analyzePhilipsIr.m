% AnalyzePhilipsIr analyzes the data from the Philips infra-red
% temperature sensor at the finger.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_contact_temp.txt
clear all; close all; clc;

PATH            = '/Volumes/data1/recordings/btmn/subjects/';
SUB_PATH        = '/temperature/raw/';
PATH_TIMESTAMPS = '/Volumes/data1/recordings/btmn/import/150430_behavior_blindert/';
OUTPUT_FOLDER   = '/Volumes/data2/projects/btmn/analysis/amb/finger-temperature/';
MISSING         = [5, 7, 10, 17, 18, 21, 29, 39];
ALL             = 1:44;
SUBJECTS        = setdiff(ALL, MISSING);

% Select subjects.
for iSubject = SUBJECTS
   
    SUBJECT = sprintf('%04.0f', iSubject);    

    % Paths to temperature file.
    IR = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_temperature_ir_temp.txt'];

    if exist(IR, 'file') == 2
        
        % Open file for writing data.
        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ir-temperature_features.csv'], 'w');
        fprintf(fid, [repmat('%s, ', 1, 4), '%s\n'],...
            'subjectId', 'alarmCounter', 'startTime', 'endTime', 'aveIrTemp');              
        fclose(fid);
     
        % Load temperature data from the IR sensor.
        format = '%s%s%s';
        fid    = fopen(IR);
        C      = textscan(fid, format, 'delimiter', ',', 'headerlines', 0); 
        fclose(fid);

        time  = C{1,1};
        alarm = str2double(C{1,2});
        temp  = str2double(C{1,3})./100;

        STAMPS = unique(alarm)';
        
        for iStamp = STAMPS
            
            % Find indices of the this alarm number.
            indices = find(alarm == iStamp);
            
            startTime = datenum(time(indices(1)), 'dd-mm-yy HH:MM:SS.FFF');
            endTime   = datenum(time(indices(end)), 'dd-mm-yy HH:MM:SS.FFF');

            % Remove outliers? e.g. > +-3*SD?
                        
            % Select the data.
            tempFingerData = temp(indices);
            
            % Calculate the mean temperature.     
            meanTempIr = mean(tempFingerData);
                
            % Write results to file.
            fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ir-temperature_features.csv'], 'a');
            fprintf(fid, '%4.0f, %4.0f, %s, %s, %4.2f\n', ...
                iSubject, iStamp, ...
                datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                meanTempIr);
            fclose(fid);

        end
        
    end
    
end