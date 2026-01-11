function r = residuals_oxygen_IT(p, deltaDO_obs, DO_t, T, I, DO_sat_fun)
% get parameters from p
% bc apparently lsqnonlin wants it like that?
params.Pmax = p(1); % max photosynthesis
params.k_PhS = p(2); % solar irradiance half saturation
params.theta_PhS = p(3); % photosynthesis temperature coefficient (?? idk either tbh)
params.k_R= p(4); % respiration constant
params.theta_R = p(5); % respiration temperature coefficient
params.k_aer = p(6); % reaeration coefficient

% photosynthesis term
PhS = params.Pmax .* params.theta_PhS.^(T-20) .* (I ./ (I + params.k_PhS)); 

% respiration term 
Resp = params.k_R .* params.theta_R.^(T-20);

% reaeration term
% using the weiss 1970 formula for freshwater
% I really hope that's ok
Reaer = params.k_aer .* (DO_sat_fun(T) - DO_t);

% compute model ΔDO
deltaDO_model = PhS - Resp + Reaer;

% compute residuals
r = deltaDO_model - deltaDO_obs;
end

    