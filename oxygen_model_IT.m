function deltaDO = oxygen_model_IT(p, T, I, DO_prev, DO_sat_fun)
% we're computing delta DO for a timestep
% DO_prev is the DO level at the beginning
% the next DO_t is obtained as DO_prev + deltaDO
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
Resp = params.k_R .* params.theta_PhS.^(T-20);

% reaeration term
% using the weiss 1970 formula for freshwater
% I really hope that's ok
% DO_prev is the 
Reaer = params.k_aer .* (DO_sat_fun(T) - DO_prev);

% compute model ΔDO
deltaDO = PhS - Resp + Reaer;
end

    