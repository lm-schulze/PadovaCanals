function [dO] = oxygen_model_T(dO, T, O, O_sat, params)

% photosynthesis term
PhS = 

% reaeration term
Reaer = k_rer*(O_sat-O)

% BOD term
BOD = 

dO = PhS + Reaer - BOD
end
