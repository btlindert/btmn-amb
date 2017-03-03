function analyzeEnvironment(SUBJECT)
% analyzeEnvironment is a combined version of analyzeAmbientLight, 
% analyzeAmbientHumidity and analyzeAmbientTemperature. All these sensors
% were integrated in the same brooche. It thus makes sense to combine the
% validity of the light measurements with the temp/humidity recordings. 
% Because the temp/humidity recordings now depends on the presence of the
% light measurements we also export the median values from the sensors
% using the other scripts. This information can help with imputation.

% Path order is as follows:
% /someren/recordings/btmn/subjects/0000
%   /ambient-light/raw
%       /btmn_0000_ambient-light_coat_processed.txt
%       /btmn_0000_ambient-light_sweater_processed.txt

% TODO/OPTIONAL: ADD LOADING OF COATHEADER WITH RED/GREEN/BLUE/ACTIVITY DATA
disp('Running analyzeEnvironment...');

plots               = 'off';
validityPlots       = 'off';
validSelectionPlots = 'off';
validSelectorsPlots = 'off';

PATH            = '/someren/recordings/btmn/subjects/';
LIGHT_PATH      = '/ambient-light/raw/';
HUM_PATH        = '/humdity/raw/';
TEMP_PATH       = '/temperature/raw/';
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

% INNER LIGHT
files = subdir([PATH SUBJECT LIGHT_PATH '*sweater_processed.*']);

if size(files, 1) == 1

    disp('Inner data present...');
    INNER_LIGHT    = files(1).name;
    [luxInner, claInner, csInner, actInner, xInner, yInner] = ...
        dimesimeterRead(INNER_LIGHT);
    
    % Check validity of entire time series. 
    validInner = validity(actInner, luxInner, window, actThreshold, validityPlots, 'Inner');

else 
    
    INNER_LIGHT      = '';
    validInner = [];
    luxInner   = [];
    claInner   = [];
    csInner    = [];
    actInner   = [];
    xInner     = [];
    yInner     = [];
    
end 

% OUTER LIGHT.
files = subdir([PATH SUBJECT LIGHT_PATH '*coat_processed.*']); 

if size(files, 1) == 1

    disp('Outer data present...')
    OUTER_LIGHT    = files(1).name;
    [luxOuter, claOuter, csOuter, actOuter, xOuter, yOuter] = ...
        dimesimeterRead(OUTER_LIGHT);
    
    % Check validity of entire time series. 
    validOuter = validity(actOuter, luxOuter, window, actThreshold, validityPlots, 'Outer');

else 
    
    OUTER_LIGHT      = '';
    validOuter = [];
    luxOuter   = [];
    claOuter   = [];
    csOuter    = [];
    actOuter   = [];
    xOuter     = [];
    yOuter     = [];
    
end


% Set vars to empty or remove.
OUTER_TEMP = '';
INNER_TEMP = '';        


% INNER TEMPERATURE
files = subdir([PATH SUBJECT TEMP_PATH '*sweater*']);

if size(files, 1) == 1

    INNER_TEMP = files(1).name;
    temperatureInner = ibuttonTemperatureRead(INNER_TEMP);
    
end    

% OUTER TEMPERATURE
files = subdir([PATH SUBJECT TEMP_PATH '*coat*']); 

if size(files, 1) == 1

    OUTER_TEMP = files(1).name;
    temperatureOuter = ibuttonTemperatureRead(OUTER_TEMP);

end

% Set vars to empty or remove.
OUTER_HUM = '';
INNER_HUM = '';        


% INNER HUMIDITY
files = subdir([PATH SUBJECT HUM_PATH '*sweater.*']);

if size(files, 1) == 1

    INNER_HUM    = files(1).name;
    humInner = ibuttonHumidityRead(INNER_HUM);

end    

% OUTER HUMIDITY
files = subdir([PATH SUBJECT HUM_PATH '*coat.*']); 

if size(files, 1) == 1

    OUTER_HUM    = files(1).name;
    humOuter = ibuttonHumidityRead(OUTER_HUM);

end


% Generate labels for header.
prefix = {'startTime', 'endTime'};
suffix = {'Rel', '60', '45', '30', '15', '0'};
times  = generateLabels(prefix, suffix);

prefix = {'duration', 'medLux', 'medThreeParLog', 'medFourParLog', 'medCla', 'medCs', 'medAct', 'medX', 'medY', 'medHum', 'medTemp', 'nNan'};   
labels = generateLabels(prefix, suffix);

% If either file exists, proceed.
if ~isempty(INNER_LIGHT) || ~isempty(OUTER_LIGHT)
    
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
        onset  = [-1*rel, -60, -45, -30, -15, 0];
        offset = [0, -45, -30, -15, 0, 5];
      
        nSlots = numel(onset);
             
        % Declare vars.
        duration       = offset-onset; 
        startTimes     = cell(1,nSlots);
        endTimes       = cell(1,nSlots);
        medLux         = zeros(1,nSlots);
        medThreeParLog = zeros(1,nSlots);
        medFourParLog  = zeros(1,nSlots);
        medCla         = zeros(1,nSlots);
        medCs          = zeros(1,nSlots);
        medAct         = zeros(1,nSlots);
        medX           = zeros(1,nSlots);
        medY           = zeros(1,nSlots);
        medHum         = zeros(1,nSlots);
        medTemp        = zeros(1,nSlots);
        nNan           = zeros(1,nSlots);

        for timeSlot = 1:nSlots
        
            % Get 15 minute periods of data prior to the phone alarms
            % plus 5 minutes during the task
            startTime = addtodate(alarmTime, onset(timeSlot), 'minute');
            endTime   = addtodate(alarmTime, offset(timeSlot), 'minute');

            startTimes{timeSlot} = datestr(startTime, 'dd-mm-yyyy HH:MM');
            endTimes{timeSlot}   = datestr(endTime, 'dd-mm-yyyy HH:MM');

            % Not all files were collected so we test for the existence of the file
            % first.
            if ~isempty(INNER_LIGHT) || ~isempty(OUTER_LIGHT)

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
                
                % Humidity
                humSelected = validSelection(humInner, humOuter, startTime, endTime,...
                    selInner, selOuter, selMax, 'off');
                
                % Temperature
                tempSelected = validSelection(tempInner, tempOuter, startTime, endTime,...
                    selInner, selOuter, selMax, 'off');
                
                % Log10.
                medLux(timeSlot) = nanmean(log10(luxSelected + 1));
                
                % 3-parameter logistic
                a = -0.161;
                b = 88.0;
                c = 1.0;
                threeParLog = @(x) ((a-c)./(1 + (x./b))) + c;
                medThreeParLog(timeSlot) = nanmedian(threeParLog(luxSelected));
                
                % 4-parameter logistic
                a = -0.0156;
                b = 106;
                c = 0.936;
                d = 3.55;
                fourParLog = @(x) ((a-c)./(1 + (x./b).^d)) + c;
                medFourParLog(timeSlot) = nanmedian(fourParLog(luxSelected)); 
                
                % Circadian stimulus
                medCla(timeSlot) = nanmedian(claSelected);
                
                % Circadian lux 
                medCs(timeSlot)  = nanmedian(csSelected);
                
                % Activity
                actSelected       = actSelected - actThreshold;
                actSelected(actSelected < 0) = 0;
                medAct(timeSlot) = nanmedian(actSelected);
                
                % x
                medX(timeSlot)   = nanmedian(xSelected); 
                
                % y
                medY(timeSlot)   = nanmedian(ySelected);
                                
                % Humidity
                medHum(timeSlot) = nanmedian(humSelected);
                                
                % Temperature
                medTemp(timeSlot) = nanmedian(tempSelected);
                
                % Number of NaNs
                % NANs is equal for all variables, so let's just pick lux.
                nNan(timeSlot)    = sum(isnan(luxSelected));
    
            else % NaN.
                
                medLux(timeSlot)         = NaN;
                medThreeParLog(timeslot) = NaN;
                medFourParLog(timeslot)  = NaN;
                medCla(timeSlot)         = NaN;
                medCs(timeSlot)          = NaN;
                medAct(timeSlot)         = NaN;
                medX(timeSlot)           = NaN;
                medY(timeSlot)           = NaN;
                medHum(timeSlot)         = NaN;
                medTemp(timeSlot)        = NaN;
                nNan(timeSlot)           = NaN;
                
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
            sprintf([repmat('%s, ', 1, 5), '%s'], startTimes{:}), ...
            sprintf([repmat('%s, ', 1, 5), '%s'], endTimes{:}), ... 
            duration, medLux, medThreeParLog, medFourParLog, medCla, medCs, medAct, medX, medY, medHum, medTemp, nNan);
        fclose(fid);
        
    end
    
end
    
disp('Analysis completed without errors...');

end