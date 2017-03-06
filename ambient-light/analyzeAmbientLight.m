function analyzeAmbientLight(SUBJECT)
% analyzeAmbientLight analyzes the light data from the dimesimeter sensors 
% at the coat and sweater.

% Path order is as follows:
% /someren/recordings/btmn/subjects/0000
%   /ambient-light/raw
%       /btmn_0000_ambient-light_coat_processed.txt
%       /btmn_0000_ambient-light_sweater_processed.txt

% TODO/OPTIONAL: ADD LOADING OF COATHEADER WITH RED/GREEN/BLUE/ACTIVITY DATA
disp('Running analyzeAmbientLight...');

plots               = 'off';
validityPlots       = 'off';
validSelectionPlots = 'off';
validSelectorsPlots = 'off';

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


% Set baseline noise removal threshold on activity.
% Specify non-activity window
window       = 15;
actThreshold = 0.045; %slightly above bin 0.038 due to bin width;

% INNER.
files = subdir([PATH SUBJECT SUB_PATH '*sweater_processed.*']);

if size(files, 1) == 1

    disp('Inner data present...');
    INNER    = files(1).name;
    [luxInner, claInner, csInner, actInner, xInner, yInner] = ...
        dimesimeterRead(INNER);
    
    % Check validity of entire time series. 
    validInner = validity(actInner, luxInner, window, actThreshold, validityPlots, 'Inner');

else 
    
    INNER      = '';
    validInner = [];
    luxInner   = [];
    claInner   = [];
    csInner    = [];
    actInner   = [];
    xInner     = [];
    yInner     = [];
    
end 

% OUTER.
files = subdir([PATH SUBJECT SUB_PATH '*coat_processed.*']); 

if size(files, 1) == 1

    disp('Outer data present...')
    OUTER    = files(1).name;
    [luxOuter, claOuter, csOuter, actOuter, xOuter, yOuter] = ...
        dimesimeterRead(OUTER);
    
    % Check validity of entire time series. 
    validOuter = validity(actOuter, luxOuter, window, actThreshold, validityPlots, 'Outer');

else 
    
    OUTER      = '';
    validOuter = [];
    luxOuter   = [];
    claOuter   = [];
    csOuter    = [];
    actOuter   = [];
    xOuter     = [];
    yOuter     = [];
    
end

% Generate labels for header.
prefix = {'startTime', 'endTime'};
suffix = {'Rel', '15', '0'};
times  = generateLabels(prefix, suffix);

prefix = {'duration', 'meanLux', 'meanThreeParLog', 'meanFourParLog', 'meanCla', 'meanCs', 'meanAct', 'meanX', 'meanY', 'nNan'};   
labels = generateLabels(prefix, suffix);

% If either file exists, proceed.
if ~isempty(INNER) || ~isempty(OUTER)
    
    disp('Processing...')
    
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
      
        nSlots = numel(onset);
             
        % Declare vars.
        duration        = offset-onset; 
        startTimes      = cell(1,nSlots);
        endTimes        = cell(1,nSlots);
        meanLux         = zeros(1,nSlots);
        meanThreeParLog = zeros(1,nSlots);
        meanFourParLog  = zeros(1,nSlots);
        meanCla         = zeros(1,nSlots);
        meanCs          = zeros(1,nSlots);
        meanAct         = zeros(1,nSlots);
        meanX           = zeros(1,nSlots);
        meanY           = zeros(1,nSlots);
        nNan            = zeros(1,nSlots);

        for timeSlot = 1:nSlots
        
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            startTimes{timeSlot} = datestr(startTime, 'dd-mm-yyyy HH:MM');
            endTimes{timeSlot}   = datestr(endTime, 'dd-mm-yyyy HH:MM');

            % Not all files were collected so we test for the existence of the file
            % first.
            if ~isempty(INNER) || ~isempty(OUTER)

                [selInner, selOuter, selMax] = validSelectors(validInner, validOuter,...
                    startTime, endTime, validSelectorsPlots);
                
                % Select the actual data samples.
                luxSelected = validSelection(luxInner, luxOuter, startTime, endTime,...
                    selInner, selOuter, selMax, validSelectionPlots);
                
                claSelected = validSelection(claInner, claOuter, startTime, endTime,...
                    selInner, selOuter, selMax, 'off');
                
                csSelected = validSelection(csInner, csOuter, startTime, endTime,...
                    selInner, selOuter, selMax, 'off');
                
                actSelected = validSelection(actInner, actOuter, startTime, endTime,...
                    selInner, selOuter, selMax, 'off');
                                
                xSelected = validSelection(xInner, xOuter, startTime, endTime,...
                    selInner, selOuter, selMax, 'off');
                                
                ySelected = validSelection(yInner, yOuter, startTime, endTime,...
                    selInner, selOuter, selMax, 'off');

                % Log10.
                meanLux(timeSlot) = nanmean(log10(luxSelected + 1));
                
                % 3-parameter logistic
                a = -0.161;
                b = 88.0;
                c = 1.0;
                threeParLog = @(x) ((a-c)./(1 + (x./b))) + c;
                meanThreeParLog(timeSlot) = nanmean(threeParLog(luxSelected));
                
                % 4-parameter logistic
                a = -0.0156;
                b = 106;
                c = 0.936;
                d = 3.55;
                fourParLog = @(x) ((a-c)./(1 + (x./b).^d)) + c;
                meanFourParLog(timeSlot) = nanmean(fourParLog(luxSelected)); 
                
                % Circadian stimulus
                meanCla(timeSlot) = nanmean(claSelected);
                
                % Circadian lux 
                meanCs(timeSlot)  = nanmean(csSelected);
                
                % Activity
                actSelected       = actSelected - actThreshold;
                actSelected(actSelected < 0) = 0;
                meanAct(timeSlot) = nanmean(actSelected);
                
                % x
                meanX(timeSlot)   = nanmean(xSelected); 
                
                % y
                meanY(timeSlot)   = nanmean(ySelected);
                
                % Number of NaNs
                % NANs is equal for all variables, so let's just pick lux.
                nNan(timeSlot)    = sum(isnan(luxSelected));
                
                
            else % NaN.
                
                meanLux(timeSlot) = NaN;
                meanThreeParLog(timeslot) = NaN;
                meanFourParLog(timeslot) = NaN;
                meanCla(timeSlot) = NaN;
                meanCs(timeSlot)  = NaN;
                meanAct(timeSlot) = NaN;
                meanX(timeSlot)   = NaN;
                meanY(timeSlot)   = NaN;
                nNan(timeSlot)    = NaN;
                
            end
              
            if strcmpi(plots, 'on')
                
                figure()
                subplot(4,1,1);
                bar(luxSelected)
                %bar(luxInnerMed.data); hold on; bar(luxOuterMed.data, 'r'); hold off;
                title('lux'); axis tight
                subplot(4,1,2); 
                bar(act)
                %bar(actInnerMed.data); hold on; bar(actOuterMed.data, 'r'); hold off;
                title('act'); axis tight
                subplot(4,1,3);
                %bar(sd)
                bar(sdInnerMed.data); hold on; bar(sdOuterMed.data, 'r'); hold off;
                title('sd'); ylim([0, 0.004]); axis tight
                subplot(4,1,4);    
                bar(luxSelected);        
                title('lux selected'); axis tight
                
            end
        
        end
        
        % Write data to txt file.
        alarmLabel = alarmLabels{iStamp};
        formLabel  = formLabels{iStamp};

        fid = fopen([OUTPUT_FOLDER 'btmn_' SUBJECT '_ambient-light_features.csv'], 'a');
        fprintf(fid, ['%s, %4.0f, ', repmat('%s, ', 1, 5), ...
            repmat('%8.4f, ', 1, numel(prefix)*numel(suffix)-1), '%8.4f\n'], ...
            SUBJECT, alarmCounter(iStamp), alarmLabel, formLabel, ... 
            datestr(alarmTime, 'dd-mm-yyyy HH:MM'), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, nSlots-1), '%s'], endTimes{:}), ... 
            duration, meanLux, meanThreeParLog, meanFourParLog, meanCla, meanCs, meanAct, meanX, meanY, nNan);
        fclose(fid);
        
    end
    
end
    
disp('Analysis completed without errors...');

end