SUBJECT    = 33; 
START_DATE = '5-11-2014'; % mm-dd-yyyy

%% PATHS
INPUT_FOLDER  = '/Users/me/Data/ukcaa/phone_timestamps/';
OUTPUT_FOLDER = INPUT_FOLDER;

%% LOAD TIMESTAMPS
load([INPUT_FOLDER sprintf('%04.0f', SUBJECT) '_ATPL_timestamps.mat'])

%% WRITE DAY + NIGHT TIMESTAMPS TO -TXT FILE
fid = fopen([OUTPUT_FOLDER sprintf('%04.0f', SUBJECT) '_ATPL_timestamps_Temperature.txt'], 'w');

% convert to column vector [trig*days-by-1] for writing to file 
timestamps = reshape(timestamps, numel(timestamps),1);

% subtract 15 minutes from each timestamp to have temperature sensor
% start early relative to phone
for q = 1:numel(timestamps)
   timestamps(q) = addtodate(timestamps(q), -15, 'minute');
end

% change timestamps
newDates(1) = datenum(START_DATE, 'dd-mm-yyyy'); 
for k = 2:numel(timestamps)
    if strcmpi(datestr(timestamps(k), 'dd-mm-yyyy'), datestr(timestamps(k-1), 'dd-mm-yyyy'))
        newDates(k) = newDates(k-1);
    else
        newDates(k) = addtodate(newDates(k-1), 1, 'day');
    end  
end

% write stamps to txt file
% format should be dd-mm-yyyy (H)H:MM without the leading zeros!
% datestr alsways includes the leading zero, so HH is converted to a
% number and then back to a string to remove the 0.
for j = 1:numel(timestamps)
    fprintf(fid, '%s\r\n', [datestr(newDates(j), 'dd-mm-yyyy') ' ',...
        num2str(str2double(datestr(timestamps(j), 'HH'))) ':' datestr(timestamps(j), 'MM')]);
end

% close the file 
fclose(fid);

    