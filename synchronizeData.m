% SYNCHRONIZEDATA loads data from all the ambulatory files 
%
% Complete data will include the following files:
%   wrist - acc.bin, press.bin, temp.bin, tempskin.bin
%   thigh - acc.bin, press.bin, temp.bin, tempskin.bin
%   chest - ecg.bin, acc.bin, press.bin, temp.bin, tempskin.bin
%   philips - contact, ir
%   ibutton - coat, sweater
%   dimesimeter - coat, sweater
%
% Copyright (c) 2014 Bart te Lindert



% add path to unisens, // install

% Get 20 minute periods of data around the phone alarms:
% - Thigh:      ACC, PRESS, SKINTEMP
% - Wrist:      ACC, PRESS, SKINTEMP
% - Chest:      ACC, PRESS, SKINTEMP, ECG
% - Finger:     SKINTEMP
% - Sweater:    LIGHT, HUMIDITY, TEMP
% - Coat:       LIGHT, HUMIDITY, TEMP

% path: /data1/recordings/btmn/subjects/[subjID]/actigraphy/raw
PATH = '/data1/recordings/btmn/';

SUBJECTS = 1:100;


% Load alarmstamps.
% Loading data and generating timestamps takes most time, so perform once.
% Loop through all alarms.
% For each alarm, process with functions:
%   - posture(data)
%   - activity(data)
%   - energyExpenditure(data)
%   - light(data)
%   - humidity(data)
%   - temperatureOscillations(data)
%   - temperatureMean(data)
%   - hrv(data)


% SYNCHRONIZATION
% All the datasets differ in sampling frequency, most are continuous
% timeseries, but some are intermittent (finger_ir), so the first thing we
% do is synchronize all the datasets to a common series of timestamps

CHEST_ECG      = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_chest_ecg.bin'];
CHEST_PRESS    = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_chest_press.bin'];
CHEST_TEMPSKIN = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_chest_tempskin.bin'];

WRIST_ACC      = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_wrist-left_acc.bin'];
WRIST_PRESS    = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_wrist-left_press.bin'];
WRIST_TEMPSKIN = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_wrist-left_tempskin.bin'];

THIGH_ACC      = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_thigh-left_acc.bin'];
THIGH_PRESS    = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_thigh-left_press.bin'];
THIGH_TEMPSKIN = [INPUT_DIR 'btmn_' SUBJECT '_actigraphy_thigh-left_tempskin.bin'];

IBUTTON_SWEATER = [INPUT_DIR 'btmn_' SUBJECT '_temperature_sweater.txt'];
IBUTTON_COAT    = [INPUT_DIR 'btmn_' SUBJECT '_temperature_coat.txt'];


PHILIPS_IR      = [INPUT_DIR 'btmn_' SUBJECT '_temperature_finger_ir.txt'];
PHILIPS_CONTACT = [INPUT_DIR 'btmn_' SUBJECT '_temperature_finger_contact.txt'];


%[luxCoat luxSweater] = synchronize(luxCoat, luxSweater, 'Uniform', 'Interval', 1);

% load ibutton data from coat and sweater, sampling is 3 minutes
tempCoat    = ibutton.ibuttonRead(IBUTTON_COAT);
tempSweater = ibutton.ibuttonRead(IBUTTON_SWEATER);

%[tempCoat tempSweater] = synchronize(tempCoat, tempSweater, 'Uniform', 'Interval', 1);

% load movisens data from thigh, wrist, and chest
accChest      = movisens.movisensRead(CHEST_ACC);
ecgChest      = movisens.movisensRead(CHEST_ECG);
pressChest    = movisens.movisensRead(CHEST_PRESS);
tempskinChest = movisens.movisensRead(CHEST_TEMPSKIN);

accWrist      = movisens.movisensRead(WRIST_ACC);
pressWrist    = movisens.movisensRead(WRIST_PRESS);
tempskinWrist = movisens.movisensRead(WRIST_TEMPSKIN);

accThigh      = movisens.movisensRead(THIGH_ACC);
pressThigh    = movisens.movisensRead(THIGH_PRESS);
tempskinThigh = movisens.movisensRead(THIGH_TEMPSKIN);

% load philips-temp data from the finger, both ir and contact
skintempFingerContact = philips-temp.philipstempRead(PHILIPS_CONTACT);
skintempFingerIR      = philips-temp.philipstempRead(PHILIPS_IR);

% once all the data is loaded, start cutting the timestamps
% load all timestamps from the original program. 
% some triggers might be missing, but can be used for other analyses

% Load timestamps from the text file.


% Loop through all subjects.
for iSubject = 1:100
   
    subj = sprintf('%04.0f', iSubject);    
    
    % Load all the timestamps for this subject.
    timestamps = movisens.movisensTimestampsRead(filename);
    
    
    
    
    %% SKIN TEMPERATURE: PROX, DIST, DPG, OSCILLATIONS
    
    % Thigh, chest, wrist and finger average.
    % Finger oscillations.

    %% AMBIENT LIGHT: MEAN
    DIMESIMETER_SWEATER = [INPUT_DIR 'btmn_' SUBJECT '_ambient-light_sweaterprocessed.txt'];
    DIMESIMETER_COAT    = [INPUT_DIR 'btmn_' SUBJECT '_ambient-light_coatprocessed.txt'];

    % load dimesimeter data from coat and sweater, sampling is 3 minutes
    [luxCoat, actCoat]       = dimesimeter.dimesimeterRead(DIMESIMETER_COAT);
    [luxSweater, actSweater] = dimesimeter.dimesimeterRead(DIMESIMETER_SWEATER);

    % Mean lux.
    % RBG spectrum.

    %% AMBIENT HUMIDITY: MEAN
    % Mean percentage of coat/sweater.

    %% AMBIENT TEMPERATURE: MEAN
    % Mean temperature of coat/sweater.

    %% AMBIENT PRESSURE: MEAN
    % Mean hPa
    % do
        

end
