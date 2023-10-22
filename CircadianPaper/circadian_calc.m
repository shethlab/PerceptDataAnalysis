function percept_data = circadian_calc(percept_data,window_left,window_right,period,is_demo)

%Warning if improper window size inputs
window=[window_left,window_right];
if ~isnumeric(window) || any(window < 0) || any(mod(window,1) ~= 0)
    error('Window inputs must be integers >= 0.')
end

%Set 24 hour cosinor period if no or invalid period is provided
if ~exist('period','var') || ~isnumeric(period) || isempty(period) || period <= 0
    disp('Period input not specified or invalid. Assuming 24 hr.')
    period = 24;
end

% If the demo flag is enabled, uses hardcoded cosinor parameters for the demo dataset
if exist('is_demo','var') && is_demo == 1
    if size(percept_data.days,1) == 6 %VC/VS demo data loaded
        all_components = [3,2,1,1,1,2];
        all_peaks = [2,2,1,1,1,2];
    else %GPi demo data loaded
        all_components = [2,1,1];
        all_peaks = [2,1,1];
    end
end

for j = 1:size(percept_data.days,1)
    if exist('all_components','var')
        num_components = all_components(j);
        num_peaks = all_peaks(j);
    else
        num_components = input(['Enter the number of cosinor components for subject ',percept_data.days{j,1},': ']); %cosinor parameter input
        num_peaks = input(['Enter the number of cosinor peaks for subject ',percept_data.days{j,1},': ']); %cosinor parameter input
    end

    %Warning if improper cosinor inputs
    if ~isnumeric([num_components,num_peaks]) || any([num_components,num_peaks] < 1) || any(mod([num_components,num_peaks],1) ~= 0)
        error('Cosinor inputs must be positive integers.')
    end

    for hemisphere=1:2
        %Temporary variables per iteration
        days = percept_data.days{j,hemisphere+1};
        LFP_norm = percept_data.LFP_norm_matrix{j,hemisphere+1};
        LFP_raw = percept_data.LFP_raw_matrix{j,hemisphere+1};
        time = percept_data.time_matrix{j,hemisphere+1};

        LFP_filled = fillData(LFP_raw,days); %nan-filled, outlier-removed
        LFP_filled = (LFP_filled-nanmean(LFP_filled))./nanstd(LFP_filled);

        %Check that the day values line up with the data and skip if not
        if length(days) ~= size(LFP_norm,2)
            disp('Size mismatch between day values and LFP data. Skipping this hemisphere.')
            continue
        end

        %Find indices of discontiuous days of data
        start_index = find(diff(days) > 1);
        try
            start_index = [1,start_index+1,length(days)+1];
        catch
            start_index = [1,length(days)+1];
        end
        
        %Initializing metrics
        sample_entropy = nan(1,length(days));
        acro = nan(1,length(days),num_peaks);
        amp = nan(1,length(days),num_peaks);
        p = nan(1,length(days));
        R2 = nan(1,length(days));
        autocorrelation = nan(1,length(days));
        
        for i = 1:length(days) %Iterating on the specified window for each day in the dataset
            disp([percept_data.days{j,1},' - ',num2str(i)])
            if any((start_index > i-window_left & start_index <= i+window_right) | length(days) < i+window_right)
                % Skipping calculations if there are full-day or greater gaps in data in the specified window
            else
                y = reshape(LFP_norm(:,i-window_left:i+window_right),[1,144*(sum(window)+1)]);
                y_filled = reshape(LFP_filled(:,i-window_left:i+window_right),[1,144*(sum(window)+1)]);
                t = reshape(time(:,i-window_left:i+window_right),[1,144*(sum(window)+1)]);

                %Calculation of sample entropy
                s = SampEn(y_filled,'m',2,'tau',1,'r',3.6,'Logx',exp(1));
                sample_entropy(i) = s(3);

                %Calculation of autocorrelation
                [acf, lags] = autocorr(y_filled,NumLags=144);
                autocorrelation(i) = acf(145);
                
                %Calculation of cosinor amplitude, acrophase, p-value, and R^2
                [amp(1,i,1:num_peaks),acro(1,i,1:num_peaks),p(i),fit] = cosinor(t,y,period,num_components,num_peaks);
                R2(i) = fit.Rsquared.Ordinary;
            end
        end
    
    %Saving the patient/hemisphere metrics to the overall data structure    
    percept_data.entropy{j,hemisphere+1} = sample_entropy;
    percept_data.amplitude{j,hemisphere+1} = amp;
    percept_data.acrophase{j,hemisphere+1} = acro;
    percept_data.cosinor_p{j,hemisphere+1} = p;
    percept_data.cosinor_R2{j,hemisphere+1} = R2;
    percept_data.autocorrelation{j,hemisphere+1} = autocorrelation;
    end
    
    %Copying patient labels
    percept_data.entropy{j,1} = percept_data.days{j,1};
    percept_data.amplitude{j,1} = percept_data.days{j,1};
    percept_data.acrophase{j,1} = percept_data.days{j,1};
    percept_data.cosinor_p{j,1} = percept_data.days{j,1};
    percept_data.cosinor_R2{j,1} = percept_data.days{j,1};
    percept_data.autocorrelation{j,1} = percept_data.days{j,1};
end

end