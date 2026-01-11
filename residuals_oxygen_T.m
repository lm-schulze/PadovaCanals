function r = residuals_oxygen_T(p, deltaDO_obs, DO_t, T, DO_sat_fun)
% this is the version without the photosynthesis term
% get parameters from p
% bc apparently lsqnonlin wants it like that?
params.k_R= p(1); % respiration constant
params.theta_R = p(2); % respiration temperature coefficient
params.k_aer = p(3); % reaeration coefficient 

% respiration term 
Resp = params.k_R .* params.theta_R.^(T-20);

% reaeration term
% using the weiss 1970 formula for freshwater
% I really hope that's ok
Reaer = params.k_aer .* (DO_sat_fun(T) - DO_t);

% compute model ΔDO
deltaDO_model = - Resp + Reaer;

% compute residuals
r = deltaDO_model - deltaDO_obs;
end

    