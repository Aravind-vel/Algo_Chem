function worst_surface = Attainment_surface_calculation_2d(points)
%% calculation
points = sortrows(points,2);

% creating mid points to connect vertically and horizontally
for i = 1:size(points,1)-1
   
        dummy = [points(i+1,1),points(i,2)];
        if i ==1
            points_attainment = [points(i,:);dummy];
        else
            points_attainment = [points_attainment;points(i,:);dummy];
        end

        % last point is added to the list
        if i ==size(points,1)-1
            points_attainment = [points_attainment;points(i+1,:);];
        end
    
end
worst_surface = points_attainment;

end

