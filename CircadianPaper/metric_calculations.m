%% Inputs
window_left=0; %number of days to the left of the day of interest to include in the window
window_right=0; %number of days to the right of the day of interest to include in the window 

%% Calculations

%Warning if improper window size inputs
window=[window_left,window_right];
if ~isnumeric(window) || any(window < 0) || any(mod(window,1) ~= 0)
    error('Window inputs must be integers >= 0.')
end

for j=1:size(percept_data.LFP_norm_matrix,1)
    num_components=input('Enter the number of cosinor components: ');
    num_peaks=input('Enter the number of cosinor peaks: ');
    period=24; %assuming 24 hour period for cosinor calculations
    
    %Warning if improper cosinor inputs
    if ~isnumeric([num_components,num_peaks]) || any([num_components,num_peaks] < 1) || any(mod([num_components,num_peaks],1) ~= 0)
        error('Cosinor inputs must be positive integers.')
    end

    for hemisphere=1:2       
        %Check that the day values line up with the data and skip if not
        if length(percept_data.days{j,hemisphere+1})~=size(percept_data.LFP_norm_matrix{j,hemisphere+1},2)
            disp('Size mismatch between day values and LFP data. Skipping this hemisphere.')
            continue
        end

        %Find indices of discontiuous days of data
        start_index=find(diff(percept_data.days{j,hemisphere+1})>1);
        try
            start_index=[1,start_index+1,length(percept_data.days{j,hemisphere+1})+1];
        catch
            start_index=[1,length(percept_data.days{j,hemisphere+1})+1];
        end
        
        %Initializing metrics
        c_mean=nan(1,length(percept_data.days{hemisphere+1}));
        c_var=nan(1,length(percept_data.days{hemisphere+1}));
        sample_entropy=nan(1,length(percept_data.days{hemisphere+1}));
        acro=nan(num_peaks,length(percept_data.days{hemisphere+1}));
        amp=nan(num_peaks,length(percept_data.days{hemisphere+1}));
        p=nan(1,length(percept_data.days{hemisphere+1}));
        R2=nan(1,length(percept_data.days{hemisphere+1}));
        
        t=0:2*pi/144:(sum(window)+143/144)*2*pi; %Input timestamps spaced 10 minutes apart from 0 to length of specified window

        for i=1:size(percept_data.LFP_norm_matrix{hemisphere+1},2) %Iterating on the specified window for each day in the dataset
            disp([percept_data.days{j,1},' - ',num2str(i)])
            if any((start_index > i-window_left & start_index <= i+window_right) | length(percept_data.days{j,hemisphere+1}) < i+window_right)
                % Skipping calculations if there are full-day or greater gaps in data in the specified window
            else
                y=reshape(percept_data.LFP_norm_matrix{j,hemisphere+1}(:,i-window_left:i+window_right),[1,144*(sum(window)+1)]); %Extract the processed LFP for the specified window into 1d
                
                %Calculation of circular mean and variance with data shifted up by the global min to avoid negative values
                c_var(i)=circ_var(t,y-min(percept_data.LFP_norm_matrix{j,hemisphere+1},[],'all'),[],2);
                c_mean(i)=circ_mean(t,y-min(percept_data.LFP_norm_matrix{j,hemisphere+1},[],'all'),2);
                
                %Calculation of sample entropy
                s=SampEn(y,'m',2,'tau',1,'r',3.6,'Logx',exp(1));
                sample_entropy(i)=s(3);
                
                %Calculation of cosinor amplitude, acrophase, p-value, and R^2
                [amp(1:num_peaks,i),acro(1:num_peaks,i),p(i),fit]=cosinor(t/(2*pi),y,1,num_components,num_peaks);
                R2(i)=fit.Rsquared.Ordinary;
            end
        end
        c_mean(c_mean < 0)=c_mean(c_mean < 0)+2*pi; %Shift circular mean from [-pi,pi] to [0,2*pi]
    
    %Saving the patient+hemisphere-specific metrics to the overall data structure    
    percept_data.circ_var{j,hemisphere+1}=c_var;
    percept_data.circ_mean{j,hemisphere+1}=c_mean;
    percept_data.entropy{j,hemisphere+1}=sample_entropy;
    percept_data.amplitude{j,hemisphere+1}=amp;
    percept_data.acrophase{j,hemisphere+1}=acro;
    percept_data.cosinor_p{j,hemisphere+1}=p;
    percept_data.cosinor_R2{j,hemisphere+1}=R2;
    end
end