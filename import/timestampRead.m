function [id, subjectId, alarmLabels, alarmCounter, formLabels, alarmTimestamps] ...
    = timestampRead(filename)
% timestampRead loads a timestamp file containing the actual timestamps of the alarms.

format = '%q%q%q%q%q%q%q';
fid    = fopen(filename);
C      = textscan(fid, format, 'headerlines', 1, 'delimiter', ','); 
fclose(fid);

id              = str2double(C{1,1});
subjectId       = str2double(C{1,2});
alarmLabels     = C{1,3};
alarmCounter    = str2double(C{1,4});
formLabels      = C{1,5};
date            = datevec(C{1,6}, 'yyyy-mm-dd');
time            = datevec(C{1,7}, 'HH:MM:SS');
datetime        = [date(:, 1:3), time(:, 4:6)];
alarmTimestamps = datenum(datetime); 

end