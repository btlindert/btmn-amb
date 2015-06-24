function analyzeAmbientLight(SUBJECT)

% analyzeAmbientLight analyzes the light data from the dimesimeter sensors 
% at the coat and sweater.

% Path order is as follows:
% /data1/recordings/btmn/subjects/0000
%   /ambient-light/raw
%       /btmn_0000_ambient-light_coat_processed.txt
%       /btmn_0000_ambient-light_sweater_processed.txt

% TODO/OPTIONAL: ADD LOADING OF COATHEADER WITH RED/GREEN/BLUE/ACTIVITY DATA

PATH            = '/data1/recordings/btmn/subjects/';
SUB_PATH        = '/ambient-light/raw/';
PATH_TIMESTAMPS = '/data1/recordings/btmn/import/';
OUTPUT_FOLDER   = '/data2/projects/btmn/analysis/amb/ambient-light/';

  
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
files = subdir([PATH SUBJECT SUB_PATH '*sweater_processed.*']);

if size(files, 1) == 1

    INNER    = files(1).name;
    [luxInner, claInner, csInner, actInner, xInner, yInner] = ...
        dimesimeterRead(INNER);
    
end 

% OUTER.
files = subdir([PATH SUBJECT SUB_PATH '*coat_processed.*']); 

if size(files, 1) == 1

    OUTER    = files(1).name;
    [luxOuter, claOuter, csOuter, actOuter, xOuter, yOuter] = ...
        dimesimeterRead(OUTER);
    
end


% Generate labels for header.
prefix = {'startTime', 'endTime'};
suffix = {'60', '45', '30', '15', '0'};
times  = generateLabels(prefix, suffix);

prefix = {'luxInner', 'claInner', 'csInner', 'actInner', 'xInner', 'yInner', ...
          'luxOuter', 'claOuter', 'csOuter', 'actOuter', 'xOuter', 'yOuter'};   
labels = generateLabels(prefix, suffix);

% If either file exists, proceed.
if ~isempty(INNER) || ~isempty(OUTER)

    
    % Open file and write headers.
    fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-light_features.csv'], 'w');
    fprintf(fid, [repmat('%s, ', 1, 6), '%s\n'],...
        'subjectId', 'alarmCounter', 'alarmLabel', 'formLabel', ... 
        'alarmTime', times, labels);     
    fclose(fid);

    
    % Loop through all the alarms.    
    for iStamp = 1:numel(alarmTimestamps)

        
        % Alarm timestamp.
        alarmTime = alarmTimestamps(iStamp);
      
      
        % Declare vars.
        startTimes   = cell(1,5);
        endTimes     = cell(1,5);
        meanLuxInner = zeros(1,5);
        meanClaInner = zeros(1,5);
        meanCsInner  = zeros(1,5);
        meanActInner = zeros(1,5);
        meanXInner   = zeros(1,5);
        meanYInner   = zeros(1,5);
        meanLuxOuter = zeros(1,5);
        meanClaOuter = zeros(1,5);
        meanCsOuter  = zeros(1,5);
        meanActOuter = zeros(1,5);
        meanXOuter   = zeros(1,5);
        meanYOuter   = zeros(1,5);

        
        % Onset and offset of analysis periods.
        onset  = [-60, -45, -30, -15, 0];
        offset = [-45, -30, -15, 0, 5];
        
        
        for timeSlot = 1:5
        
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            startTimes{timeSlot} = datestr(startTime, 'dd-mm-yyyy HH:MM');
            endTimes{timeSlot}   = datestr(endTime, 'dd-mm-yyyy HH:MM');

            % Not all files were collected so we test for the existence of the file
            % first.
            if ~isempty(INNER)

                % Average lux.
                luxInnerData = getsampleusingtime(luxInner, startTime, endTime);
                meanLuxInner(timeSlot) = getMeanData(luxInnerData);

                % Average circadian lux.
                claInnerData = getsampleusingtime(claInner, startTime, endTime);
                meanClaInner(timeSlot) = getMeanData(claInnerData);

                % Average circadian StimuluS.
                csInnerData = getsampleusingtime(csInner, startTime, endTime);
                meanCsInner(timeSlot) = getMeanData(csInnerData);

                % Average activity.
                actInnerData = getsampleusingtime(actInner, startTime, endTime);
                meanActInner(timeSlot) = getMeanData(actInnerData);        

                % Average x.     
                xInnerData = getsampleusingtime(xInner, startTime, endTime);
                meanXInner(timeSlot) = getMeanData(xInnerData);

                % Average y. 
                yInnerData = getsampleusingtime(yInner, startTime, endTime);
                meanYInner(timeSlot) = getMeanData(yInnerData);
                
            else % NaN.
                
                meanLuxInner(timeSlot) = NaN;
                meanClaInner(timeSlot) = NaN;
                meanCsInner(timeSlot)  = NaN;
                meanActInner(timeSlot) = NaN;
                meanXInner(timeSlot)   = NaN;
                meanYInner(timeSlot)   = NaN;
                
            end

            if ~isempty(OUTER)

                % Average lux.
                luxOuterData = getsampleusingtime(luxOuter, startTime, endTime);
                meanLuxOuter(timeSlot) = getMeanData(luxOuterData);          

                % Average circadian lux.
                claOuterData = getsampleusingtime(claOuter, startTime, endTime);
                meanClaOuter(timeSlot) = getMeanData(claOuterData);   

                % Average circadian stimulus.
                csOuterData = getsampleusingtime(csOuter, startTime, endTime);
                meanCsOuter(timeSlot) = getMeanData(csOuterData);   

                % Average activity.
                actOuterData = getsampleusingtime(actOuter, startTime, endTime);
                meanActOuter(timeSlot) = getMeanData(actOuterData);         

                % Average x.     
                xOuterData = getsampleusingtime(xOuter, startTime, endTime);
                meanXOuter(timeSlot) = getMeanData(xOuterData);   

                % Average y. 
                yOuterData = getsampleusingtime(yOuter, startTime, endTime);
                meanYOuter(timeSlot) = getMeanData(yOuterData);  
                
            else
                
                meanLuxOuter(timeSlot) = NaN;
                meanClaOuter(timeSlot) = NaN;
                meanCsOuter(timeSlot)  = NaN;
                meanActOuter(timeSlot) = NaN;
                meanXOuter(timeSlot)   = NaN;
                meanYOuter(timeSlot)   = NaN;
                
            end

        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-light_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ...
            repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ... 
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            sprintf([repmat('%s, ', 1, 4), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, 4), '%s'], endTimes{:}), ...
            meanLuxInner, meanClaInner, meanCsInner, meanActInner, meanXInner, meanYInner, ...
            meanLuxOuter, meanClaOuter, meanCsOuter, meanActOuter, meanXOuter, meanYOuter);
        fclose(fid);
        
    end
    
end
    
end