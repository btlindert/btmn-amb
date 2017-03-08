function analyzeAmbientHumidity(SUBJECT, DATE)
% analyzeAmbientHumidity analyzes the humidity data from the iButton hydrochron
% sensors at the coat and sweater.
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /humidity/raw
%       /btmn_0000_humidity_coat.txt/.csv
%       /btmn_0000_humidity_sweater.txt/.csv
disp('Running analyzeAmbientHumidity...');

% Force input to be string.
SUBJECT = char(SUBJECT);
DATE    = char(DATE);

PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/humidity/raw/';
PATH_TIMESTAMPS = '/someren/recordings/btmn/import/';
OUTPUT_FOLDER   = ['/someren/projects/btmn/analysis/amb/ambient-humidity/', DATE, '/'];


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

    % Generate labels for header.
    prefix = {'startTime', 'endTime'};
    suffix = {'rel', '15', '0'};
    times  = generateLabels(prefix, suffix);

    prefix = {'medHumidityInner', 'medHumidityOuter'};
    suffix = {'rel', '15', '0'};
    labels  = generateLabels(prefix, suffix);
    
    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-humidity_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 6), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', times, labels);              
    fclose(fid);

    % Loop through all alarms.
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
        medHumidityInner = zeros(1,nSlots);
        medHumidityOuter = zeros(1,nSlots);  
        
        for timeSlot = 1:nSlots
            
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            startTimes{timeSlot} = datestr(startTime, 'dd-mm-yyyy HH:MM');
            endTimes{timeSlot}   = datestr(endTime, 'dd-mm-yyyy HH:MM');
            
            % Extract data.
            humidityInnerData = getsampleusingtime(humInner, startTime, endTime);
            
            % Extract features.
            if ~isempty(humidityInnerData.Data)

                [~,~,~,medHumidityInner(timeSlot),~,~,~,~] = ...
                    getDescriptivesData(humidityInnerData);

            else % NaN.

                medHumidityInner(timeSlot) = NaN;

            end
            
            % Extract data.
            humidityOuterData = getsampleusingtime(humOuter, startTime, endTime);
            
            % Extract features.
            if ~isempty(humidityOuterData.Data)

                [~,~,~,medHumidityOuter(timeSlot),~,~,~,~] = ...
                    getDescriptivesData(humidityOuterData);  

            else % NaN.

                medHumidityOuter(timeSlot) = NaN;

            end

        end
        
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-humidity_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ... 
            repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], endTimes{:}), ... 
            medHumidityInner, medHumidityOuter);
        fclose(fid);

    end
    
end

end