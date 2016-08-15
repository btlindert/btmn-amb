function analyzeAmbientLight(SUBJECT)

% analyzeAmbientLight analyzes the light data from the dimesimeter sensors 
% at the coat and sweater.

% Path order is as follows:
% /someren/recordings/btmn/subjects/0000
%   /ambient-light/raw
%       /btmn_0000_ambient-light_coat_processed.txt
%       /btmn_0000_ambient-light_sweater_processed.txt

% TODO/OPTIONAL: ADD LOADING OF COATHEADER WITH RED/GREEN/BLUE/ACTIVITY DATA

PATH            = '/someren/recordings/btmn/subjects/';
SUB_PATH        = '/ambient-light/raw/';
PATH_TIMESTAMPS = '/someren/recordings/btmn/import/';
OUTPUT_FOLDER   = '/someren/projects/btmn/analysis/amb/ambient-light/';

  
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

prefix = {'meanLux', 'meanCla', 'meanCs', 'meanAct', 'meanX', 'meanY'};   
labels = generateLabels(prefix, suffix);

% If either file exists, proceed.
if ~isempty(INNER) || ~isempty(OUTER)
    
    % Median filter lux and activity data across the entire time series, to
    % avoid edge flatting in small periods. Remove baseline threshold of
    % 0.05 from activity.
    window = 11;
    actThreshold = 0.04; %slightly above bin 0.038 due to bin width; % or 0.035
    sdThreshold = 0.002;
    
    actInnerMedianFiltered = actInner;
    actOuterMedianFiltered = actOuter;
    luxInnerMedianFiltered = luxInner;
    luxOuterMedianFiltered = luxOuter;
    
    actInnerMedianFiltered.Data = medfilt1(actInnerMedianFiltered.Data, window);
    actInnerMedianFiltered.Data(actInnerMedianFiltered.Data <= actThreshold) = 0;
    actOuterMedianFiltered.Data = medfilt1(actOuterMedianFiltered.Data, window);
    actOuterMedianFiltered.Data(actOuterMedianFiltered.Data <= actThreshold) = 0;
    luxInnerMedianFiltered.Data = medfilt1(luxInnerMedianFiltered.Data, window);
    luxOuterMedianFiltered.Data = medfilt1(luxOuterMedianFiltered.Data, window);
    
    % Calculate SD in window.
    sdInnerMedianFiltered = actInnerMedianFiltered;
    sdOuterMedianFiltered = actOuterMedianFiltered;
    
    %sdInnerMedianFiltered.Data = nan;
    %sdOuterMedianFiltered.Data = nan;

    for i = 6:length(sdInnerMedianFiltered) - 5
        sdInnerMedianFiltered.Data(i) = std(actInnerMedianFiltered.Data(i-5:i+5));
     
    end

    for i = 6:length(sdOuterMedianFiltered) - 5
        sdOuterMedianFiltered.Data(i) = std(actOuterMedianFiltered.Data(i-5:i+5));
    end
    
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
        startTimes = cell(1,5);
        endTimes   = cell(1,5);
        meanLux    = zeros(1,5);
        meanCla    = zeros(1,5);
        meanCs     = zeros(1,5);
        meanAct    = zeros(1,5);
        meanX      = zeros(1,5);
        meanY      = zeros(1,5);

        
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
            if ~isempty(INNER) && ~isempty(OUTER)

                % Select median filtered lux, activity and SD.
                luxInnerMed = getsampleusingtime(luxInnerMedianFiltered, startTime, endTime);
                luxOuterMed = getsampleusingtime(luxOuterMedianFiltered, startTime, endTime);
                actInnerMed = getsampleusingtime(actInnerMedianFiltered, startTime, endTime);
                actOuterMed = getsampleusingtime(actOuterMedianFiltered, startTime, endTime);
                sdInnerMed = getsampleusingtime(sdInnerMedianFiltered, startTime, endTime);
                sdOuterMed = getsampleusingtime(sdOuterMedianFiltered, startTime, endTime);            
                                                                
                nI = length(luxInnerMed.Data);
                nO = length(luxOuterMed.Data);
                N = max([nI, nO]);
                
                % Paste all data to NaN matrix, in case data is not available
                % for equal duration.
                luxMed = nan(N, 2);
                luxMed(1:nI, 1) = luxInnerMed.Data;
                luxMed(1:nO, 2) = luxOuterMed.Data;
                
                actMed = nan(N, 2);
                actMed(1:nI, 1) = actInnerMed.Data;
                actMed(1:nO, 2) = actOuterMed.Data;
                
                sdMed = nan(N, 2);
                sdMed(1:nI, 1) = sdInnerMed.Data;
                sdMed(1:nO, 2) = sdOuterMed.Data;
                
                % Find indices that correspond with selection criteria. For
                % this we only use the median filtered lux, activity and SD.
                
                % All lux = NaN, unless...
                % If actOuter > 0 AND luxOuter > 0, 
                % pick sensor with max lux.
                sel1 = find(actMed(:,2) > 0 & luxMed(:,2) >= 0);
                
                % If actOuter > 0 AND luxOuter > 0 AND
                % actInner > 0 AND LuxInner > 0, 
                % pick Outer sensor (luxOuter).
                sel2 = find(actMed(:,2) > 0 & luxMed(:,2) >= 0 ...
                    & actMed(:,1) > 0 & luxMed(:,1) >= 0 );
                
                % If actOuter <= 0 AND actInner > 0, pick Inner sensor (luxInner). 
                sel3 = find(actMed(:,2) <= 0 & actMed(:,1) > 0);
               
                
                % Paste all other variables to NaN matrices.
                luxInnerData = getsampleusingtime(luxInner, startTime, endTime);
                claInnerData = getsampleusingtime(claInner, startTime, endTime);
                csInnerData  = getsampleusingtime(csInner, startTime, endTime);
                actInnerData = getsampleusingtime(actInner, startTime, endTime);
                xInnerData   = getsampleusingtime(xInner, startTime, endTime);
                yInnerData   = getsampleusingtime(yInner, startTime, endTime);
                  
                luxOuterData = getsampleusingtime(luxOuter, startTime, endTime);
                claOuterData = getsampleusingtime(claOuter, startTime, endTime);
                csOuterData  = getsampleusingtime(csOuter, startTime, endTime);
                actOuterData = getsampleusingtime(actOuter, startTime, endTime);
                xOuterData   = getsampleusingtime(xOuter, startTime, endTime);
                yOuterData   = getsampleusingtime(yOuter, startTime, endTime);
                
                lux = nan(N, 2);
                lux(1:nI, 1) = luxInnerData.Data;
                lux(1:nO, 2) = luxOuterData.Data;
                
                cla = nan(N, 2);
                cla(1:nI, 1) = claInnerData.Data;
                cla(1:nO, 2) = claOuterData.Data;
                
                cs = nan(N, 2);
                cs(1:nI, 1) = csInnerData.Data;
                cs(1:nO, 2) = csOuterData.Data;
                
                act = nan(N, 2);
                act(1:nI, 1) = actInnerData.Data;
                act(1:nO, 2) = actOuterData.Data;
                                
                x = nan(N, 2);
                x(1:nI, 1) = xInnerData.Data;
                x(1:nO, 2) = xOuterData.Data;
                                
                y = nan(N, 2);
                y(1:nI, 1) = yInnerData.Data;
                y(1:nO, 2) = yOuterData.Data;
                
                % Find which column contains the max value and select the data.
                % Apply sel1, before sel2, before sel3.
                [~, maxCol] = max(luxMed(sel1, :), [], 2); 
                
                
                % Average log10(lux), use lux instead of median filtered lux.
                luxSelected = nan(N, 1);
                luxSelected(sel1) = max(lux(sel1, maxCol), [], 2);
                luxSelected(sel2) = lux(sel2, 2);
                luxSelected(sel3) = lux(sel3, 1);

                meanLux(timeSlot) = nanmean(log10(luxSelected + 1));
                
                % Average circadian lux.
                claSelected = nan(N, 1);
                claSelected(sel1) = max(cla(sel1, maxCol), [], 2);
                claSelected(sel2) = cla(sel2, 2);
                claSelected(sel3) = cla(sel3, 1);
                
                meanCla(timeSlot) = nanmean(claSelected);

                % Average circadian stimulus.
                csSelected = nan(N, 1);
                csSelected(sel1) = max(cs(sel1, maxCol), [], 2);
                csSelected(sel2) = cs(sel2, 2);
                csSelected(sel3) = cs(sel3, 1);
                
                meanCs(timeSlot) = nanmean(csSelected);

                % Average activity: use median filtered activity!
                actSelected = nan(N, 1);
                actSelected(sel1) = max(act(sel1, maxCol), [], 2);
                actSelected(sel2) = act(sel2, 2);
                actSelected(sel3) = act(sel3, 1);
                
                meanAct(timeSlot) = nanmean(actSelected);      

                % Average x.     
                xSelected = nan(N, 1);
                xSelected(sel1) = max(x(sel1, maxCol), [], 2);
                xSelected(sel2) = x(sel2, 2);
                xSelected(sel3) = x(sel3, 1);
                
                meanX(timeSlot) = nanmean(xSelected);
                
                % Average y. 
                ySelected = nan(N, 1);
                ySelected(sel1) = max(y(sel1, maxCol), [], 2);
                ySelected(sel2) = y(sel2, 2);
                ySelected(sel3) = y(sel3, 1);
                
                meanY(timeSlot) = nanmean(ySelected);
                
            else % NaN.
                
                meanLux(timeSlot) = NaN;
                meanCla(timeSlot) = NaN;
                meanCs(timeSlot)  = NaN;
                meanAct(timeSlot) = NaN;
                meanX(timeSlot)   = NaN;
                meanY(timeSlot)   = NaN;
                
            end
   
        end
        
         figure()
        subplot(4,1,1);
        plot(luxInnerMed); hold on; plot(luxOuterMed, 'r'); hold off;
        title('lux'); axis tight
        subplot(4,1,2); 
        plot(actInnerMed); hold on; plot(actOuterMed, 'r'); hold off;
        title('act'); axis tight
        subplot(4,1,3);
        plot(sdInnerMed); hold on; plot(sdOuterMed, 'r'); hold off;
        title('sd'); ylim([0, 0.004]); axis tight
        subplot(4,1,4);
        plot(luxSelected);        
        title('lux selected'); axis tight
        
        fprintf('figure %f, mean = %f\n', iStamp, nanmean(luxSelected));
        
        % Write data to txt file.
%         alarmLabel = alarmLabels{iStamp};
%         formLabel = formLabels{iStamp};
% 
%         fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-light_features.csv'], 'a');
%         fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ...
%             repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
%             SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ... 
%             datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
%             sprintf([repmat('%s, ', 1, 4), '%s'], startTimes{:}), ...
%             sprintf([repmat('%s, ', 1, 4), '%s'], endTimes{:}), ...
%             meanLux, meanCla, meanCs, meanAct, meanX, meanY);
%         fclose(fid);
        
    end
    
end
    
end