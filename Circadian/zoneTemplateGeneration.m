%% Template Generation

function zoneTemplateGeneration(circadianData,acrophases,pvals,days,smooth,overlaid,wrapped,daystoplot,bl)


%% Zone Days and Colors
if isempty(daystoplot)
    preDBSdays = {-100:-1;-100:-1;-100:-1;-100:-1;-100:-1};
    maniadays = {[];30:69;0:8;0:4;[]};
    postDBSdays = {[];[0:29,70:296];[];[];0:665};
    healthydays = {48:100;[];176:665;95:290;[]};
else
    preDBSdays = daystoplot{1};
    maniadays = daystoplot{2};
    postDBSdays = daystoplot{3};
    healthydays = daystoplot{4};
end

c_red = [245,0,40]/255;
c_blue = [50,50,255]/255;
c_purple = [127,63,152]/255;
c_yellow = [255,215,0]/255;

hems = {'Left Hemisphere','Right Hemisphere'};

%% Rotate and Smooth Matrix
smoothedRotatedCircadianMatrices = {};
for i = 1:5
    smoothedRotatedCircadianMatrices{i,1} = circadianData{i,1};
    for j = 2:3
        smoothedRotatedCircadianMatrices{i,j} = smoothRotate(circadianData{i,j},acrophases{i,j-1},pvals{i,j-1},smooth);
    end

end




%% Generate Template Arrays
templates = {};
for i = 1:5
    templates{i,1} = smoothedRotatedCircadianMatrices{i,1};
    for j = 2:3
        %% Pre DBS
        [~, indspre] = intersect(days{i,j-1},preDBSdays{i});
        indspre=setdiff(indspre,find(isnan(acrophases{i,j-1}(:,:,1))));
        templates{i,j}(:,1) = median(smoothedRotatedCircadianMatrices{i,j}(:,indspre),2,'omitnan');



        [~, maniainds] = intersect(days{i,j-1},maniadays{i});
        maniainds=setdiff(maniainds,find(isnan(acrophases{i,j-1}(:,:,1))));
        templates{i,j}(:,2) = median(smoothedRotatedCircadianMatrices{i,j}(:,maniainds),2,'omitnan');


        [~, postDBSinds] = intersect(days{i,j-1},postDBSdays{i});
        postDBSinds=setdiff(postDBSinds,find(isnan(acrophases{i,j-1}(:,:,1))));
        templates{i,j}(:,3) = median(smoothedRotatedCircadianMatrices{i,j}(:,postDBSinds),2,'omitnan');


        [~, indshealth] = intersect(days{i,j-1},healthydays{i});
        indshealth=setdiff(indshealth,find(isnan(acrophases{i,j-1}(:,:,1))));
        templates{i,j}(:,4) = median(smoothedRotatedCircadianMatrices{i,j}(:,indshealth),2,'omitnan');
    end
end


%% Plot Templates Wrapped or Unwrapped
if wrapped
    for h = 2:2+bl
        figure;
        %figure('Position', get(0, 'Screensize'));

        t = tiledlayout(2-overlaid,5);
        j = 1;
        for i =[1,3,4,2,5]
            nexttile(j)
            polarPlotDay(templates{i,h}(:,1),smoothedRotatedCircadianMatrices{i,1},c_yellow);
            hold on
            %     polarPlotDay(templates{i,h}(:,2),smoothedRotatedCircadianMatrices{i,1},c_red);
            if ~overlaid
                nexttile(5+j)
            end
            polarPlotDay(templates{i,h}(:,3),smoothedRotatedCircadianMatrices{i,1},c_purple);
            hold on
            polarPlotDay(templates{i,h}(:,4),smoothedRotatedCircadianMatrices{i,1},c_blue);
            j = j+1;
        end
        subtitle(t,hems{h-1});
    end


else
    for h = 2:2+bl
        figure('Position', get(0, 'Screensize'));
        t = tiledlayout(2-overlaid,5);
        j = 1;
        for i =[1,3,4,2,5]
            nexttile(j)
            plot((0:143)/6,templates{i,h}(:,1)-mean(templates{i,h}(:,1),'omitnan'),'Color',c_yellow,'LineWidth',2);
            title(smoothedRotatedCircadianMatrices{i,1});
            hold on
            %plot((0:143)/6,templates{i,h}(:,1)-mean(templates{i,h}(:,1),'omitnan'),'Color',c_red,'LineWidth',2);
            if ~overlaid
                nexttile(5*(1)+j)
            end

            plot((0:143)/6,templates{i,h}(:,3)-mean(templates{i,h}(:,3),'omitnan'),'Color',c_purple,'LineWidth',2);
            hold on
            plot((0:143)/6,templates{i,h}(:,4)-mean(templates{i,h}(:,4),'omitnan'),'Color',c_blue,'LineWidth',2);
            title(smoothedRotatedCircadianMatrices{i,1});
            linkaxes

            j = j+1;
        end
        title(t,hems{h-1});
    end
end
end