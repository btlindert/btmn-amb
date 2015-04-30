% ambientHumidity analyzes the data from the iButton sensors at the
% coat and sweater.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_coat.txt
%       /btmn_0000_temperature_sweater.txt
PATH     = '/data1/recordings/btmn/subjects/';
SUB_PATH = '/temperature/raw/';

OUTPUT_FOLDER = '/..../';

fid = fopen([OUTPUT_FOLDER 'ambient-humidity.csv'], 'a');
fprintf(fid, '%s,%s,%s,%s\n',...
    'subjectId', 'alarmId', 'aveHumOuter', 'aveHumInner');       


% Select subjects.
for iSubject = [1,2,3]
   
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Load all the timestamps for this subject. Use the Philips temperature
    % time stamps, beacuse these already contain the correct date and start
    % at the correct time (i.e. 15 min prior to alarm).    
    timestamps = stampRead(filename);
    
    % Paths to iButton files.
    SWEATER = [PATH SUBJECT SUB_PATH 'bmtn_' SUBJECT,...
        '_humidity_sweater.txt'];
    COAT    = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT,...
        '_humidity_coat.txt'];

    % Load iButton data from coat and sweater, sampling is 1
    % minute???????????????
    [~ , humOuter] = ibuttonRead(SWEATER);
    [~ , humInner] = ibuttonRead(COAT);

    for iStamp = 1:numel(timestamps)
    
        % Alarm timestamp.
        alarmTime = timestamps(iStamp);
        
        % Get 20 minute period of data around the phone alarms;
        % Add 5 min; subtract 15 min.
        startTime = alarmTime;
        endTime   = addToDate(alarmTime, 20, 'minute');
        
        humSweaterData  = getSamplesUsingTime(humOuter, startTime, endTime);
        humCoatData     = getSamplesUsingTime(humInner, startTime, endTime);
       
        % Mean humidity.
        aveHumSweater = mean(humSweaterData);
        aveHumCoat    = mean(humCoatData);        
        
        fprintf(fid, '%f,%f,%f,%f\n', ...
            iSubject, iStamp, aveHumSweater, aveHumCoat);
             
    end
    
end

fclose(fid);