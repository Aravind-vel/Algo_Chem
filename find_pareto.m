function [paretopoints_obj,paretopoints_var] = find_pareto(Objective,variables)

% Initialize an empty logical array to store Pareto front information
isPareto = true(size(Objective, 1), 1);

% Determine the Pareto front
for i = 1:size(Objective, 1)
    for j = 1:size(Objective, 1)
        % Check if solution i dominates solution j
        if all(Objective(i, :) <= Objective(j, :)) && any(Objective(i, :) < Objective(j, :))
            % Solution i does not dominate solution j
            isPareto(i) = false;
            break;  % No need to check further for this solution

        end
    end
end

% Extract the Pareto-optimal solutions
paretopoints_obj = Objective(isPareto, :);
paretopoints_var = variables(isPareto,:);
end