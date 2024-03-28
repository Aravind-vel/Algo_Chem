function [Yield,Throughput]= insilico_cycloadditions_1(Temp,time,react_b,cat_eq,catalyst)


%continuous variables - Temperature cel, Residence time min, Reactant B eq,
%                        Cat eq. scalar value
%categorical variables - catalyst (5) in categorical value

% 1 - Ethanolamine
% 2 - Pyrrolidine
% 3 - EDA
% 4 - Butylamine
% 5 - Piperideine


load("cycloadditions_training_data.mat","objective","variables");

trainingData = variables;
catalyst = categorical(catalyst);
testData_table = table(Temp,time,react_b,cat_eq,catalyst);
testData_table.Properties.VariableNames = {'Temp','Time','React eq','cat eq',...
    'Catalyst'};


responseData = objective;

trainingData_table = table(trainingData(:,1),trainingData(:,2),trainingData(:,3),trainingData(:,4),categorical(trainingData(:,5)),responseData);
trainingData_table.Properties.VariableNames = {'Temp','Time','React eq','cat eq',...
    'Catalyst','Yield'};
gprmodel = fitrgp(trainingData_table,'Yield','KernelFunction','ardmatern52',Standardize=true);
predicted_yield = resubPredict(gprmodel);
Yield = predict(gprmodel,testData_table);

%% Throughput calculation

    Inj_volume = 214; %micro l
    lim_stock = 0.5; %M
    exc_stock = 0.5; %M
    cat_stock = 0.05; %M
    Reactor_vol = 5; %ml
    mol_weight_product = 246;


    volume_lim = (exc_stock*Inj_volume)/(exc_stock+lim_stock*(((cat_eq*exc_stock)+(react_b*cat_stock))/(cat_stock)));
    Conc_lim_aftermix = lim_stock * volume_lim /Inj_volume;

    Throughputd = Yield * 0.01 * Conc_lim_aftermix * Reactor_vol/(time); %mol/min
    Throughput = Throughputd * mol_weight_product * 0.001 / 0.01667;
    Throughput = 1.*Throughput;
    Yield = 1.*Yield;







end


