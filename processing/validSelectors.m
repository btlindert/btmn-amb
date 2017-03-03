function [selInner, selOuter, selMax] = validSelectors(validInner, validOuter,...
    startTime, endTime, plots)     

if isempty(validInner) && isempty(validOuter)
    
    return

elseif isempty(validInner)
    
    % Select Outer valid data.
    validO      = getsampleusingtime(validOuter, startTime, endTime);
    validI.data = [];
    selInner    = []; 
    selOuter    = find(validO.data == 1);
    selMax      = [];
    
elseif isempty(validOuter)
    
    % Select Inner valid data.
    validO.data = [];
    validI      = getsampleusingtime(validInner, startTime, endTime);
    selInner    = find(validI.data == 1); 
    selOuter    = [];
    selMax      = [];
    
else
    
    % Select valid data.
    validI = getsampleusingtime(validInner, startTime, endTime);
    validO = getsampleusingtime(validOuter, startTime, endTime);  
    
    % Put the data side-by-side.
    nI = numel(validI.data);
    nO = numel(validO.data);
    N  = max([nI, nO]);

    % Paste all data to NaN matrix, in case data is not available
    % for equal duration.
    validIO = nan(N, 2);
    validIO(1:nI, 1) = validI.Data;
    validIO(1:nO, 2) = validO.Data;

    % Find indices that correspond with selection criteria. 

    % All lux = NaN, unless...
    % If actInnerValid == 1 AND actOuterValid == 0, 
    % pick inner sensor.
    selInner = find(validIO(:,1) == 1 & validIO(:,2) == 0);

    % If actInnerValid == 0 AND actOuterValid == 1,
    % pick outer sensor.
    selOuter = find(validIO(:,1) == 0 & validIO(:,2) == 1);

    % If actInnerValid == 1 AND actOuterValid == 1 
    % pick max value of both sensors.
    selMax = find(validIO(:,1) == 1 & validIO(:,2) == 1);

end    
         
if strcmpi(plots, 'on')
    
    figure()
    subplot(2,1,1)
    bar(validI.data); title('Inner valid');
    subplot(2,1,2)
    bar(validO.data); title('Outer valid');

end
end