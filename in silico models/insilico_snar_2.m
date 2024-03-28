function [Yield,STY,E_factor] = insilico_snar_2(Res_time,Temp,C1_inlet_conc,C2_eq)


%reservoir concentration
C1 = 1; %M
C2 = 2; %M


reactor_volume = 5*10^-3; % L; ml to L converted


mol_weight = [631.09;71.12;210.21;682.20;733.32]; %g/mol


%Total volumetric flowrate
Vol_flow_total = reactor_volume/Res_time; % L/min

%Inlet concentration of Reactant 2 - pyrrolidine
C2_inlet_conc = C2_eq*C1_inlet_conc; % M - mol/L

%volumetric flowrate of Reactant 1 and Reactant 2
Vol_flow_1 = (C1_inlet_conc/C1)*Vol_flow_total; % L/min
Vol_flow_2 = (C2_inlet_conc/C2)*Vol_flow_total; % L/min

Concentration_final = Concentration(Res_time,Temp,C1_inlet_conc,C2_inlet_conc);

Yield = (Concentration_final(3)/C1_inlet_conc)*100; % (%)

STY = mol_weight(3) * (Concentration_final(3))/Res_time; %g/L min

Throughput = STY * reactor_volume*60; %g/h

Ethanol_mass = (Vol_flow_1+Vol_flow_2)* 789; %g/min ethanoldensity = 789 g/L

undesidred_product = 0;
desired_product = 0;

for i = 1:5

    if i ~= 3
undesidred_product =undesidred_product + Concentration_final(i)*mol_weight(i);
    else
desired_product = desired_product + Concentration_final(i)*mol_weight(i);
    end

end

E_factor = (Ethanol_mass + (Vol_flow_total * undesidred_product))/(Vol_flow_total*desired_product);
E_factor = -1.*E_factor; %minimize

STY = STY*60; %g/L h

% Change sign according to the maximization/minimization
STY = 1.*STY;
E_factor = 1.*E_factor; 
Yield = 1.*Yield;

end


function C_fin = Concentration(Res_time,Temp,C1,C2)



% Given initial concentrations
C3 = 0;
C4 = 0;
C5 = 0;

% Given kinetic constants
kl_ref =[57.9,2.70,0.865,1.63].*0.01*(1/0.0166667); % mol-1 dm3 s-1 (to) mol-1 l min-1

Ea_l = [33.33,35.3,38.9,44.8].*1000; % J/mol
R = 8.31 ; % J/mol K;
T_ref = 90 + 273; % K

% Given residence time and temperature
residence_time = Res_time; %min %0 to 2 min
temperature = Temp+273; %K % 30 to 120 cel

% Convert kinetic constants using given formula
kl = kl_ref .* exp((-Ea_l/R ) * (1/temperature - 1/T_ref));

% Define time step for Euler integration
dt = 0.001; % adjust as needed

% Perform Euler integration
for t = 0:dt:residence_time
    rates = rate_equations(C1, C2, C3, C4, kl);
    C1 = C1 + rates(1) * dt;
    C2 = C2 + rates(2) * dt;
    C3 = C3 + rates(3) * dt;
    C4 = C4 + rates(4) * dt;
    C5 = C5 + rates(5) * dt;
end

% The final concentrations after the residence time
C_fin = [C1, C2, C3, C4, C5];
end



% Define rate equations

function rates = rate_equations(C1, C2, C3, C4, kl)
    r1 = -(kl(1) + kl(2)) * C1 * C2;
    r2 = -(kl(1) + kl(2)) * C1 * C2 - kl(3) * C2 * C3 - kl(4) * C2 * C4;
    r3 = kl(1) * C1 * C2 - kl(3) * C2 * C3;
    r4 = kl(1) * C1 * C2 - kl(4) * C2 * C4;
    r5 = kl(3) * C2 * C3 + kl(4) * C2 * C4;
    rates = [r1; r2; r3; r4; r5];
end

