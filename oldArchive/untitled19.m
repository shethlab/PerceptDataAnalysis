cat_labels={'Pre-DBS','Disinhibition/Mania','Post-DBS OCD','Well'};
num_samples=3000;
OCDpreDBS = {};
hypomania = {[15:196];[0:35];[0:19,];[];[];[];[0:54]};
OCDpostDBS = {};
wellState = {[];[176:364];[95:273];[];[];[];[55:100]};
OCDpreDBSinds = {};
hypomaniainds = {};
OCDpostDBSinds = {};
wellStateinds = {};
k=1;

figure
for j=[7,1:4]
    dist_rand11=[];
    dist_rand12=[];
    dist_rand13=[];
    dist_rand14=[];
    [~,purple_idx]=intersect(comb_days{j,1},min(comb_days{j,1}):-1);
    [~,yellow_idx]=intersect(comb_days{j,1},0:max(comb_days{j,1}));
    [~,red_idx]=intersect(comb_days{j,1},hypomania{j});
    [~,blue_idx]=intersect(comb_days{j,1},wellState{j});
    OCDpreDBSinds = purple_idx;
    hypomaniainds = red_idx;
    wellStateinds = blue_idx;
    yellow_idx = setdiff(setdiff(yellow_idx,red_idx),blue_idx);
    if j ==7
        yellow_idx  = yellow_idx(yellow_idx<=100);
    end
    OCDpostDBSinds = yellow_idx;

    h{j}=subplot(1,7,k);
    hold on




    for m = 1:length(OCDpreDBSinds)
        for n = m+1:length(OCDpreDBSinds)
            try
                dist_rand11 = [dist_rand11,dtw(rots{j,2}(:,OCDpreDBSinds(m)),rots{j,2}(:,OCDpreDBSinds(n)),'euclidean')];
            catch
                dist_rand11 = [dist_rand11,nan];
            end
        end
    end

    if ~isempty(hypomaniainds)
        for m = 1:length(OCDpreDBSinds)
            for n = 1:length(hypomaniainds)
                try
                    dist_rand12 = [dist_rand12,dtw(rots{j,2}(:,OCDpreDBSinds(m)),rots{j,2}(:,hypomaniainds(n)),'euclidean')];
                catch
                    dist_rand12 = [dist_rand12,nan];
                end
            end
        end
    else
        dist_rand12 =NaN(1,length(OCDpreDBSinds)*length(hypomaniainds));
    end

    if ~isempty(OCDpostDBSinds)
        for m = 1:length(OCDpreDBSinds)
            for n = 1:length(OCDpostDBSinds)
                try
                    dist_rand13 = [dist_rand13,dtw(rots{j,2}(:,OCDpreDBSinds(m)),rots{j,2}(:,OCDpostDBSinds(n)),'euclidean')];
                catch
                    dist_rand13 = [dist_rand13,nan];
                end
            end
        end
    else
        dist_rand13 =NaN(1,length(OCDpreDBSinds)*length(OCDpostDBSinds));
    end

    if ~isempty(wellStateinds)
        for m = 1:length(OCDpreDBSinds)
            for n = 1:length(wellStateinds)
                try
                    dist_rand14 = [dist_rand14,dtw(rots{j,2}(:,OCDpreDBSinds(m)),rots{j,2}(:,wellStateinds(n)),'euclidean')];
                catch
                    dist_rand14 = [dist_rand14,nan];
                end
            end
        end
    else
        dist_rand14 =NaN(1,length(OCDpreDBSinds)*length(wellStateinds));
    end



    histogram(dist_rand11,'FaceColor',[0.6,0,0.8]);
    histogram(dist_rand12,'FaceColor','r');
    histogram(dist_rand13,'FaceColor','y');
    histogram(dist_rand14,'FaceColor','b');
    dists{j} = {dist_rand11;dist_rand12;dist_rand13;dist_rand14};
    title(rots{j,1});
    xlabel('Euclidean Distance');

    if k==7
        legend(cat_labels);
    end

    k=k+1;
end
linkaxes([h{:}],'y');
save('C:\Users\Owner\Desktop\histogrammeddistances.mat','dists')