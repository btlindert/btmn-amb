% analyzeAmbientTemperature analyzes the temperature data from the iButton 
% sensors at the coat and sweater.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_coat.txt/.csv
%       /btmn_0000_temperature_sweater.txt/.csv

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/temperature/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/150430_behavior_blindert/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/ambient-temperature/';
MISSING         = [5, 7, 10, 17, 18, 21, 29, 39];
ALL             = 1:44;
SUBJECTS        = setdiff(ALL, MISSING);

for iSubject = SUBJECTS
    
    % Subject string.
    SUBJECT = sprintf('%04.0f', iSubject);

    % Path to timestamps.
    TIMESTAMPS = [PATH_TIMESTAMPS 'btmn_' SUBJECT '_behavior_mobile_timestamps.csv'];

    % Load all the timestamps for this subject.
    [id, subjectId, alarmLabels, alarmCounter, formLabels, alarmTimestamps] ...
        = timestampRead(TIMESTAMPS);

    % Set vars to empty or remove.
    OUTER = '';
    INNER = '';        
    clear('humInner');
    clear('humOuter');
    
    % Find the files (either .csv or .txt files).
    fp = dir([PATH SUBJECT SUB_PATH]);
    
    % INNER
    f = regexpi({fp.name}, ['.*' SUBJECT '.*sweater.*'], 'match');
    f = [f{:}]; 
    if ~isempty(f)
        INNER = [PATH f{1}];
    end
    
    % OUTER
    f = regexpi({fp.name}, ['.*' SUBJECT '.*coat.*'], 'match');
    f = [f{:}];
    if ~isempty(f)
        OUTER = [PATH f{1}];
    end
    
    % Load iButton data from coat and sweater.
    if ~isempty(INNER)
        temperatureInner = ibuttonTemperatureRead(INNER);
    end
    
    if ~isempty(OUTER)
        temperatureOuter = ibuttonTemperatureRead(OUTER);
    end
    
     % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-temperature_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 8), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', 'startTime', 'endTime', ...
        'meanTemperatureInner', 'meanTemperatureOuter');              
    fclose(fid);
    
    for iStamp = 1:numel(alarmTimestamps)
    
        % Alarm timestamp.
        alarmTime = alarmTimestamps(iStamp);
        
        % Get 20 minute period of data around the phone alarms;
        % Add 5 min; subtract 15 min.
        startTime = addtodate(alarmTime, -15, 'minute');
        endTime   = addtodate(alarmTime, 5, 'minute');
        
        if ~isempty(INNER)
            temperatureInnerData = getsampleusingtime(temperatureInner, startTime, endTime);
            meanTemperatureInner = mean(temperatureInnerData);
        else
            meanTemperatureInner = [];
        end
        
        if ~isempty(OUTER)
            temperatureOuterData = getsampleusingtime(temperatureOuter, startTime, endTime);
            meanTemperatureOuter = mean(temperatureOuterData);        
        else
            meanTemperatureOuter = [];
        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel = formLabels{iStamp};
        
        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-temperature_features.csv'], 'a');
        fprintf(fid, '%4.0f, %4.0f, %s, %s, %s, %s, %s, %4.2f, %4.2f\n', ...
                 iSubject, alarmCounter(iStamp), alarmLabel, formLabel, ...
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                 meanTemperatureInner, meanTemperatureOuter);
        fclose(fid);
             
    end
    
end