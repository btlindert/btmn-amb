clear all; close all; clc;

% rootDir = 'D:\data\movisens\EusiButtonIR 130910';
rootDir = 'D:\data\movisens\BartiButtonIR 130920\';

% 1 minute sampling for the ibutton
fs = 2;

% load left data
% ibuttonLeft = xlsread([rootDir '\iButtonData.xlsx'], 'EusLeft');
% movisensLeft = unisens_get_data([rootDir '\EusLeftRing'], 'tempskin.bin', 'all')./100;
ibuttonLeft = xlsread([rootDir '\iButtonData.xlsx'], 'BartLeft');
ibuttonLeft = ibuttonLeft(:,1);
movisensLeft = unisens_get_data([rootDir '\BartLeft'], 'tempskin.bin', 'all')./100;

minutes = floor(numel(movisensLeft)/(60*fs));
temp = reshape(movisensLeft(1:minutes*60*fs), (60*fs), minutes);
movisensLeftMins = mean(temp,1);
x = (1:numel(movisensLeft))./(fs*60);
% xmax = 2000;
xmax = 4000;

% raw data plot
figure(1)
subplot(3,2,1)
plot(movisensLeftMins); hold on;
plot(ibuttonLeft, 'r'); hold on;
plot(x, movisensLeft, 'g'); 
title('Left (ring)')
xlabel('minutes')
ylabel('temperature (C)')
% legend('movisens min avg', 'ibutton', 'movisens raw');
xlim([0 xmax]);
ylim([28 36]);

diff = movisensLeftMins(1:xmax)'-ibuttonLeft(1:xmax);
meaner = mean([movisensLeftMins(1:xmax)' ibuttonLeft(1:xmax)], 2);

% difference over time
figure(1)
subplot(3,2,3)
plot(diff); 
xlabel('minutes')
ylabel('difference (C)')
ylim([-2 2])
grid on;

% bland-altman
figure(1)
subplot(3,2,5)
plot(meaner, diff); 
xlabel('mean (C)')
ylabel('difference (C)')
ylim([-4 4])
grid on;

%% load right data
% ibuttonRight= xlsread([rootDir '\iButtonData.xlsx'], 'EusRight');
% movisensRight = unisens_get_data([rootDir 'EusRight'], 'tempskin.bin', 'all')./100;
ibuttonRight= xlsread([rootDir '\iButtonData.xlsx'], 'BartRight');
ibuttonRight = ibuttonRight(:,1);
movisensRight = unisens_get_data([rootDir 'BartRightRing'], 'tempskin.bin', 'all')./100;
minutes = floor(numel(movisensRight)/(60*fs));
temp = reshape(movisensRight(1:minutes*60*fs), (60*fs), minutes);
movisensRightMins = mean(temp,1);
x = (1:numel(movisensRight))./(fs*60);

% raw data plot
figure(1)
subplot(3,2,2)
plot(movisensRightMins); hold on;
plot(ibuttonRight, 'r'); hold on;
plot(x, movisensRight, 'g');
title('Right')
xlabel('minutes')
ylabel('temperature (C)')
% legend('movisens avg', 'ibutton', 'movisens raw');
xlim([0 xmax]);
ylim([28 36]);
diff = movisensRightMins(1:xmax)'-ibuttonRight(1:xmax);
meaner = mean([movisensRightMins(1:xmax)' ibuttonRight(1:xmax)], 2);

% difference over time
figure(1)
subplot(3,2,4)
plot(diff); 
xlabel('minutes')
ylabel('difference (C)')
ylim([-2 2])
grid on;

% bland-altman plots
figure(1)
subplot(3,2,6)
plot(meaner, diff);
xlabel('mean (C)')
ylabel('difference (C)')
ylim([-4 4])
grid on;
