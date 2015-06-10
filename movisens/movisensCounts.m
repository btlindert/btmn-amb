function act = movisensCounts(ts)
% movisensCounts converts accelerometry recorded from the wrist with a
% MoveII sensor to actigraphy counts that are used to estimate sleep
% parameters.

% Fixed sampling frequency.
fs = 64;

% Get ts data.
data = ts.Data;
time = ts.Time;

% Set filter specifications.
cf_low = 3;               % lower cut off frequency (Hz)
cf_hi  = 11;              % high cut off frequency (Hz)
order  = 5;               % filter order
pass   = 'bandpass';      % filter type
w1     = cf_low/(fs/2);   % normalized frequency low
w2     = cf_hi/(fs/2);    % normalized frequency high
[b, a] = butter(order, [w1 w2], pass); 

% Filter data.
z_filt = filtfilt(b, a, data); 

% Convert data to 128 bins between 0 and 5
z_filt = abs(z_filt);
topEdge = 5;
botEdge = 0; 
numBins = 128; 

binEdges    = linspace(botEdge, topEdge, numBins+1);
[~, binned] = histc(z_filt, binEdges);

% Convert to 15 sec counts/epoch.
epoch = 15;
counts = max2epochs(binned, fs, epoch);

% NOTE: Please be aware that the algorithm used here has only been
% validated for 15 sec epochs and 50 Hz raw accelerometery (palmar-dorsal
% z-axis data. The formula (1) used below
% is based on these settings. The longer the epoch, the higher the
% constant offset/residual noise will be (18 in this case). Sampling frequencies 
% will probably affect the constant offset less. However, due 
% to the band-pass of 3-11 Hz used above and human movement frequencies 
% of up to 10 Hz, a sampling of less than 30 Hz is not reliable.

% Subtract constant offset and multiply with factor for distal location.
counts = (counts-18).*3.07;                   % ---> formula (1)

% Set any negative values to 0.
indices = counts < 0;
counts(indices) = 0;

% Create a new time series for the epoch data.
newTime    = zeros(size(counts));
newTime(1) = datenum(time(1));

for i = 2:numel(newTime)

    newTime(i) = datenum(addtodate(newTime(i-1), 15, 'second'));

end

% Create timeseries.
act = timeseries(counts, 'Name', 'ACT');
act.DataInfo.Unit  = 'counts';
act.TimeInfo.Units = 'seconds';

% Create a uniform timeseries based on the start time and the epoch duration
% make sure the TimeInfo.Units of ts1 has already been set to seconds. 
act = set(act, 'Time', newTime);

end