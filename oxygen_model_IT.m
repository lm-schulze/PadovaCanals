function dDOdt = oxygen_model_IT(t, DO, T_fun, I_fun, DO_sat_fun, p)
% I_fun, T_fun are interpolations for the I, T values
% get parameters from p
params.Pmax = p(1); % max photosynthesis
params.k_PhS = p(2); % solar irradiance half saturation
params.theta_PhS = p(3); % photosynthesis temperature coefficient (?? idk either tbh)
params.k_R= p(4); % respiration constant
params.theta_R = p(5); % respiration temperature coefficient
params.k_aer = p(6); % reaeration coefficient

I = I_fun(t);
T = T_fun(t);

% photosynthesis term
PhS = params.Pmax .* params.theta_PhS.^(T-20) .* (I ./ (I + params.k_PhS)); 

% respiration term 
Resp = params.k_R .* params.theta_R.^(T-20);

% reaeration term
% using the weiss 1970 formula for freshwater
% I really hope that's ok
Reaer = params.k_aer .* (DO_sat_fun(T) - DO);

% compute model dDOdt
dDOdt = PhS - Resp + Reaer;
end

    