function [ecgLsbValue, accLsbValue, tempskinLsbValue, tempLsbValue, ...
    pressLsbValue] = movisensGetLsbValue(str)
% getLsbValue gets the lsbValues for all channels.
% ecgLsbValue is only present in ekgMove xml files. Specify as empty to
% avoid errors for moveII files.
ecgLsbValue = [];

for iChild = 1:size(str.Children, 2)
    
    % Find the 'signalEntry' channels.
    if strcmpi(str.Children(iChild).Name, 'signalEntry')
       
        nAttributes = size(str.Children(iChild).Attributes, 2);
        
        % Loop through all 'Attributes' of 'signalEntry'.
        for iAttribute = 1:nAttributes
            
            if strcmpi(str.Children(iChild).Attributes(iAttribute).Value, 'ecg.bin');
               
               % lsbValue always comes after the id. 
               ecgLsbValue = str.Children(iChild).Attributes(iAttribute+1).Value;
               ecgLsbValue = str2double(ecgLsbValue);
            
            elseif strcmpi(str.Children(iChild).Attributes(iAttribute).Value, 'acc.bin');
               
               accLsbValue = str.Children(iChild).Attributes(iAttribute+1).Value;
               accLsbValue = str2double(accLsbValue);
                       
            elseif strcmpi(str.Children(iChild).Attributes(iAttribute).Value, 'tempskin.bin');
               
               tempskinLsbValue = str.Children(iChild).Attributes(iAttribute+1).Value;
               tempskinLsbValue = str2double(tempskinLsbValue);  
            
            elseif strcmpi(str.Children(iChild).Attributes(iAttribute).Value, 'temp.bin');
               
               tempLsbValue = str.Children(iChild).Attributes(iAttribute+1).Value;
               tempLsbValue = str2double(tempLsbValue);
            
            elseif strcmpi(str.Children(iChild).Attributes(iAttribute).Value, 'press.bin');
                
               pressLsbValue = str.Children(iChild).Attributes(iAttribute+1).Value;
               pressLsbValue = str2double(pressLsbValue);
            
            end
            
        end
        
    end
    
end