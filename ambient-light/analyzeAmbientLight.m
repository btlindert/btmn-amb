% analyzeAmbientLight analyzes the light data from the dimesimeter sensors 
% at the coat and sweater.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /ambient-light/raw
%       /btmn_0000_ambient-light_coat_processed.txt
%       /btmn_0000_ambient-light_sweater_processed.txt

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/ambient-light/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/150430_behavior_blindert/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/ambient-light/';
MISSING         = [5, 7, 10, 17, 18, 21, 29, 39];
ALL             = 1:44;
SUBJECTS        = setdiff(ALL, MISSING);

for iSubject = SUBJECTS
   
    % Subject string.
    SUBJECT = sprintf('%04.0f', iSubject);    
    
    % Paths to dimesimeter files.
    INNER = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_ambient-light_sweater_processed.txt'];
    OUTER = [PATH SUBJECT SUB_PATH 'btmn_' SUBJECT '_ambient-light_coat_processed.txt'];
    
    % Path to timeStamps.
    TIMESTAMPS = [PATH_TIMESTAMPS 'btmn_' SUBJECT '_behavior_mobile_timestamps.csv'];

    % Load all the timestamps for this subject.
    [id, subjectId, alarmLabels, alarmCounter, formLabels, alarmTimestamps] ...
        = timestampRead(TIMESTAMPS);
    
    % check if both fileS exiSt and load once.
    if exist(INNER, 'file') == 2
        % Load dimeSimeter data from Sweater, Sampling iS 1 minute.
        [luxInner, claInner, csInner, actInner, xInner, yInner] = dimesimeterRead(INNER);
    end
    
    if exist(OUTER, 'file') == 2
        % Load dimeSimeter data from Sweater, Sampling iS 1 minute.
        [luxOuter, claOuter, csOuter, actOuter, xOuter, yOuter] = dimesimeterRead(OUTER); 
    end
    
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-light_features.csv'], 'w');
    fprintf(fid, [repmat('%s,', 1, 18), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ... 
        'alarmTime', 'startTime', 'endTime', ...
        'luxInner', 'claInner', 'csInner', 'actInner', 'xInner', 'yInner', ...
        'luxOuter', 'claOuter', 'csOuter', 'actOuter', 'xOuter', 'yOuter');       
    fclose(fid);

    % Loop through all the samples.
    for iStamp = 1:numel(alarmTimestamps)

        % Alarm timeStamp.
        alarmTime = alarmTimestamps(iStamp);

        % Get 20 minute period of data around the phone alarms.
        startTime = addtodate(alarmTime, -15, 'minute');
        endTime   = addtodate(alarmTime, 5, 'minute');

        % Not all files were collected so we test for the existence of the file
        % first.
        if exist(INNER, 'file') == 2

            % Average lux.
            luxInnerData = getsampleusingtime(luxInner, startTime, endTime);
            luxInnerMean = mean(luxInnerData);
       
            % Average circadian lux.
            claInnerData = getsampleusingtime(claInner, startTime, endTime);
            claInnerMean = mean(claInnerData);

            % Average circadian StimuluS.
            csInnerData = getsampleusingtime(csInner, startTime, endTime);
            csInnerMean = mean(csInnerData);

            % Average activity.
            actInnerData = getsampleusingtime(actInner, startTime, endTime);
            actInnerMean = mean(actInnerData);        

            % Average x.     
            xInnerData = getsampleusingtime(xInner, startTime, endTime);
            xInnerMean = mean(xInnerData);

            % Average y. 
            yInnerData = getsampleusingtime(yInner, startTime, endTime);
            yInnerMean = mean(yInnerData);
        else 
            luxInnerMean = [];
            claInnerMean = [];
            csInnerMean  = [];
            actInnerMean = [];
            xInnerMean   = [];
            yInnerMean   = [];
        end
        
        if exist(OUTER, 'file') == 2

            % Average lux.
            luxOuterData = getsampleusingtime(luxOuter, startTime, endTime);
            luxOuterMean = mean(luxOuterData);          

            % Average circadian lux.
            claOuterData = getsampleusingtime(claOuter, startTime, endTime);
            claOuterMean = mean(claOuterData);   

            % Average circadian stimulus.
            csOuterData = getsampleusingtime(csOuter, startTime, endTime);
            csOuterMean = mean(csOuterData);   

            % Average activity.
            actOuterData = getsampleusingtime(actOuter, startTime, endTime);
            actOuterMean = mean(actOuterData);         

            % Average x.     
            xOuterData = getsampleusingtime(xOuter, startTime, endTime);
            xOuterMean = mean(xOuterData);   

            % Average y. 
            yOuterData = getsampleusingtime(yOuter, startTime, endTime);
            yOuterMean = mean(yOuterData);  
        else
            luxOuterMean = [];
            claOuterMean = [];
            csOuterMean  = [];
            actOuterMean = [];
            xOuterMean   = [];
            yOuterMean   = [];
        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel = formLabels{iStamp};
        
        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-light_features.csv'], 'a');
        fprintf(fid, ['%4.0f, %4.0f, %s, %s, %s, %s, %s, ', repmat('%8.4f, ', 1, 11) ,'%8.4f\n'], ...
                 iSubject, alarmCounter(iStamp), alarmLabel, formLabel, ... 
                 datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(startTime, 'dd-mm-yyyy HH:MM'), ...
                 datestr(endTime, 'dd-mm-yyyy HH:MM'), ...
                 luxInnerMean, claInnerMean, csInnerMean, actInnerMean, xInnerMean, yInnerMean, ...
                 luxOuterMean, claOuterMean, csOuterMean, actOuterMean, xOuterMean, yOuterMean);
        fclose(fid);

    end
    
end