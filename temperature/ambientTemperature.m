% ambientTemperature analyzes the data from the iButton sensors at the
% coat and sweater.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /temperature/raw
%       /btmn_0000_temperature_coat.txt
%       /btmn_0000_temperature_sweater.txt
PATH     = '/data1/recordings/btmn/subjects/';
SUB_PATH = '/temperature/raw/';

OUTPUT_FOLDER = '/..../';

fid = fopen([OUTPUT_FOLDER 'ambient-temperature.csv'], 'a');
fprintf(fid, '%s,%s,%s,%s\n',...
    'subjectId', 'alarmId', 'aveTempOuter', 'aveTempInner');       


% Select subjects.
for iSubject = [1,2,3]
   
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Load all the timestamps for this subject. Use the Philips temperature
    % time stamps, beacuse these already contain the correct date and start
    % at the correct time (i.e. 15 min prior to alarm).    
    timestamps = stampRead(filename);
    
    % Paths to iButton files.
    SWEATER = [PATH SUBJECT SUB_PATH 'bmtn_' SUBJECT,...
        '_temperature_sweater.txt'];
    COAT    = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT,...
        '_temperature_coat.txt'];

    % Load iButton data from coat and sweater, sampling is 1
    % minute???????????????
    [tempOuter, ~] = ibuttonRead(SWEATER);
    [tempInner, ~] = ibuttonRead(COAT);

    for iStamp = 1:numel(timestamps)
    
        % Alarm timestamp.
        alarmTime = timestamps(iStamp);
        
        % Get 20 minute period of data around the phone alarms;
        % Add 5 min; subtract 15 min.
        startTime = alarmTime;
        endTime   = addToDate(alarmTime, 20, 'minute');
        
        tempOuterData = getSamplesUsingTime(tempOuter, startTime, endTime);
        tempInnerData    = getSamplesUsingTime(tempInner, startTime, endTime);
       
        % Mean temperature.     
        aveTempOuter = mean(tempOuterData);
        aveTempInner    = mean(tempInnerData);
        
        fprintf(fid, '%f,%f,%f,%f\n', ...
            iSubject, iStamp, aveTempOuter, aveTempInner);
             
    end
    
end

fclose(fid);