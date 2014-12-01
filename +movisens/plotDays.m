function h = plotDays(h, start, plots, days, overlap, vals, tsl, tsr, tsm, liml, limr)

% PLOT_DAYS yyplot with markup with multiple subplots and overlap
%
% Description:
%   Plot data from timeseries on left axis, right axis and patches on a
%   figure with 'plots' subplots each of 'days' days and with 'overlap'
%   days overlap.
%
% Arguments:
%   h - figure handle
%   start - starting datenum (will be rounded down to midnight)
%   plots - number of plots to display
%   days - days on a single plot
%   overlap - days of overlap between subsequent plots
%   tsl - timeseries for left axis
%   tsr - timeseries for right axis (optional)
%   tsm - timeseries for markup (optional)
%   liml - left limits [low high] (optional)
%   limr - right limits [low high] (optional)
%
% Results:
%   h - figure handle
%
% Copyright (C) 2011-2013, Maxim Osipov
% 
% Modified for btmn by Bart te Lindert. 

hw = waitbar(0, 'Please wait while the plot is updated...');

if ~exist('h', 'var')
    
    h = figure;
    set(h,'Color',[1 1 1]);
    
else
    
    f = h;
    
    while ~isempty(f) && ~strcmp('figure', get(f,'type')),
        f = get(f, 'parent');
    end
    
    set(0, 'currentfigure', f);
    set(f, 'Renderer', 'zbuffer','Color',[1 1 1]);

end

if nargin < 4,

    error('Not enough arguments');

end

if ~exist('liml', 'var') || isempty(liml),

    lylim = [min(min(tsl.Data)) max(max(tsl.Data))];

else
    
    lylim = liml;

end

lylim = lylim.*1.25;

if exist('tsr', 'var') && ~isempty(tsr),

    if ~exist('limr', 'var') || isempty(limr),
    
        rylim = [min(min(tsr.Data)) max(max(tsr.Data))];
    
    else
        
        rylim = limr;
    
    end
    
end

strIdx = start;
start  = datenum(vals{1,strIdx});

for iPlot = 1:plots

    ah = subplot_tight(plots, 5, (iPlot-1)*5+1:iPlot*5-1, [0.04 0.015]);

    % Get data subset.
    t1     = floor(start + (iPlot-1)*days - iPlot*overlap) + .5;
    t2     = floor(start + iPlot*days - iPlot*overlap) - .5;
    tvld   = find((tsl.Time > t1) & (tsl.Time < t2));
    tsld   = getsamples(tsl, tvld);
    tsld_t = tsld.Time;
    tsld_d = tsld.Data;
    
    if isempty(tsld_t),
    
        tsld_t = t1;
        tsld_d = NaN;
    
    end
    
    if ~exist('tsr', 'var') || isempty(tsr),
        
        % Plot single axes.
        H1 = stem(ah, tsld_t, tsld_d, 'filled', 'k', 'MarkerSize', 1);
        hold on;
        AX = gca;
        xlim(AX, [t1 t2]);
        ylim(AX, lylim);
        %         if (i < plots),
        %             set(AX, 'XTickLabel', '');
        %         end
        set(AX,...
            'XTick',t1:(t2-t1)/24:t2,...
            'FontSize',16,...
            'YTick', [],...
            'TickDir', 'out',...
            'TickLength', [.003 .003],...
            'XColor', [.3 .3 .3],...
            'YColor', [.7 .7 .7],...
            'Box', 'off')
        datetick(AX, 'x', 15, 'keeplimits', 'keepticks');
        
        events = tsl.Events;
        plot_event_data(events, t1, t2, lylim)
        
        % If eventdata is part of the timeseries, plot it.
        try
            events = tsl.Events;
            plot_event_data(events, t1, t2, lylim)
        catch
            % no plots
        end
        
        hold off
        
        h = text(t1, lylim(2),...
            [datestr(t1, 'dddd dd mmmm') ' - ' datestr(t2, 'dddd dd mmmm')],...
            'Color', [0.3 0.3 0.3],...
            'FontSize', 25,...
            'VerticalAlignment', 'Top',...
            'HorizontalAlignment', 'Left');
        uistack(h, 'top');
        
    else
        
        % Plot double axes
        tvrd = find((tsr.Time > t1) & (tsr.Time < t2));
        tsrd = getsamples(tsr, tvrd);
        tsrd_t = tsrd.Time;
        tsrd_d = tsrd.Data;
        if isempty(tsrd_t),
            tsrd_t = [t1];
            tsrd_d = [NaN];
        end
        [AX,H1,H2] = plotyy(ah, tsld_t, tsld_d,...
            tsrd_t, tsrd_d,...
            'stem', 'stem');
        xlim(AX(1), [t1 t2]);
        xlim(AX(2), [t1 t2]);
        ylim(AX(1), lylim);
        ylim(AX(2), rylim);
        set(AX(1), 'box', 'off')
        set(AX(2), 'box', 'off')
        datetick(AX(1), 'x', 15, 'keeplimits');
        datetick(AX(2), 'x', 15, 'keeplimits');
        if (iPlot < plots),
            set(AX(1), 'XTickLabel', '');
            set(AX(2), 'XTickLabel', '');
        end
        set(AX(1), 'YTickLabel', '');
        set(AX(2), 'YTickLabel', '');
        set(AX(1),'YColor','k');
        set(AX(2),'YColor','r');
        set(AX(2),'YDir','reverse');
        set(H1,'Color','k');
        set(H1,'MarkerSize', 1);
        set(H2,'Color','r');
        set(H2,'MarkerSize', 1);
        
        % If eventdata is part of the timeseries, plot it.
        try

            events = tsl.Events;
            plot_event_data(events, t1, t2, lylim)
        
        catch    
            % no plots
        end
        
        try
            
            events = tsr.Events;
            plot_event_data(events, t1, t2, lylim)
        
        catch
            % no plots
        end
        
        hold off

        h = text(t1, lylim(2),...
            [datestr(t1, 'dddd dd mmmm') ' - ' datestr(t2, 'dddd dd mmmm')],...
            'Color', [0.3 0.3 0.3],...
            'FontSize',20,...
            'VerticalAlignment', 'Top',...
            'HorizontalAlignment', 'Left');
        uistack(h, 'top');
    
    end
    
    % Plot markup
    % TODO - we plot all markup currently, some not visible, but want just a subset
    if exist('tsm', 'var') && ~isempty(tsm),
        tvmd = find((tsm.Time > t1-1) & (tsm.Time < t2+1));
        tsmd = getsamples(tsm, tvmd);
        if ~isempty(tsmd.Time),
            patch_x = [tsmd.Time'; tsmd.Data'; tsmd.Data'; tsmd.Time'];
            patch_y = zeros(size(patch_x));
            patch_y(3, :) = lylim(2);
            patch_y(4, :) = lylim(2);
            H = patch(patch_x, patch_y, [1, 1, 0]);
            set(H, 'edgecolor', 'none');
            uistack(H, 'bottom');
            xlim([t1 t2]);
            set(H, 'Clipping', 'on');
        end
    end

    
    % Add text data.
    subplot_tight(plots, 5, iPlot*5, [0.04 0.015]);
    
    if (iPlot ~= 1)
    
        fntSize = 16;
        tst     = vals{13, iPlot};
        tstH    = floor(tst/60);
        tstM    = round(tst-(tstH*60));
        tst     = strcat(num2str(tstH), {'h '}, num2str(tstM),'m');

        % Sleep variables from actant.
        text(0, 8.5, sprintf('Totale slaapduur: %s', tst{:,:}),...
            'FontSize', fntSize)
        text(0, 7  , sprintf('Slaaplatentie: %sm',...
            num2str(vals{7, iPlot})),...
            'FontSize', fntSize)
        text(0, 5.5, sprintf('Aantal min wakker: %sm',...
            num2str(round(vals{12, iPlot}))),...
            'FontSize', fntSize)
        text(0, 4  , sprintf('%% van de tijd in bed geslapen: %.1f%%',...
            vals{15, iPlot}),...
            'FontSize', fntSize)

        % Subjective input from the diaries.
        text(0, 2.5, sprintf('Slaapkwaliteit: %s',...
            vals{22, iPlot}),...
            'FontSize', fntSize)
        text(0, 1  , sprintf('Uitgerust: %s',...
            vals{23, iPlot}),...
            'FontSize', fntSize)

    end
    
    axis([0 2 0.7 8.8])
    axis off
    waitbar(iPlot/plots, hw);

end

waitbar(1, hw);
close(hw);

end

% Plotoption for eventdata
function plot_event_data(events, t1, t2, lylim)
area([t1 t2], [lylim(2) lylim(2)],...
    'LineStyle', 'none',...
    'FaceColor', [.92 .97 .92]);

for j = 1:numel(events)
    
    % Get name and time of event.
    label = events(1,j).Name;
    time  = datenum(events(1,j).StartDate);
    
    % Shade period between inBed and outOfBed.
    if strcmp(label, 'In bed time')
        
        for k = j:numel(events)
            
            % Get name and time of event.
            label2 = events(1,k).Name;
            time2 = datenum(events(1,k).StartDate);
            
            if strcmp(label2, 'Out of bed time')
                area([time time2], [lylim(2) lylim(2)],...
                    'LineStyle', 'none',...
                    'FaceColor', [.8 .9 .9]);
                break
                
            end
            
        end
     
    % Shade period between lightsOffTime and wakeTime.
    elseif strcmp(label, 'Lights off time')
        
        for k = j:numel(events)
            
            % Get name and time of event.
            label2 = events(1,k).Name;
            time2 = datenum(events(1,k).StartDate);
            
            if strcmp(label2, 'Wake time')
                area([time time2], [lylim(2) lylim(2)],...
                    'LineStyle', 'none',...
                    'FaceColor', [.95 .8 .8]);
                break
                
            end
            
        end
    
    % Shade periode between sleepOnsetTime and finalWakeTime.
    elseif strcmp(label, 'Sleep onset time')
        
        for k = j:numel(events)
            
            % Get name and time of event
            label2 = events(1,k).Name;
            time2 = datenum(events(1,k).StartDate);
            
            if strcmp(label2, 'Final wake time')
                area([time time2], [lylim(2) lylim(2)],...
                    'LineStyle', 'none',...
                    'FaceColor', [.85 .7 .85]);
                break
            end
            
        end
        
    elseif strcmp(label, 'wake')
        
        plot([time time], [t2-100 t2-100],  '+');
        
    end
end
end
