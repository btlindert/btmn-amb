function [ave, sd, car, res, myo, neu, noDep, noInDep] = ...
    temperatureAnalysis(data)
% temperatureAnalysis calculates the power of the oscillations in specific
% regions of the powerspectrum related to thermoregulatory control.

% Arguments:
%   data - Input data timeseries
%
% Results:
%   noi  - NO-independent endothelial activity (0.005-0.0095 Hz)
%   nod  - NO-dependent endothelial activity (0.0095-0.021 Hz)
%   neu  - neurogenic (0.021-0.052 Hz)
%   myo  - myogenic (0.145-0.052 Hz)
%   res  - respiratory (0.145-0.6 Hz)
%   car  - cardiac (0.6-2.0 Hz)
%
% TODO:
%   - Add ref:
%   - Optimize pwelch
%   - Select peak frequency power per band.
%   
% Copyright (c) 2014 Bart te Lindert.

% Average and standard deviation.

ave = mean(data);
sd  = std(data);

% Sampling frequency of the data. 
% Movisens moveII, ekgMove and the finger sensor all sample at 2Hz.
% Data is sampled for 20 minutes around each alarm, 15min pre, 5 min during
% the questionnaire.
fs = 2;

% Detrend the data.
data = detrend(data);

% Create power spectral density using Welch' method
window  = 2^10;%%%%%%% optimize, reduce to 2048 samples, 2^x?
[Pxx,f] = pwelch(data, window, window/2, window, fs);

% Select the peak oscillation at the relevant intervals.
% 0.0095, 0.021, 0.052, 0.1452, 0.6, 1.0)
semilogy(f, Pxx);



