function actValid = validity(activity, lux, window, threshold, plots, tag)
% Validity checks the validity of dimesimeter measurements based on its
% activity and light sensor.

% Periods of >15-20 minutes immobility are very unlikely during the day 
% (Romeijn, 2012) and an indication that the sensor is not being worn. 
% On the other hand, short activity bouts are very likely (e.g. Ayabe, 
% 2013, BMC Research Notes) especially if the sensor data is aggregated
% across a minute interval.

% Spurious activity epochs are therefore almost always valid, but epochs 
% without activity become less valid with increasing time, especially 
% if >15 minutes.

% Each epoch of no activity is checked if its part of a `window` period 
% of immobility by sliding a window from -window to +window minutes.

% This also corrects for the instances in which activity drops below the
% conservative noise threshold for several minutes of little activity
% (0.035-0.045). 

% If either sensor has valid data, we pick sensor with the highest lux
% measurement. Reasoning: the coat could cover the sensor, but not 
% necessarily, if the coat is open.

% 0 lux measurements are extremely rare in real life, so lux must
% be > 0 to be valid.

act   = activity.data;
lux   = lux.data;
n     = length(act);
valid = ones(n,1);

% Remove threshold
act = act-threshold;

% Valid activity
idx = find(act <= 0); % select only the non-activity epochs
idx = idx(idx > window & idx <= (n-window)); % skip first and last window minutes
for i = 1:length(idx)
    ii = idx(i);
    % For all non-activity epochs
    for j = -window:0
        % For all windows starting at j of length window.
        % Select data in window.
        df = act(ii+j:ii+j+window);
        if sum(df <= 0) == length(df) % all epochs == non-activity
            valid(ii) = 0; % an invalid period is found!
            %break
        end
    end
end

validActivity = valid;

% Valid light
validLux = ones(n,1);
validLux(lux <= 0) = 0;

% Combined light and activity.
valid(lux <= 0) = 0;


if strcmpi(plots, 'on')

    figure()
    title(tag);
    
    subplot(3,1,1);
    bar(act); hold on; bar(validActivity*-1); hold off;
    title('Activity'); ylim([-1, 1]);

    subplot(3,1,2)
    bar(log10(lux+1)); hold on; bar(validLux*-1); hold off;
    title('Lux'); ylim([-1, 3]);
    
    subplot(3,1,3); 
    bar(log10(lux.*valid+1)); hold on; bar(valid*-1); hold off;
    title('Valid'); ylim([-1, 3]);
    
end

% Create timeseries object.
actValid = timeseries(valid, activity.time, 'Name', 'valid');
actValid.DataInfo.Unit  = 'binary';
actValid.TimeInfo.Units = 'minutes';

end