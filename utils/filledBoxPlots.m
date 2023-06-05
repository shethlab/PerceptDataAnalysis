function filledBoxPlots(arr1,gs,cols,labels)
boxplot(arr1,gs,'Colors',cols,'Labels',labels,'Notch','off');
box_h = findobj(gca,'Tag','Box');
for q = 1:length(box_h)
    b = length(box_h)-q+1;
    hp(b) = patch([box_h(b).XData],[box_h(b).YData],cols(q,:),'FaceAlpha',.5);
end
set(gca,'FontSize',12)
uistack(box_h,'bottom')
end