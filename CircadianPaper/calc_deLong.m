%% This function performs pairwise DeLong significance tests between ROCs of
% the four models described in Provenza, Reddy, and Allam et al 2024. This
% function has one required input:
%   1. percept_data: the data structure containing the Percept data. The
%       prerequisite for this code is calc_circadian.py, which creates the
%       appropriately-formatted data structure. This structure must contain
%       a field called "ROC."
%
% This function has one output:
%   1. delong: a table containing various tables with all pairwise
%       comparison test statistics and p-values.

function delong = calc_deLong(percept_data)

for row = 1:2 %Daily & delta models
    for hemisphere = 1:2
        pred = [];

        sorted_data = sortrows(percept_data.ROC.cosinor{row,hemisphere+1},"True",'ascend');
        target = sorted_data.True;
        pred(:,1) = sorted_data.Pred_Prob;
        
        sorted_data = sortrows(percept_data.ROC.linearAR{row,hemisphere+1},"True",'ascend');
        pred(:,2) = sorted_data.Pred_Prob;
        
        try
            sorted_data = sortrows(percept_data.ROC.nonlinearAR{row,hemisphere+1},"True",'ascend');
            pred(:,3) = sorted_data.Pred_Prob;
        catch
            pred(:,3) = nan(size(pred,1),1);
        end
        
        sorted_data = sortrows(percept_data.ROC.entropy{row,hemisphere+1},"True",'ascend');
        pred(:,4) = sorted_data.Pred_Prob;
        
        [S,~,~,~,~,theta] = wilcoxonCovariance(pred,target); %Calculates covariance
        
        thetaP = nan(4);
        x_stat = nan(4);
        for model1 = 1:4
            for model2 = 1:4
                if model1 == model2 %Skip test if self-comparison
                    continue
                elseif all(isnan(pred(:,model1))) || all(isnan(pred(:,model2))) %Skip test if no data
                    continue
                else %DeLong Test
                    L = zeros(1,size(pred,2)); %Matrix of included values
                    L(model1) = 1;
                    L(model2) = -1;
                    [thetaP(model1,model2),~,x_stat(model1,model2)] = wilcoxonConfidence(L,S,theta,0.05); 
                end
            end
        end
        
        delong{row,hemisphere} = array2table(thetaP,'VariableNames',{'Cosinor','Linear AR','Nonlinear AR','Sample Entropy'},'RowNames',{'Cosinor','Linear AR','Nonlinear AR','Sample Entropy'});
        delong{row,hemisphere} = array2table(x_stat,'VariableNames',{'Cosinor','Linear AR','Nonlinear AR','Sample Entropy'},'RowNames',{'Cosinor','Linear AR','Nonlinear AR','Sample Entropy'});
    end
end

delong = array2table(delong,'VariableNames',{'Left','Right'},'RowNames',{'Daily Model','Delta Model'});

end