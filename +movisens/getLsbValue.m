function lsbValue = getLsbValue(str)
% getLsbValue gets the lsbValue for the 'acc' channel.

for iChild = 1:size(str.Children, 2)
    
    % Find the 'signalEntry' channels.
    if strcmpi(str.Children(iChild).Name, 'signalEntry')
       
        % Loop through all 'Attributes' to find value = 'acc'.
        for iAttribute = 1:size(str.Children(iChild).Attributes, 2)
            
            if strcmpi(str.Children(iChild).Attributes(iAttribute).Value, 'acc');
               
               % If found, loop through all 'Attributes' again to find the 
               % .Name = lsbValue ...
               for jAttribute = 1:size(str.Children(iChild).Attributes, 2)
                   
                   if strcmpi(str.Children(iChild).Attributes(jAttribute).Name, 'lsbValue')
                       
                       % ... and extract the corresponding value.
                       lsbValue = str.Children(iChild).Attributes(jAttribute).Value;
                       lsbValue = str2double(lsbValue);
                       
                       return
                       
                   end

               end
 
            end  
            
        end
        
    end
    
end