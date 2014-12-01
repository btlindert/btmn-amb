% this file creates random sampling schemes for the Nexus phone 
% and the Philips temperature sensor, but makes sure that both are 
% synchonized.
%   - The Philips temperature sensor samples both day and night. The phone only
%     samples during the day.
%   - The temperature sensor starts recording 15 minutes before the phone
%     rings its alarm.
%   - The temperature sensor should be set to: 2 Hz for 900 samples (

% create randomized xml scripts for each subject
clear all; close all; clc;
% non repeatability of the random number generator
rng shuffle

%% set the following before running the script
% number of subjects
N = 100;                      
OUTPUT_FOLDER = 'D:\tresorit\matlab\philips-movisensXS\';

%% DO NOT CHANGE ANYTHING BELOW THIS LINE %%
startDate = '01-01-2014';   

for subject = 5:N
    %% randomize time samples for the day for both the Nexus and the Philips temperature sensor
    days         = 7;                  % number of days
    trig_per_day = 14;                 % number of triggers/day
    waketime     = 8;                  % wake time in hours
    bedtime      = 22;                 % bed time in hours
    blocks       = trig_per_day*days;  % number of blocks = number of triggers
    delay        = 16;                 % minimal time between beeps
    minutes      = 24*60*days;         % calculate number of minutes in a day

    % create time series in minutes from start till end
    time    = zeros(minutes,1);
    start   = datevec(startDate, 'dd-mm-yyyy');
    time(1) = datenum([start(1:3) waketime 00 00]);

    for i = 2:length(time);
        time(i) = addtodate(time(i-1), 1, 'minute');
    end

    % reshape to [minutes x day]
    time = reshape(time, 24*60, days);

    % split data into period from 08:00-22:00 and 22:00-08:00
    % 08:00-22:00 = first 14*60 rows
    day = time(1:14*60,:);   
    % 22:00-08:00 = last 10*60 rows
    night = time(14*60+1:end,:);
    
    % reshape both to a continuous vector and reshape per block
    day = reshape(day, numel(day), 1);
    night = reshape(night, numel(night), 1);
    
    % reshape to blocks
    daytriggers = 8;
    dayblocks = daytriggers*days;
    minperdayblock = floor(numel(day)/dayblocks);
    day = day(1:minperdayblock*dayblocks);
    day = reshape(day, minperdayblock, dayblocks);
    
    nighttriggers = 6;
    nightblocks = nighttriggers*days;
    minpernightblock = floor(numel(night)/nightblocks);
    night = night(1:minpernightblock*nightblocks);
    night = reshape(night, minpernightblock, nightblocks);

    % remove first 8 minutes (delay/2) and last 8 minutes of each block
    day = day(delay/2+1:end-(delay/2),:);
    night = night(delay/2+1:end-(delay/2),:);

    % generate random numbers between [0,1], for every block convert to index (idx) and select appropriate times
    x = rand(1,dayblocks);                           
    day_idx = ceil(x*size(day,1)); 
    
    x = rand(1,nightblocks);                           
    night_idx = ceil(x*size(night,1)); 
    
    for i = 1:numel(night_idx)
        nightz(i) = night(night_idx(i),i);      
    end

    for i = 1:numel(day_idx)
        dayz(i) = day(day_idx(i),i);      
    end

    dayz = reshape(dayz, daytriggers, days);
    nightz = reshape(nightz, nighttriggers, days);
    stamps = [dayz; nightz];
    
    %% SAVE TIMESTAMPS TO -MAT FILE
    save([OUTPUT_FOLDER '\mat\' sprintf('%04.0f', subject) '_timestamps.mat'], 'stamps', '-mat');
    
    %% SAVE DAYTIME MOVISENSXS TIMESTAMPS TO -TXT FILE    
    fid = fopen([OUTPUT_FOLDER '\movisensXS\' sprintf('%04.0f', subject) '_timestamps_Phone.txt'], 'w');
    
    % select only the day triggers
    stamps = dayz;
        
    % write to file
    for day = 1:size(stamps,2)
        for trigger = 1:size(stamps,1)
            fprintf(fid, '%s %s %s\r\n', num2str(day), num2str(trigger), datestr(stamps(trigger, day), 'HH:MM'));
        end
    end

    % close the file 
    fclose(fid);
    
end