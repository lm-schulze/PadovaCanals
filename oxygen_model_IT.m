function [dO] = oxygen_model_IT(dO, T, I, O, O_sat, params)

% photosynthesis term
P_max = params.mu*exp()
PhS = P_max * I / (I + params.alpha1);

% reaeration term
Reaer = params.k_rear*(O_sat-O);

% BOD term
BOD = 

dO = PhS + Reaer - BOD;
end
