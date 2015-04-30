function data = actvity(iSubject, alarms) 
% Activity estimation based on XXX acc data.


% Subject string id.
iSubjectStr = sprintf('%04.0f', iSubject);

% Create filenames.
CHEST_ACC = ['btmn_' iSubjectStr '_actigraphy_chest_acc.bin'];
CHEST_XML = ['btmn_' iSubjectStr '_actigraphy_chest_unisens.xml'];
WRIST_ACC = ['btmn_' iSubjectStr '_actigraphy_wrist-left_acc.bin'];
WRIST_XML = ['btmn_' iSubjectStr '_actigraphy_wrist-left_unisens.xml'];
THIGH_ACC = ['btmn_' iSubjectStr '_actigraphy_thigh-left_acc.bin'];
THIGH_XML = ['btmn_' iSubjectStr '_actigraphy_thigh-left_unisens.xml'];

% Generate symbolic links on the fly in a /tmp folder.
% Unisens data can only be loaded with the toolbox if the filenames are
% acc|ecg|press|temp|tempskin.bin and in the same folder as the
% unisens.xml.
status = system(['ln -s ' UNISENS_FOLDER CHEST_XML ' ',...
    SIMLINK_FOLDER 'unisens.xml']);
status = system(['ln -s ' UNISENS_FOLDER CHEST_ACC ' ',...
    SIMLINK_FOLDER 'acc.bin']);

accChest = unisens_get_data(SIMLINK_FOLDER, 'acc.bin', 'all');

% Load chest acc data.
status = system(['ln -s ' UNISENS_FOLDER WRIST_XML ' ',...
    SIMLINK_FOLDER 'unisens.xml']);
status = system(['ln -s ' UNISENS_FOLDER WRIST_ACC ' ',...
    SIMLINK_FOLDER 'acc.bin']);

accWrist = unisens_get_data(SIMLINK_FOLDER, 'acc.bin', 'all');

% Load thigh acc data.
status = system(['ln -s ' UNISENS_FOLDER THIGH_XML ' ',...
    SIMLINK_FOLDER 'unisens.xml']);
status = system(['ln -s ' UNISENS_FOLDER THIGH_ACC ' ',...
    SIMLINK_FOLDER 'acc.bin']);

% Load acc data.
accThigh = unisens_get_data(SIMLINK_FOLDER, 'acc.bin', 'all');



% Extract start time from the unisens.xml file.
str       = movisens.movisensXmlRead([SIMLINK_FOLDER 'unisens.xml']); 
startTime = str.Attributes(4).Value;
startTime = datenum(startTime, 'yyyy-mm-ddTHH:MM:SS.FFF'); % note T in the middle!

% Add event to timeseries objects and loop through events?????

% Loop through all alarms, to estimate posture, activity.
for iTrigger = 1:nTriggers


    % Use wrist data to estimate activity/energy expenditure.
    % - call function activity(accWrist) -> validated in movisens
    % paper?

    % Use chest and thigh data to estimate posture.
    % - call function posture(accThigh, accChest)

    % Select data around the trigger, 15min before, 5min after
    trigger   = datenum(time);
    starttime = addtodate(trigger, -15, 'minute');
    endtime   = addtodate(trigger, 5, 'minute');
    data      = getsampleusingtime(ts, starttime, endtime);


end