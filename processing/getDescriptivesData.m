function [iqrVal, maxVal, meanVal, medianVal, minVal, stdVal, sumVal, varVal] = getDescriptivesData(data)
% getMeanData calculates the mean of the data (ts object). 
% If data is not empty, else it's a NaN.

% Extract features.
if ~isempty(data.Data)

    iqrVal    = iqr(data, 'MissingData', 'remove');
    maxVal    = max(data, 'MissingData', 'remove');
    meanVal   = mean(data, 'MissingData', 'remove');
    medianVal = median(data, 'MissingData', 'remove');
    minVal    = min(data, 'MissingData', 'remove');
    stdVal    = std(data, 'MissingData', 'remove');
    sumVal    = sum(data, 'MissingData', 'remove');
    varVal    = var(data, 'MissingData', 'remove');
    
else % NaN.

    iqrVal    = NaN;
    maxVal    = NaN;
    meanVal   = NaN;
    medianVal = NaN;
    minVal    = NaN;
    stdVal    = NaN;
    sumVal    = NaN;
    varVal    = NaN;
    
end

end