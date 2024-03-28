clc
clear all
close all

%% Editable parameters
n_models =6; % To compare
n_obj = 2;
objective_con = {'max','max'}; % in silico problem objective criteria
objective_fun = {'Yield (%)','Throughput (g/h)'};  % 'Yield (%)','STY (g h^{-1} L^{-1})','E-factor'
n_opt = 100; 
n_runs = 21;
n_cont_var = 4; % continuous variables
n_dis_var = 0; % categorical variables
n_cat_lev = 1; % levels of the categorical variables; put 1 if n_dis_var = 0
n_lhs = 5; % lhs samples per level of categorical variable

% getting mat files automatically using key name
model_name = 'reizman_1';

% Use '.' for current directory or provide a full path
folderPath = './results in mat file';

% Get a list of all files in the directory
files = dir(folderPath);

filtered_files = files(contains({files.name}, model_name));

% Define the order of the prefixes - Choose the appropriate solvers for which the results are to be compared.
prefix_order = {'MVMOO', 'EDBO', 'Dragonfly_1m', 'Dragonfly_linear', 'TSEMO', 'EIMEGO'}; % for only continuous variables
% prefix_order = {'MVMOO', 'EDBO', 'Dragonfly_1m', 'Dragonfly_linear'}; % for continuous and categorical variables

% Initialize an array to hold the sorted file names
sorted_files = strings(0);

% Loop through each prefix, find matching files, and append them to 'sorted_files'
for i = 1:length(prefix_order)
    prefix = prefix_order{i};
    for j = 1:length(filtered_files)
        fileName = filtered_files(j).name;
        if startsWith(fileName, prefix)
            sorted_files(end+1) = fileName; % Append matching file name
        end
    end
end

% Convert 'sorted_files' to a cell array if needed
model_matfile = cellstr(sorted_files);

%getting mat files manually

% model_matfile = {'Dragonfly_2hpyrane_5cat_21runs_5lhs.mat'};
legend_names = {'MVMOO','EDBO+','Dragonfly-Tchebyshev', 'Dragonfly-Linear','TSEMO','EIM-EGO'};
model_relation = [1,2,3,3,4,5];
interval_metric = 'confidence_interval'; %{'confidence_interval','STD','max_min'};
sampling_line = false;
if sampling_line
 legend_names{end+1} = 'Sampling';
 end

plot_line = {'-','--',':','-.'};
plot_line_width = 2; %for mean value
fill_transperancey = 0.3; %for interval

%creating unique color for each model
% colors_unique = numel(unique(model_relation)); % automatic color assignment

colors = [
    0, 0.4470, 0.7410;    % dark blue
    0.8500, 0.3250, 0.0980; % dark orange
    0.9290, 0.6940, 0.1250; % dark yellow
    0.4940, 0.1840, 0.5560; % dark purple
    0.4660, 0.6740, 0.1880  % dark green
];

x_label_title = 'Experiment No.';
xy_label_fontsize = 20;
xy_label_fontweight = 'bold';
legend_fontsize = 20;
legend_fontweight = 'bold';
title_fontsize = 15;

% List of figure names that you want to initialize
metric_names = {'hypervolume', 'igd','worst_attainment'};

% Initialize figures
for i = 1:numel(metric_names)
    fieldName = sprintf(metric_names{i});
    models.figures.(fieldName) = figure;
end



% Initialize trend plots for each objective
for i = 1:n_obj
    fieldName = sprintf('trend_objective_%d', i);
    models.figures.(fieldName)= figure;
    metric_names{end+1} = fieldName; % Add the new field name to the list
end




%% Initialization
% colors = hsv(colors_unique);

% This loop creates structure for each model and load X and Y values
for i = 1:n_models
    modelData = load(model_matfile{i});
    fieldName = sprintf('model_%d',i);
    models.(fieldName).X_values = modelData.X_final(1:n_opt,1:n_cont_var+n_dis_var,1:n_runs);
    models.(fieldName).Y_values = abs(modelData.Y_final(1:n_opt,1:n_obj,1:n_runs));
end

%% Identifying Reference point/ideal and anti-ideal points

% Making the objective values to -ve for the one that we are minimizing
% putting all Y values in single array to identify the reference points
% X and Y values in single array in 2 dimension to identify the True/global
% pareto points which act as a reference for IGD calculation

Y_in_single_array_3d = [];
X_in_single_array_3d = [];
Y_in_single_array_2d = [];
X_in_single_array_2d = [];

for i = 1:n_models
    fieldName = sprintf('model_%d',i);
    for j = 1:n_obj
        if strcmp(objective_con{j},'min')
            models.(fieldName).Y_values(:,j,:) = -1.*models.(fieldName).Y_values(:,j,:);
        end

    end
    Y_in_single_array_3d = [Y_in_single_array_3d;models.(fieldName).Y_values];
    X_in_single_array_3d = [X_in_single_array_3d;models.(fieldName).X_values];

    for k = 1:n_runs
        Y_in_single_array_2d = [Y_in_single_array_2d;models.(fieldName).Y_values(:,:,k)];
        X_in_single_array_2d = [X_in_single_array_2d;models.(fieldName).X_values(:,:,k)];
    end

end

% calculating Reference point for Hypervolume_1 calculation
% shifting value by 0.01 from ideal and anti_ideal point
%Refer following paper
% Knowles, Joshua. (2006). ParEGO: A Hybrid Algorithm With On-Line
% Landscape Approximation for Expension Multiobjective Optimization Problems.
% Evolutionary Computation, IEEE Transactions on. 10. 50 - 66. 10.1109/TEVC.2005.851274.

anti_ideal_point = zeros(1,n_obj);
ideal_point = zeros(1,n_obj);
for i = 1:n_obj
    anti_ideal_point(1,i) = min(min(Y_in_single_array_3d(:,i,:)));
    ideal_point(1,i) = max(max(Y_in_single_array_3d(:,i,:)));
end

% Adjusted utopia and anti utopia point by the factor of 0.01
Reference_anti_ideal_point = anti_ideal_point - 0.01 * (ideal_point - anti_ideal_point);
Reference_ideal_point = ideal_point + 0.01 * (ideal_point - anti_ideal_point);


% identifying True pareto/Global pareto - pareto points considering all
% runs in all models

[models.true_pareto.Y,models.true_pareto.X] = find_pareto(Y_in_single_array_2d,X_in_single_array_2d);
models.true_pareto.Y = sortrows(models.true_pareto.Y,1);


%% Metric calculation




for i = 1:n_models
    fieldName = sprintf('model_%d',i);

    % identifying pareto for upto jth iteration
    for j = 1:n_opt
        for k = 1:n_runs
            fieldName_pareto = sprintf('pareto_run_%d',k);
            % % identifying pareto for each runs
            % [models.(fieldName).pareto.(fieldName_pareto){j},t] = find_pareto(models.(fieldName).Y_values([1:j],:,k),models.(fieldName).X_values([1:j],:,k));
            %
            % % identifying hypervolume for each pareto
            % models.(fieldName).hypervolume.hypervolume_value(j,k) = Hypervolume_calculation(models.(fieldName).pareto.(fieldName_pareto){j},Reference_point);
            % identifying pareto for each runs
            [models.(fieldName).pareto{j},t] = find_pareto(models.(fieldName).Y_values([1:j],:,k),models.(fieldName).X_values([1:j],:,k));

          

            % identifying hypervolume for each pareto
            models.(fieldName).hypervolume.hypervolume_value(j,k) = Hypervolume_calculation(models.(fieldName).pareto{j},Reference_ideal_point,Reference_anti_ideal_point);

            % identifying igd for each pareto
            models.(fieldName).igd.igd_value(j,k) = IGD_calculation(models.true_pareto.Y,models.(fieldName).pareto{j});

            % Identifying the pareto only for the end of the optimization -
            % for attaintment plots
            if j == n_opt
               [models.(fieldName).pareto_final{k},models.(fieldName).pareto_var_final{k}] = find_pareto(models.(fieldName).Y_values(:,:,k),models.(fieldName).X_values(:,:,k));
            end

            % objective values in single array for objective trend
            for l = 1:n_obj
            fieldName_objective = sprintf('trend_objective_%d',l);
            models.(fieldName).(fieldName_objective).values(j,k) = models.(fieldName).Y_values(j,l,k);
            end

        end
    end

    % identifying worst attainment points
        models.(fieldName).worst_attaintment_points = Attainment_points_calculation(models.(fieldName).pareto_final);
    if n_obj ==2
        % worst attainment surface
        models.(fieldName).worst_attainment_surface = Attainment_surface_calculation_2d(models.(fieldName).worst_attaintment_points);
    end

    % [models.(fieldName).best_attainment,models.(fieldName).median_attainment,models.(fieldName).worst_attainment] = Attainment_calculation(models.(fieldName).pareto_final');

    % identifying objectvie trend
    for l = 1:n_obj
        fieldName_objective = sprintf('trend_objective_%d',l);
        models.(fieldName).(fieldName_objective).values =   Objective_trend_calculation(models.(fieldName).(fieldName_objective).values,objective_con{l});
    end


end

%% Mean and std./confidence interval calculation for the metric
for i = 1:n_models
    %%%% modify after creating all metrics
    fieldName = sprintf('model_%d',i);
    [models.(fieldName).hypervolume.mean,models.(fieldName).hypervolume.interval] = mean_interval(models.(fieldName).hypervolume.hypervolume_value,interval_metric);

    % igd mean and interval calculation
    [models.(fieldName).igd.mean,models.(fieldName).igd.interval] = mean_interval(models.(fieldName).igd.igd_value,interval_metric);

    % objective trend mean and interval calculation
    for l = 1:n_obj
        fieldName_objective = sprintf('trend_objective_%d',l);
        [models.(fieldName).(fieldName_objective).mean, models.(fieldName).(fieldName_objective).interval] =   mean_interval(models.(fieldName).(fieldName_objective).values,interval_metric);
    end

end


%% plotting

for i = 1:numel(metric_names)

    figure(models.figures.(metric_names{i}));

    line_plotted = [];
    num_line_plotted = [];
    curr_line = [];
    curr_color = [];
    h = [];

    if i==3 % for attainment surface
        

            if n_obj == 2 % Creates attainment plot only for two objectives


                        text = 'Worst Attainment Surface';

                        % creating attainment plot for True pareto front
                        models.true_pareto.attainment_surface = Attainment_surface_calculation_2d(sortrows(models.true_pareto.Y,1));

                        % Plot Ture pareto
                        x_axis_for_plot = models.true_pareto.attainment_surface(:,1);
                        y_axis_for_plot = models.true_pareto.attainment_surface(:,2);

                        plot(x_axis_for_plot,y_axis_for_plot,'LineStyle','-','Color','k','LineWidth',plot_line_width);
                        hold on;
                        legend_names = [{'True Pareto'},legend_names];


            for j = 1:n_models

                fieldName2 = sprintf('model_%d',j);

                % selecting line format and color for the current model
                line_plotted = [line_plotted,model_relation(j)];
                num_line_plotted = sum(line_plotted == model_relation(j));
                curr_line = plot_line(num_line_plotted);
                curr_color = colors(model_relation(j),:);

                x_axis_for_plot = models.(fieldName2).worst_attainment_surface(:,1);
                y_axis_for_plot = models.(fieldName2).worst_attainment_surface(:,2);
                
                plot(x_axis_for_plot,y_axis_for_plot,'LineStyle',curr_line,'Color',curr_color,'LineWidth',plot_line_width);

              
                % scatter(x_axis_for_plot,y_axis_for_plot,'MarkerFaceColor',curr_color,'MarkerEdgeColor','none');
                hold on;

                xlabel(objective_fun{1},'Fontsize',xy_label_fontsize,'FontWeight',xy_label_fontweight)
                ylabel(objective_fun{2},'FontSize',xy_label_fontsize,'FontWeight',xy_label_fontweight)

                 % legend(legend_names, 'FontSize',legend_fontsize,'FontWeight',legend_fontweight,Location='southoutside',Orientation='horizontal');

                if sampling_line == true
                    title([text, ': ', num2str(n_lhs), ' LHS samples'],'FontSize',title_fontsize);
                else
                    % title([text],'FontSize',title_fontsize);
                end

            end


            elseif n_obj ==3

%  Seperate file to plot worst attainment of 3 objectives

            end

    else % for all except attainment surface - hypervolume, igd, trend

            for j = 1:n_models

                

                fieldName1 = sprintf('model_%d',j);
                fieldName2 = sprintf(metric_names{i});
                mean_value = models.(fieldName1).(fieldName2).mean;
                interval_value = models.(fieldName1).(fieldName2).interval;

                line_plotted = [line_plotted,model_relation(j)];
                num_line_plotted = sum(line_plotted == model_relation(j));
                curr_line = plot_line(num_line_plotted);
                curr_color = colors(model_relation(j),:);

                % plot mean value
                h(j) = plot([1:1:n_opt],mean_value,'LineStyle',curr_line,'Color',curr_color,'LineWidth',plot_line_width);
                hold on

                % Fill between the upper and lower bounds for the 95% confidence interval
                x_fill = [1:n_opt, fliplr(1:n_opt)];
                y_fill = [interval_value(:,2)', fliplr(interval_value(:,1)')];
                fill(x_fill, y_fill, curr_color, 'EdgeColor', 'none', 'FaceAlpha', fill_transperancey);
                





            end

            hold off

            % plot sample line only if the models that are compared are having same
            % sample size
            if sampling_line == true
                h(j+1) = xline(n_lhs*n_cat_lev, 'k', 'LineWidth', 2);
             end

            xlabel(x_label_title,'FontSize',xy_label_fontsize,'FontWeight',xy_label_fontweight);

    

    switch i
        case 1 % labels for hypervolume
            ylabel('Hypervolume','FontSize',xy_label_fontsize,'FontWeight',xy_label_fontweight);

            if sampling_line == true
                % title(['Hypervolume Analysis: ' num2str(n_lhs) ' LHS samples'],'FontSize',title_fontsize);
            else
                % title(['Hypervolume Analysis'],'FontSize',title_fontsize);
            end

            % legend(h,legend_names, 'FontSize',legend_fontsize,'FontWeight',legend_fontweight,Location='Southeast');
        case 2 % labels for igd
            ylabel('IGD+','FontSize',xy_label_fontsize,'FontWeight',xy_label_fontweight);

            if sampling_line == true
                % title(['IGD+ Analysis: ' num2str(n_lhs) ' LHS samples'],'FontSize',title_fontsize);
            else
                % title(['IGD+ Analysis'],'FontSize',title_fontsize);
            end

            % legend(h,legend_names, 'FontSize',legend_fontsize,'FontWeight',legend_fontweight,Location='northeast');
        otherwise % labels for objective trend
            index = i-3;
            ylabel(objective_fun{index},'FontSize',xy_label_fontsize,'FontWeight',xy_label_fontweight);

            if sampling_line == true
                % title(['Objective Trace Analysis: ' num2str(n_lhs) ' LHS samples'],'FontSize',title_fontsize);
            else
                % title(['Objective Trace Analysis'],'FontSize',title_fontsize);
            end

            % legend(h,legend_names, 'FontSize',legend_fontsize,'FontWeight',legend_fontweight,Location='southeast');
    end


    end
end

%% Functions 

function points_attainment = attainment_points(pareto_points,reference_point)
% for Attainment calculation

%concat pareto and reference points
points = [reference_point;pareto_points];

%Adding dummypoints to create Hypervolume
for i = 1:size(points,1)

    if i ~= size(points,1)
        dummy = [points(i+1,1),points(i,2)];
        if i ==1
            points_attainment = [points(i,:);dummy];
        else
            points_attainment = [points_attainment;points(i,:);dummy];
        end

    else %for last point conncect with reference

        points_attainment = [points_attainment;points(i,:);[reference_point(1,1),points(i,2)]];


    end
end
end



function objective_trace = Objective_trend_calculation(objective,condition)

%condition = 'max' for maximization ; 'min' for minimization
objective_trace = zeros(size(objective));

% for min objective values are in negative - convert them to positive
if strcmp(condition,'min')
    objective = -1.*objective;
end

for j = 1:size(objective,2)
    objective_trace(1,j) = objective(1,j);
    for i = 2:size(objective,1)

        switch condition
            case 'max'
                if objective(i,j) > objective_trace(i-1,j)
                    objective_trace(i,j) = objective(i,j);
                else
                    objective_trace(i,j) = objective_trace(i-1,j);
                end
            case 'min'
                if objective(i,j) < objective_trace(i-1,j)
                    objective_trace(i,j) = objective(i,j);
                else
                    objective_trace(i,j) = objective_trace(i-1,j);
                end

        end
    end

end


end



