function selected = validSelection(inner, outer, startTime, endTime,...
    selInner, selOuter, selMax, plots)

% validSelection selects the actual valid measurement from inner and outer.

if ~isempty(outer) && ~isempty(selOuter)
 
    % Select the outer data
    outerData = getsampleusingtime(outer, startTime, endTime);
    
    % Check if the selOuter and outerData are of equal length, if not
    % interpolate by creating new timestamps of lenght(selOuter).
    if ~isequal(length(outerData.data), length(selOuter)) 
        % Create new time series object.
        ts1 = timeseries;
        ts1.data = selOuter;
        ts1.time = setuniformtime(ts1, 'Starttime', startTime, 'EndTime', endTime);
        outerData = resample(outerData, ts1.time);
    else
        % outerData stays as it is...
    end  
end



if ~isempty(inner) && ~isempty(selInner)
 
    % Select the outer data
    innerData = getsampleusingtime(inner, startTime, endTime);
    
    % Check if the selOuter and outerData are of equal length, if not
    % interpolate by creating new timestamps of lenght(selOuter).
    if ~isequal(length(innerData.data), length(selInner)) 
        % Create new time series object.
        ts1 = timeseries;
        ts1.data = selInner;
        ts1.time = setuniformtime(ts1, 'Starttime', startTime, 'EndTime', endTime);
        innerData = resample(innerData, ts1.time);
    else
        % outerData stays as it is...
    end  
end


if isempty(inner)

    % Select the outer data
    selected  = nan(numel(outerData.data), 1);
    selected(selOuter) = outerData.data(selOuter);

elseif isempty(outer)

    % Select the inner data.
    selected = nan(numel(innerData.data), 1);
    selected(selInner) = innerData.data(selInner);
    
else
    
    % Select the data for this alarm.

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
