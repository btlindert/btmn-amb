function analyzePhilipsContact(SUBJECT)
% AnalyzePhilipsContact analyzes the data from the Philips contact
% temperature sensor at the finger.
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_contact_temp.txt

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/temperature/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/contact-temperature/';

  
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


% Set vars to empty.
CONTACT = '';


% CONTACT.
files = subdir([PATH SUBJECT SUB_PATH '*contact_temp.*']);

if size(files, 1) == 1

    CONTACT     = files(1).name;
    temperature = philipsContactRead(CONTACT);

end  


% If either file exists, proceed.     
if ~isempty(CONTACT)

    % Open file for writing data.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_contact-temperature_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 11), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', 'startTime', 'endTime', ...
        'meanContactTemp60', 'meanContactTemp45', 'meanContactTemp30', 'meanContactTemp15', 'meanContactTemp0');              
    fclose(fid);


    % Loop through all the alarms.
    for iStamp = 1:numel(alarmTimestamps)

        % Alarm timestamp.
        alarmTime = alarmTimestamps(iStamp);

        % Declare vars.
        meanTempContact = zeros(1,5);
        
        % Onset and offset of analysis periods.
        onset  = [-60, -45, -30, -15, 0];
        offset = [-45, -30, -15, 0, 5];
        
        
        % Loop though time slots.
        for timeSlot = 1:5

            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            % Extract data.
            tempFingerData = getsampleusingtime(temperature, startTime, endTime);

            % Extract features.
            if ~isempty(tempFingerData.Data)

                meanTempContact(timeSlot) = mean(tempFingerData);

            else % NaN.

                meanTempContact(timeSlot) = NaN;

            end   

        end
        
        
        % Write results to file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_contact-temperature_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, %s, %s, %s, %s, %s,', repmat('%4.2f, ', 1, 4), '%4.2f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
            datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
            meanTempContact);
        fclose(fid);

    end

end
    
end