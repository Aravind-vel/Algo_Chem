function worst_attainment = Attainment_points_calculation(pareto)

% From all the pareto which are in the format for maximization, worst
% attainment points can be calculated by identifying the pareto points of
% all the pareto (n_runs) corresponding to minimization.  

%all pareto in single array
Objective = vertcat(pareto{:});


  % Initialize an empty logical array to store Pareto front information
    isPareto = true(size(Objective, 1), 1);

    % Determine the Pareto front for minimization
    for i = 1:size(Objective, 1)
        for j = 1:size(Objective, 1)
            % Check if solution i is dominated by solution j
            if all(Objective(i, :) >= Objective(j, :)) && any(Objective(i, :) > Objective(j, :))
                % Solution i is dominated by solution j
                isPareto(i) = false;
                break;  % No need to check further for this solution
            end
        end
    end

    % Extract the Pareto-optimal solutions
    worst_attainment = Objective(isPareto, :);
    % paretopoints_var = variables(isPareto, :);

end

