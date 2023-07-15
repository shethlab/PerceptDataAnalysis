function [stats_left,stats_right] = stat_calculations(percept_data,field,zone_index) 

switch field
    case 'entropy'
    case 'amplitude'
    case 'acrophase'
    case 'cosinor_p'
    case 'cosinor_R2'
    otherwise
        error('Inputted data field is invalid.')
end

for j=1:size(percept_data.days,1)
    for hemisphere=1:2      
        %Temporary variables per iteration
        days = percept_data.days{j,hemisphere+1};
        metric = percept_data.(field){j,hemisphere+1}(1,:,1);
        
        %Find zone indices
        pre_DBS_idx=find(days<0);
        [~,chronic_idx] = intersect(days,[zone_index.responder{j},zone_index.non_responder{j}]);
        
        %Extract per-zone data
        pre_DBS_data = metric(1,pre_DBS_idx,1);
        chronic_data = metric(1,chronic_idx,1);
        
        %Comparing pre-DBS vs chronic state statistics
        stats{j,hemisphere}=detailedStats(pre_DBS_data(~isnan(pre_DBS_data)),chronic_data(~isnan(chronic_data)),percept_data.days{j,1});
    end
end

stats_left=[stats{:,1}];
stats_right=[stats{:,2}];

end