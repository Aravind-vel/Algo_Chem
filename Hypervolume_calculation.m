function hypervolume = Hypervolume_calculation(pareto,Ref_ideal_pt,Ref_anti_ideal_pt)


[n_pareto,n_obj] = size(pareto);

%% Editable parameters
n_ran_samples = 100000*n_obj;

%% Hypervolume calculation

rand_samples = bsxfun(@plus,Ref_anti_ideal_pt,bsxfun(@times,(Ref_ideal_pt-Ref_anti_ideal_pt),rand(n_ran_samples,n_obj)));

dominated = 0;
for i = 1:n_pareto
idx = sum(bsxfun(@ge,pareto(i,:),rand_samples),2)==n_obj;
dominated = dominated+sum(idx);
rand_samples(idx,:) = [];
end

hypervolume = (dominated/n_ran_samples)*100;



end