function analyzeAmbientTemperature(SUBJECT)
% analyzeAmbientTemperature analyzes the temperature data from the iButton 
% sensors at the coat and sweater.
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_coat.txt/.csv
%       /btmn_0000_temperature_sweater.txt/.csv

PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/temperature/raw/';
PATH_TIMESTAMPS = '/someren/recordings/btmn/import/';
OUTPUT_FOLDER   = '/someren/projects/btmn/analysis/amb/ambient-temperature/';

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

    % Generate labels for header.
    prefix = {'startTime', 'endTime'};
    suffix = {'rel', '15', '0'};
    times  = generateLabels(prefix, suffix);

    prefix = {'medTemperatureInner', 'medTemperatureOuter'};
    suffix = {'rel', '15', '0'};
    labels  = generateLabels(prefix, suffix);
    
    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-temperature_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 6), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', times, labels);              
    fclose(fid);

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
        medTemperatureInner = zeros(1,nSlots);
        medTemperatureOuter = zeros(1,nSlots);  
          
        for timeSlot = 1:nSlots
            
            % Get 20 minute period of data around the phone alarms;
            % Add 5 min; subtract 15 min.
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            startTimes{timeSlot} = datestr(startTime, 'dd-mm-yyyy HH:MM');
            endTimes{timeSlot}   = datestr(endTime, 'dd-mm-yyyy HH:MM');
            
            % Extract data.
            temperatureInnerData = getsampleusingtime(temperatureInner, startTime, endTime);
 
            % Extract features,
            if ~isempty(temperatureInnerData.Data)
                
                [~,~,~,medTemperatureInner(timeSlot),~,~,~,~] = ...
                    getDescriptivesData(temperatureInnerData); 
                
            else % NaN.
                
                medTemperatureInner(timeSlot) = NaN;
                
            end

            % Extract data.
            temperatureOuterData = getsampleusingtime(temperatureOuter, startTime, endTime);

            % Extract features.
            if ~isempty(temperatureOuterData.Data)
                
                [~,~,~,medTemperatureOuter(timeSlot),~,~,~,~] = ...
                    getDescriptivesData(temperatureOuterData); 
                
            else % NaN.
                
                medTemperatureOuter(timeSlot) = NaN;
                
            end

        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-temperature_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ...
            repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], endTimes{:}), ... 
            medTemperatureInner, medTemperatureOuter);
        fclose(fid);
        
    end
  
end

end