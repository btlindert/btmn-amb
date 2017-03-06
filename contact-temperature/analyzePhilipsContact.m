function analyzePhilipsContact(SUBJECT)
% AnalyzePhilipsContact analyzes the data from the Philips contact
% temperature sensor at the finger.
%
% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_contact_temp.txt

PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/temperature/raw/';
PATH_TIMESTAMPS = '/someren/recordings/btmn/import/';
OUTPUT_FOLDER   = '/someren/projects/btmn/analysis/amb/contact-temperature/';

  
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

    % Generate labels for header.
    prefix = {'medContactTemp'};
    suffix = {'rel', '15', '0'};
    labels  = generateLabels(prefix, suffix);
    
    % Open file for writing data.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_contact-temperature_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 5), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ...
        'alarmTime', labels);              
    fclose(fid);


    % Loop through all the alarms.
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
        
        % Declare vars.
        medTempContact = zeros(1,nSlots);
        
        % Loop though time slots.
        for timeSlot = 1:nSlots

            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            startTimes{timeSlot} = datestr(startTime, 'dd-mm-yyyy HH:MM');
            endTimes{timeSlot}   = datestr(endTime, 'dd-mm-yyyy HH:MM');
            
            % Extract data.
            tempFingerData = getsampleusingtime(temperature, startTime, endTime);

            % Extract features.
            if ~isempty(tempFingerData.Data)

            [~,~,~,medTempContact(timeSlot),~,~,~,~] = ...
                    getDescriptivesData(tempFingerData);

            else % NaN.

                medTempContact(timeSlot) = NaN;

            end   

        end
        
        
        % Write results to file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_contact-temperature_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ...
            repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ...
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], endTimes{:}), ... 
            medTempContact);
        fclose(fid);

    end

end
    
end