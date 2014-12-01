% AnalyzePhilipsContact analyzes the data from the Philips contact
% temperature sensor at the finger.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_contact.txt
PATH     = '/data1/recordings/btmn/subjects/';
SUB_PATH = '/temperature/raw/';

OUTPUT_FOLDER = '/..../';

fid = fopen([OUTPUT_FOLDER 'finger-temperature.csv'], 'a');
fprintf(fid, '%s,%s,%n',...
    'subjectId', 'alarmId', 'aveContactTemp');       


% Select subjects.
for iSubject = [1,2,3]
   
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Load all the timestamps for this subject.
    timestamps = movisensTimestampsRead(filename);
    
    % Paths to temperature file.
    CONTACT = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT,...
        '_temperature_contact.txt'];

    % Load temperature data from the contact sensor.
    contact = philipsContactRead(CONTACT);

    for iStamp = 1:numel(timestamps)
    
        % Alarm timestamp.
        alarmTime = timestamps(iStamp);
        
        % Get 20 minute period of data around the phone alarms;
        % Add 5 min; subtract 15 min.
        startTime = addToDate(alarmTime, -15, 'minute');
        endTime   = addToDate(alarmTime, 5, 'minute');
        
        tempFingerData = getSamplesUsingTime(contact, startTime, endTime);
       
        % Mean temperature.     
        aveTempContact = mean(tempFingerData);

        fprintf(fid, '%f,%f,%f\n',...
                 iSubject, iStamp, aveTempContact);
             
    end
    
end

fclose(fid);