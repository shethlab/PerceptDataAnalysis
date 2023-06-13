is_VCVS = 1; %set 1 if data is VC/VS, 0 if GPi
stat = comb_entropy; %change this line to fit variable of interest

chronic={[48:100];[0:29,70:296];[176:665];[95:273];[0:396]};
pre_GPI={[-48:-1];[];[];[-9:-1];[]};

stats={};

switch is_VCVS
    case 1 %VC/VS data
        for j=1:5
            for k=1:2
                [~,pre_idx]=intersect(comb_days{j,k},-999:-1);
                [~,post_idx]=intersect(comb_days{j,k},chronic{j});
                
                pre_data=stat{j,k}(1,pre_idx,1);
                post_data=stat{j,k}(1,post_idx,1);
                
                stats{j,k}=detailedStats(post_data(~isnan(post_data)),pre_data(~isnan(pre_data)));
            end
        end
    otherwise %GPi data
        for j=[1,4]
            for k=1:2           
                [~,pre_idx]=intersect(comb_days{j,k},pre_GPI{j});           
                [~,post_idx]=intersect(comb_days{j,k},chronic{j});
                
                pre_data=stat{j,k}(1,pre_idx,1);
                post_data=stat{j,k}(1,post_idx,1);
                
                stats{j,k}=detailedStats(post_data(~isnan(post_data)),pre_data(~isnan(pre_data)));
            end
        end            
end

%Open and view these variables for stats
stats_left=[stats{:,1}];
stats_right=[stats{:,2}];