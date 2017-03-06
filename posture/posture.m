function [modeClassification, secUndefined, secUpright, secStanding, secSitting, secSupine, ...
    secRight, secProne, secLeft, secDynamic] = posture(dataChest, dataThigh, plots)
% POSTURE classifies posture based on the inclination of the thigh and
% chest sensors using a fixed threshold classification algorithm by Lugade
% 2014 169.

% Arguments:
%   chestData - [N-by-3] matrix with chest x,y,z accelerometry.
%   thighData - [N-by-3] matrix with thigh x,y,z accelerometry. 
%   plots     - 'on' or 'off' (default). 
%
% Results:
%   classification - Vector with classification number per second.
%       0 - dynamic
%       1 - lying right
%       2 - prone
%       3 - lying left
%       4 - supine
%       5 - sitting
%       6 - standing
%       7 - undefined
%
% Copyright (c) 2015 Bart te Lindert
    
dataChest = [dataChest.ACCX.Data, dataChest.ACCY.Data, dataChest.ACCZ.Data];
dataThigh = [dataThigh.ACCX.Data, dataThigh.ACCY.Data, dataThigh.ACCZ.Data];

%% Chest
% In upright posture, the axes are oriented as follows relative to gravity:
%   x - vertical
%   y - lateral
%   z - anterior/posterior
%  +ve x-axis is downward in normal placement, so any angle should be
%  calculated relative to [1, 0, 0].
%  Leaning forward and backward movement is a rotation around the y-axis 
%  in the (x, z) plane.
gChestUpright = [1, 0, 0];

% In supine posture, the axes are oriented as follows relative to gravity:
%   x - anterior/posterior
%   y - lateral
%   z - vertical
%  +ve z-axis is downward in normal placement, so any angle should be
%  calculated relative to [0, 0, 1].
%  Tranverse rotation is therefore rotation around the x-axis in the (y, z) 
% plane.
% gChestSupine = [0, 0, 1];

% Let's start by calculating the angles.
chestAngle3D = zeros(size(dataChest, 1), 1);
chestTransverseAngle2D = zeros(size(dataThigh, 1), 1);

for i = 1:size(dataChest, 1)

    % First we calculate the inclination of the chest sensor. We assume an
    % angle relative to [1,0,0] close to 0 in upright posture, and near 90 
    % in supine posture. This angle is in 3 dimensions. 
    chestAngle3D(i) = atan2(norm(cross(dataChest(i, :), gChestUpright)), ...
        dot(dataChest(i, :), gChestUpright))./pi*180;

    % Once a subject is in supine posture, we want to calculate the transverse 
    % angle to estimate supine, prone, lying left or right. To get an angle 
    % between 0 and 360 we reduce the problem to 2D. We assume [0,0,1] in
    % supine posture i.e. [0,1] (y,z) in 2D:
    y1 = 0;
    z1 = 1;
    y2 = dataChest(i,2);
    z2 = dataChest(i,3);
    chestTransverseAngle2D(i) = mod(atan2(y1*z2 - y2*z1, y1*y2 + z1*z2), 2*pi)./pi*180;   

end

%% Thigh 
% In upright posture, the axes are oriented as follows relative to gravity:
%  x - vertical
%  y - anterior/posterior
%  z - lateral
% +ve x-axis is downward in normal placement, the angle should be
% calculated relative to [1, 0, 0].
% Forward and backward movement of the legs means rotation around the z-axis 
% in the x,y plane).
gThighUpright = [1, 0, 0];

for i = 1:size(dataThigh, 1)
    
    % We calculate the inclination of the thigh sensor. We assume an
    % angle relative to [1,0,0] close to 0 in upright posture, and near 90 
    % in supine or sitting posture. This angle is in 3 dimensions.  
    thighAngle3D(i) = atan2(norm(cross(dataThigh(i, :), gThighUpright)), ...
        dot(dataThigh(i, :), gThighUpright))./pi*180;
    
end

%% Median filter.
% Median filter data : window size of 3 to each of the raw acc signals.
dataChest = medfilt1(dataChest, 3);
dataThigh = medfilt1(dataThigh, 3);

%% Signal vector magnitude.
% Of the chest sensor.
svmChest = sqrt(dataChest(:,1).^2 + dataChest(:,2).^2 + dataChest(:,3).^2);

%% Low-pass filter
% 3rd order zero phase lag elliptical low pass filter, cut-off 0.25 Hz,
% 0.01 dB passband ripple and -100 dB stopband ripple.
fs    = 64;
order = 3;
Rp    = 0.01;
Rs    = 100;
Wp    = 0.25/(fs/2);
ftype = 'low';
[b, a] = ellip(order, Rp, Rs, Wp, ftype);

gravitationChest  = filter(b, a, dataChest);
bodilyMotionChest = dataChest - gravitationChest;

%% Signal magnitude area.
% The bodily motion component was utilized in determining static versus 
% dynamic activity, with signal magnitude area (SMA) values above a 
% threshold of 0.135g identified as movement [19]. The signal magnitude area 
% was computed over each 1 s window (t) across all three orthogonal axes 
% (ax, ay, az).
seconds = floor(size(bodilyMotionChest, 1)/fs);
data = bodilyMotionChest(1:seconds*fs,:);
data = reshape(data, [fs seconds 3]);

% Calculate SMA across each second, first across fs, then across all 3
% axes and divide by sampling rate.
SMA = sum(sum(abs(data), 1), 3)./fs;

%% Continuous wavelet transform.
% Daubechies 4 mother wavelet on waist/chest signal. If data in range
% 0.1-2.0 Hz has scaling threshold > 1.5 it is movement.
wname = 'db4';
data = svmChest;
delta = 1/fs;
Fc = centfrq(wname);
Fmin = 0.1;
Fmax = 2;
minScale = Fc/(Fmin*delta);
maxScale = Fc/(Fmax*delta);
scales = 20:20:460;
coefs = cwt(data, scales, wname);
CWT = max(abs(coefs));
freq = scal2frq(scales, wname, delta);

%% Classification
% Per second.
for i = 1:fs:seconds*fs;
    
    sec      = floor((i+fs-1)/fs);
    sma      = SMA(sec);
    cwtt     = max(CWT(i:i+fs-1));
    chestA   = mean(chestAngle3D(i:i+fs-1));
    chestTA  = mean(chestTransverseAngle2D(i:i+fs-1));
    thighA   = mean(thighAngle3D(i:i+fs-1));
   
    % Static vs dynamic based on chest data.
    if sma > 0.135 
        
        movement = 'dynamic';
        
    elseif sma <= 0.135    
        % Relabel to static movement.
        movement = 'static';
        
        if cwtt > 1.5
            % Relabel static back to dynamic.
            movement = 'dynamic';
    
        end
        
    else 
        
        movement = 'undefined';
        
    end

    if strcmpi(movement, 'static')
    % Static orientation.
        if chestA < 50 || chestA > 130
            
            oneSensorClassification(sec) = 7; % upright = standing/sitting
            
            % Upright || Inverted
            if thighA < 45 || thighA > 135
                % Upright || Inverted
                twoSensorClassification(sec) = 6; % standing
            elseif thighA >= 45 && thighA <= 135
                twoSensorClassification(sec) = 5; % sitting
            else
                twoSensorClassification(sec) = 8; % undefined
            end
            
        elseif chestA >= 50 && chestA <= 130 
        % Lying down.
        % Chest sensor inversion has no effect on the transverse angle.
            if chestTA < 45 || chestTA >= 315
                oneSensorClassification(sec) = 4; % supine
            elseif chestTA >= 45 && chestTA < 135
                oneSensorClassification(sec) = 3; % right
            elseif chestTA >= 135 && chestTA < 225
                oneSensorClassification(sec) = 2; % prone
            elseif chestTA >= 225 && chestTA < 315
                oneSensorClassification(sec) = 1; % left  
            else 
                oneSensorClassification(sec) = 8; % undefined
            end
        else
            % Undefined.
            oneSensorClassification(sec) = 8; % undefined
        end
    elseif strcmpi(movement, 'dynamic')
        
        oneSensorClassification(sec) = 0; % dynamic
    
    elseif strcmpi(movement, 'undefined')
        
        oneSensorClassification(sec) = 8; % undefined.
    
    end
end

%% Mode posture.
% Choose the most frequently occuring posture.
modeClassification = mode(oneSensorClassification);


%% Seconds in each posture.
% Calculate percentages in R: if timeSlot duration changes, % calc can be
% easily changed in R.
secUndefined = length(find(oneSensorClassification == 8));
secUpright   = length(find(oneSensorClassification == 7));
secStanding  = length(find(twoSensorClassification == 6));
secSitting   = length(find(twoSensorClassification == 5));
secSupine    = length(find(oneSensorClassification == 4));
secRight     = length(find(oneSensorClassification == 3));
secProne     = length(find(oneSensorClassification == 2));
secLeft      = length(find(oneSensorClassification == 1));
secDynamic   = length(find(oneSensorClassification == 0));

%% Plots
if strcmpi(plots, 'on')

    figure(1);
    subplot(11,1,1)
    plot(dataChest);
    axis tight
    ylim([-2, 2]);
    title('chest raw data');
    legend('x', 'y', 'z');

    subplot(11,1,2)
    plot(chestAngle3D);
    axis tight
    ylim([0, 180]);
    title('chest saggital angle');
    legend('3D');
    set(gca, 'YTick', [0, 50, 130, 180]);
    grid on

    subplot(11,1,3);
    plot(chestTransverseAngle2D, 'r');
    title('chest transvers angle');
    axis tight
    ylim([0 360]);
    legend('2D');
    set(gca, 'YTick', [0, 45, 135, 225, 315, 360]);
    grid on

    subplot(11,1,4)
    plot(bodilyMotionChest);
    title('chest bodily motion');
    axis tight

    subplot(11,1,5);
    plot(SMA); hold on;
    plot([1 length(SMA)], [0.135 0.135], 'g'); hold off;
    title('chest SMA'); 
    axis tight
    ylim([0, 1]);

    subplot(11,1,6);
    contourf(1:numel(data), freq, coefs);
    axis tight
    title('chest CWT');

    subplot(11,1,7);
    plot(CWT); hold on;
    plot([1 length(CWT)], [1.5 1.5], 'g'); hold off;
    axis tight
    title('chest scaling');
    ylim([0, 5]);

    subplot(11,1,8);
    plot(dataThigh);
    title('thigh raw data');
    axis tight
    ylim([-2, 2]);

    subplot(11,1,9)
    plot(thighAngle3D);
    title('thigh saggital angle');
    axis tight
    ylim([0 90]);
    set(gca, 'YTick', [0, 45, 90]);
    grid on

    subplot(11,1,10:11);
    bar(twoSensorClassification)
    title('classification');
    axis tight
    ylim([0, 7]);
    ax = gca;
    set(ax, 'YTick', 0:7);
    set(ax, 'YTickLabel', {'dynamic', 'left', 'prone', 'right', ...
        'supine', 'sitting', 'standing', 'undefined'});
    grid on

end

end
