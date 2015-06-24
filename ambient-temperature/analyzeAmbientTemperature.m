function analyzeAmbientTemperature(SUBJECT)
% analyzeAmbientTemperature analyzes the temperature data from the iButton 
% sensors at the coat and sweater.
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_coat.txt/.csv
%       /btmn_0000_temperature_sweater.txt/.csv

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/temperature/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/ambient-temperature/';

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
files = subdir([PATH SUBJECT SUB_PATH '*sweater*']);

if size(files, 1) == 1

    INNER = files(1).name;
    temperatureInner = ibuttonTemperatureRead(INNER);
    
end    

% OUTER.
files = subdir([PATH SUBJECT SUB_PATH '*coat*']); 

if size(files, 1) == 1

    OUTER = files(1).name;
    temperatureOuter = ibuttonTemperatureRead(OUTER);

end


% If either file exists, proceed.     
if ~isempty(INNER) || ~isempty(OUTER)

     % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-temperature_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 16), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', 'startTime', 'endTime', ...
        'meanTemperatureInner60', 'meanTemperatureInner45', 'meanTemperatureInner30', 'meanTemperatureInner15', 'meanTemperatureInner0', ...
        'meanTemperatureOuter60', 'meanTemperatureOuter45', 'meanTemperatureOuter30', 'meanTemperatureOuter15', 'meanTemperatureOuter0');              
    fclose(fid);

    for iStamp = 1:numel(alarmTimestamps)

        % Alarm timestamp.
        alarmTime = alarmTimestamps(iStamp);

        % Declare vars.
        meanTemperatureInner = zeros(1,5);
        meanTemperatureOuter = zeros(1,5);  
        
        % Onset and offset of analysis periods.
        onset  = [-60, -45, -30, -15, 0];
        offset = [-45, -30, -15, 0, 5];
        
        
        for timeSlot = 1:5
            
            % Get 20 minute period of data around the phone alarms;
            % Add 5 min; subtract 15 min.
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            % Extract data.
            temperatureInnerData = getsampleusingtime(temperatureInner, startTime, endTime);
 
            % Extract features,
            if ~isempty(temperatureInnerData.Data)
                
                 meanTemperatureInner(timeSlot) = mean(temperatureInnerData);
                
            else % NaN.
                
                meanTemperatureInner(timeSlot) = NaN;
                
            end

            % Extract data.
            temperatureOuterData = getsampleusingtime(temperatureOuter, startTime, endTime);

            % Extract features.
            if ~isempty(temperatureOuterData.Data)
                
                meanTemperatureOuter(timeSlot) = mean(temperatureOuterData);  
                
            else % NaN.
                
                meanTemperatureOuter(timeSlot) = NaN;
                
            end

        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-temperature_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, %s, %s, %s, %s, %s,', repmat('%4.2f, ', 1, 9), '%4.2f\n'], ...
                 SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                 meanTemperatureInner, meanTemperatureOuter);
        fclose(fid);
        
    end
  
end

end