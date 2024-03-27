function IGD = IGD_calculation(True_pareto,Y)

for i = 1:size(True_pareto,1) %for each z
    % for ii = 1:size(Y,3) %for every run
    for j = 1:size(Y,1) %for every pareto in that run

        da = True_pareto(i,1)-Y(j,1);
        db = True_pareto(i,2)-Y(j,2);
        d_plus_temp(j,1) = sqrt((max(da,0))^2+(max(db,0))^2);

    end
    d_plus(i,1) = min(d_plus_temp);
end
% end

% Calculating IGD

IGD = mean(d_plus(:));

end