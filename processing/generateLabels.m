function labels = generateLabels(prefix, suffix) 
% generateLabels generates combinations of labels from prefix and suffix.  

% arguments
% - prefix:     cell with strings.
% - suffix:     cell with strings.

nPrefix = numel(prefix);
nSuffix = numel(suffix);
labels  = cell(1, nPrefix*nSuffix);

k = 1;

for iPrefix = 1:nPrefix
    
    for iSuffix = 1:nSuffix
       
    labels{k} = strcat(prefix{iPrefix}, suffix{iSuffix});    
        
    k = k + 1;
    
    end
        
end

labels = sprintf([repmat('%s, ', 1, nPrefix*nSuffix-1), '%s'], labels{:});

end
    