function analyzeAmbientHumidity(SUBJECT)

% analyzeAmbientHumidity analyzes the humidity data from the iButton hydrochron
% sensors at the coat and sweater.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /humidity/raw
%       /btmn_0000_humidity_coat.txt/.csv
%       /btmn_0000_humidity_sweater.txt/.csv

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/humidity/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/';%150430_behavior_blindert/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/ambient-humidity/';


% Force input to be string
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
    fprintf(fid, [repmat('%s, ', 1, 8), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', 'startTime', 'endTime', ...
        'meanHumidityInner60', 'meanHumidityInner45', 'meanHumidityInner30', 'meanHumidityInner15', 'meanHumidityInner0', ...
        'meanHumidityOuter60', 'meanHumidityOuter45', 'meanHumidityOuter30', 'meanHumidityOuter15', 'meanHumidityOuter0');              
    fclose(fid);


    for iStamp = 1:numel(alarmTimestamps)

        % Alarm timestamp.
        alarmTime = alarmTimestamps(iStamp);

        % Declare vars.
        meanHumidityInner = [];
        meanHumidityOuter = [];  
        
        % Onset and offset of analysis periods.
        onset  = [-60, -45, -30, -15, 0];
        offset = [-45, -30, -15, 0, 5];
        
        
        for timeSlot = 1:5
            
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            if ~isempty(INNER)

                humidityInnerData = getsampleusingtime(humInner, startTime, endTime);
                meanHumidityInner(timeSlot) = mean(humidityInnerData);

            else

                meanHumidityInner(timeSlot) = [];

            end


            if ~isempty(OUTER)

                humidityOuterData = getsampleusingtime(humOuter, startTime, endTime);
                meanHumidityOuter(timeSlot) = mean(humidityOuterData);  

            else

                meanHumidityOuter(timeSlot) = [];

            end

        end
        
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-humidity_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, %s, %s, %s, %s, %s,', repmat('%4.2f, ', 1, 9), '%4.2f\n'], ...
                 SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                 meanHumidityInner, meanHumidityOuter);
        fclose(fid);

    end
    
end

end