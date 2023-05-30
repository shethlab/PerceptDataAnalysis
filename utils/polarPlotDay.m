function polarPlotDay(day,titlestring)
%% Function to plot one day (or a cross day averaged template) in polar format
%% Inputs ---
% Day to be plotted, title string to be set as title
theta = 0:2*pi/144:143*2*pi/144 ;
polarplot(theta,day)
rlim([-.75,2])
pax=gca;
pax.ThetaDir='clockwise';
pax.ThetaZeroLocation='top';
thetaticklabels({'0:00','2:00','4:00','6:00','8:00','10:00','12:00','14:00','16:00','18:00','20:00','22:00'})
title(titlestring);
end