function polarPlotDay(varargin)
%% Function to plot one day (or a cross day averaged template) in polar format
%% Inputs ---
% Day to be plotted, title string to be set as title
switch nargin
    case 1
        day = varargin;
        titlestring = '';
        color = 'blue';
    case 2
        day = varargin{1};
        titlestring = varargin{2};
        color = 'blue';
    case 3
        day = varargin{1};
        titlestring = varargin{2};
        color = varargin{3};
end

theta = 0:2*pi/144:143*2*pi/144 ;
if size(day,2) ==1
    polarplot(theta,day,'Color',color,'LineWidth',2)
    pax=gca;
    try
    currlim = rlim(pax);
    catch
    end
    try
        if min(day)-.5 < currlim(1);
            currlim(1) = min(day)-.5;
        end
        if max(day)+1 > currlim(2)
            currlim(2) = max(day)+1;
        end
    rlim(currlim);
    catch
    end
    rlim([currlim(1),2])
    pax.ThetaDir='clockwise';
    pax.ThetaZeroLocation='top';
    hold on
    polarplot(pi*[1,1],[currlim(1),currlim(2)],'Color','k','LineWidth',2);
    thetaticklabels({});
    pax.RTickLabels = {};
    %thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
    title(titlestring);
end
end