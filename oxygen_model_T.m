function dDOdt = oxygen_model_T(t, DO, T_fun, DO_sat_fun, p)

% get parameters from p
% bc apparently lsqnonlin wants it like that?
params.k_R= p(1); % respiration constant
params.theta_R = p(2); % respiration temperature coefficient
params.k_aer = p(3); % reaeration coefficient

T = T_fun(t);

% respiration term 
Resp = params.k_R .* params.theta_R.^(T-20);

% reaeration term
% using the weiss 1970 formula for freshwater
% I really hope that's ok
% DO_prev is the 
Reaer = params.k_aer .* (DO_sat_fun(T) - DO);

% compute model dDO/dt
dDOdt = - Resp + Reaer;
end

    