function analyzeAmbientHumidity(SUBJECT)
% analyzeAmbientHumidity analyzes the humidity data from the iButton hydrochron
% sensors at the coat and sweater.
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /humidity/raw
%       /btmn_0000_humidity_coat.txt/.csv
%       /btmn_0000_humidity_sweater.txt/.csv

PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/humidity/raw/';
PATH_TIMESTAMPS = '/someren/recordings/btmn/import/';
OUTPUT_FOLDER   = '/someren/projects/btmn/analysis/amb/ambient-humidity/';


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


% Set vars to empty or remove.
OUTER = '';
INNER = '';        


% INNER.
files = subdir([PATH SUBJECT SUB_PATH '*sweater.*']);

if size(files, 1) == 1

    INNER    = files(1).name;
    humInner = ibuttonHumidityRead(INNER);

end    

% OUTER.
files = subdir([PATH SUBJECT SUB_PATH '*coat.*']); 

if size(files, 1) == 1

    OUTER    = files(1).name;
    humOuter = ibuttonHumidityRead(OUTER);

end


% If either file exists, proceed.     
if ~isempty(INNER) || ~isempty(OUTER)

    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-humidity_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 14), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', ...
        'medHumidityInner60', 'medHumidityInner45', 'medHumidityInner30', 'medHumidityInner15', 'medHumidityInner0', ...
        'medHumidityOuter60', 'medHumidityOuter45', 'medHumidityOuter30', 'medHumidityOuter15', 'medHumidityOuter0');              
    fclose(fid);

    % Loop through all alarms.
    for iStamp = 1:numel(alarmTimestamps)

        % Alarm timestamp.
        alarmTime = alarmTimestamps(iStamp);

        % Declare vars.
        medHumidityInner = zeros(1,5);
        medHumidityOuter = zeros(1,5);  
        
        % Onset and offset of analysis periods.
        onset  = [-60, -45, -30, -15, 0];
        offset = [-45, -30, -15, 0, 5];
        
        
        for timeSlot = 1:5
            
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            % Extract data.
            humidityInnerData = getsampleusingtime(humInner, startTime, endTime);
            
            % Extract features.
            if ~isempty(humidityInnerData.Data)

                medHumidityInner(timeSlot) = nanmedian(humidityInnerData);

            else % NaN.

                medHumidityInner(timeSlot) = NaN;

            end
            
            % Extract data.
            humidityOuterData = getsampleusingtime(humOuter, startTime, endTime);
            
            % Extract features.
            if ~isempty(humidityOuterData.Data)

                medHumidityOuter(timeSlot) = nanmedian(humidityOuterData);  

            else % NaN.

                medHumidityOuter(timeSlot) = NaN;

            end

        end
        
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-humidity_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, %s, %s, %s, ', repmat('%4.2f, ', 1, 9), '%4.2f\n'], ...
                 SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 medHumidityInner, medHumidityOuter);
        fclose(fid);

    end
    
end

end