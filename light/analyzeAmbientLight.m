% AnalyzeAmbientLight analyzes the data from the dimesimeter sensors at the
% coat and sweater.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /ambient-light/raw
%       /btmn_0000_ambient-light_coat.txt
%       /btmn_0000_ambient-light_sweater.txt
% PATH     = '/data1/recordings/btmn/subjects/';
% SUB_PATH = '/ambient-light/raw/';

% OUTPUT_FOLDER = '/data1/projects/btmn/analysis/ambient-light/';

fid = fopen([OUTPUT_FOLDER 'ambient-light.csv'], 'a');
fprintf(fid, '%s,%s,%s,%s,%s\n',...
    'subjectId', 'alarmId', 'aveLuxSweater', 'aveActSweater',...
    'aveLuxCoat', 'aveActCoat');       



% Select subjects.
for iSubject = [1,2,3]
   
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Load all the timestamps for this subject.
    timestamps = movisensTimestampsRead(filename);
    
    % Paths to dimesimeter files.
    SWEATER = [PATH SUBJECT SUB_PATH 'bmtn_' SUBJECT,...
        '_ambient-light_sweater.txt'];
    COAT    = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT,...
        '_ambient-light_coat.txt'];

    % Load dimesimeter data from coat and sweater, sampling is 1
    % minute???????????????
    % %%%%%%%%%%%
    [luxSweater, actSweater] = dimesimeterRead(SWEATER);
    [luxCoat, actCoat]       = dimesimeterRead(COAT);

    for iStamp = 1:numel(timestamps)
    
        % Alarm timestamp.
        alarmTime = timestamps(iStamp);
        
        % Get 20 minute period of data around the phone alarms;
        % Add 5 min; subtract 15 min.
        startTime = addToDate(alarmTime, -15, 'minute');
        endTime   = addToDate(alarmTime, 5, 'minute');
        
        luxSweaterData  = getSamplesUsingTime(luxSweater, startTime, endTime);
        actSweaterData  = getSamplesUsingTime(actSweater, startTime, endTime);
        luxCoatData     = getSamplesUsingTime(luxCoat, startTime, endTime);
        actCoatData     = getSamplesUsingTime(actCoat, startTime, endTime);
       
        % Mean lux.     
        aveLuxSweater = mean(luxSweaterData);
        aveLuxCoat    = mean(luxCoatData);
        
        % Mean activity.
        aveActSweater = mean(actSweaterData);
        aveActCoat    = mean(actCoatData);        
        
        
        % RBG spectrum????????????????

        fprintf(fid, '%f,%f,%f,%f,%f,%f\n',...
                 iSubject, iStamp, aveLuxSweater, aveActSweater,...
                 aveLuxCoat, aveActCoat);
             
    end
    
end

fclose(fid);