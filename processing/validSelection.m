function selected = validSelection(inner, outer, startTime, endTime,...
    selInner, selOuter, selMax, N, plots)
% validSelection selects the inner or outer measurement based on the 
% validity of the measurement.
% Arguments:
%   inner     - Entire timeseries of the inner sensor.
%   outer     - Entire timesies of the outer senros.
%   startTime - Start time of the current period of interest.
%   endTime   - End time of the current period of interest.
%   selInner  - N-by-1 vector of 0,1 indicating the inner epoch selection.
%   selOuter  - N-by-1 vector of 0,1 indicating the outer epoch selection.
%   selMax    - N-by-1 vector of 0,1 indicating the max selection of both
%               sensors.
%   N         - Number of observations in the light measurement.
%
% selInner, selOuter, 

% Select the data.
innerData = getsampleusingtime(inner, startTime, endTime);
outerData = getsampleusingtime(outer, startTime, endTime);

% Light, temp and hum are sampled at different frequencies. To interpolate
% temp/hum with light. We need to know the number of light observations.

if (~isempty(selInner) && ~isempty(innerData.data)) && ...
        (~isempty(selOuter) && ~isempty(outerData.data))
    
    % Both inner and outer data is valid and present.
    
    % Select the data and interpolate if required.
    innerData = interpolateData(innerData, N, startTime, endTime);
    outerData = interpolateData(outerData, N, startTime, endTime);

    % Put the data side-by-side.
    nI = numel(innerData.data);
    nO = numel(outerData.data);
    N  = max([nI, nO]);

    % Pre-fill the matrix in case the data is of unequal
    % length. Zero indicates invalid data.
    dataIO = zeros(N, 2);
    dataIO(1:nI, 1) = innerData.Data;
    dataIO(1:nO, 2) = outerData.Data;

    % Fill selected with NaNs.
    selected = nan(N, 1);

    % Now select the relevant data...
    selected(selMax)   = max(dataIO(selMax, :), [], 2);
    selected(selInner) = dataIO(selInner, 1);
    selected(selOuter) = dataIO(selOuter, 2);
    
elseif (isempty(selInner) || isempty(innerData.data)) && ...
        (~isempty(selOuter) && ~isempty(outerData.data))
    
    % Inner cannot be used, use outer.

    % Select the data and interpolate if required.
    outerData = interpolateData(outerData, N, startTime, endTime);
    
    selected  = nan(numel(outerData.data), 1);
    selected(selOuter) = outerData.data(selOuter);

elseif (isempty(selOuter) || isempty(outerData.data)) && ...
        (~isempty(selInner) && ~isempty(innerData.data))

    % Outer cannot be used, use inner.
    
    % Select the data and interpolate if required.
    innerData = interpolateData(innerData, N, startTime, endTime);
     
    selected = nan(numel(innerData.data), 1);
    selected(selInner) = innerData.data(selInner);

else
    
    % Neither inner nor outer can be validly selected, so set to NaN.
    selected = nan(N,1);
    
end

if strcmpi(plots, 'on')
    
    plotMax   = zeros(N,1);
    plotMax(selMax) = 1;
    plotInner = zeros(N,1);
    plotInner(selInner) = 1;
    plotOuter = zeros(N,1);
    plotOuter(selOuter) = 1;   
    
    figure()
    subplot(4,1,1);
    bar(innerData.data, 'r');
    title('Inner');
    
    subplot(4,1,2);
    bar(outerData.data, 'b');
    title('Outer');
    
    subplot(4,1,3);
    bar(plotMax, 'b'); hold on; bar(plotInner, 'r'); bar(plotOuter, 'b'); hold off;
    title('Selection');
    
    subplot(4,1,4);
    bar(selected);
    title('Final selection');
end

end

function [newData] = interpolateData(data, samples, startTime, endTime)
% Check if the selOuter and outerData are of equal length, if not
% interpolate by creating new timestamps of length(selOuter).

if ~isequal(length(data.data), samples)
    
    % Correct for the fact that 5 min will only sample a single hum/temp
    % sample (sampled every 3 min).
    if length(data.data) == 1
        
        % Fill all samples with a single value.
        newData = timeseries;
        newData.data = ones(samples,1)*data.data(1);
        %newData.time = interp1(1:2, [startTime, endTime], linspace(1, 2, samples))'
        
    else
        % Suppress warning that extrapolation doesn't work.
        warning('off', 'MATLAB:linearinter:noextrap');
        
        % Interpolate the series with new timestamps.
        newTime = interp1(1:2, [startTime, endTime], linspace(1, 2, samples))';
        newData = resample(data, newTime);
    
         warning('on', 'MATLAB:linearinter:noextrap'); % restore warning state.
    end
    
else
    
    % The data stays as it is...
    newData = data;

end 
end