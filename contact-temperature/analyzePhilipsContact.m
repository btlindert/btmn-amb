% AnalyzePhilipsContact analyzes the data from the Philips contact
% temperature sensor at the finger.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_contact_temp.txt

PATH            = '/Volumes/data1/recordings/btmn/subjects/';
SUB_PATH        = '/temperature/raw/';
PATH_TIMESTAMPS = '/Volumes/data1/recordings/btmn/import/150430_behavior_blindert/';
OUTPUT_FOLDER   = '/Volumes/data2/projects/btmn/analysis/amb/finger-temperature/';
MISSING         = [5, 7, 10, 17, 18, 21, 29, 39];
ALL             = 1:44;
SUBJECTS        = setdiff(ALL, MISSING);

% Select subjects.
for iSubject = SUBJECTS(1:end)
   
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Path to timestamps.
    TIMESTAMPS = [PATH_TIMESTAMPS 'btmn_' SUBJECT '_behavior_mobile_timestamps.csv'];

    % Load all the timestamps for this subject.
    [id, subjectId, alarmLabels, alarmCounter, formLabels, alarmTimestamps] ...
        = timestampRead(TIMESTAMPS);
    
    % Paths to temperature file.
    CONTACT = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT,...
        '_temperature_contact_temp.txt'];

    if exist(CONTACT, 'file') == 2
        
        % Open file for writing data.
        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_finger-temperature_features.csv'], 'w');
        fprintf(fid, [repmat('%s, ', 1, 7), '%s\n'],...
            'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
            'alarmTime', 'startTime', 'endTime', ...
            'aveContactTemp');              
        fclose(fid);

        
        % Load temperature data from the contact sensor.
        temperature = philipsContactRead(CONTACT);

        for iStamp = 1:numel(alarmTimestamps)

            % Alarm timestamp.
            alarmTime = alarmTimestamps(iStamp);

            % Get 20 minute period of data around the phone alarms;
            % Add 5 min; subtract 15 min.
            startTime = addtodate(alarmTime, -15, 'minute');
            endTime   = addtodate(alarmTime, 5, 'minute');

            % Extract data around the alarm.
            tempFingerData = getsampleusingtime(temperature, startTime, endTime);


            % Remove outliers? e.g. > +-3*SD?


            if ~isempty(tempFingerData.Data)

                % Calculate the mean temperature.     
                meanTempContact = mean(tempFingerData);

            else

                meanTempContact = [];

            end

            % Write results to file.
            alarmLabel = alarmLabels{iStamp};
            formLabel  = formLabels{iStamp};

            fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_finger-temperature_features.csv'], 'a');
            fprintf(fid, '%4.0f, %4.0f, %s, %s, %s, %s, %s, %4.2f\n', ...
                iSubject, alarmCounter(iStamp), alarmLabel, formLabel, ...
                datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                meanTempContact);
            fclose(fid);

        end
        
    end
    
end