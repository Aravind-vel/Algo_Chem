function [mean_value, interval] = mean_interval(value,interval_metric)

% value is in the format a x b,
% where a corresponds to iteration, b corresponds to runs

n_runs  = size(value,2);

% Calculate mean and standard deviation for each iteration
% Assuming 'value' is a 2D matrix where rows represent iterations and columns represent runs

% Calculate mean and standard deviation along the run dimension
mean_value = mean(value, 2); % Mean across each iteration
std_dev_value = std(value, 0, 2); % Standard deviation across each iteration

% 95% confidence interval calculation
con_int_value = 1.96 * std_dev_value / sqrt(n_runs);

% Min-max values
min_value = min(value, [], 2); % Minimum for each iteration
max_value = max(value, [], 2); % Maximum for each iteration

% Preallocate interval array
interval = zeros(size(value, 1), 2);

% Applying the switch-case logic
switch interval_metric
    case 'confidence_interval'
        interval(:,1) = mean_value - con_int_value;
        interval(:,2) = mean_value + con_int_value;
    case 'STD'
        interval(:,1) = mean_value - std_dev_value;
        interval(:,2) = mean_value + std_dev_value;
    case 'max_min'
        interval(:,1) = min_value;
        interval(:,2) = max_value;
end


if ~exist('interval', 'var')
    error('Name given for the interval_metric is invalid. check spellings for confidence_interval,STD,max_min')
end

end