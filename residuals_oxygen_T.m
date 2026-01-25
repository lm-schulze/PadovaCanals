function r = residuals_oxygen_T(p, t_DO, DO_obs, T_fun, DO_sat_fun, DO_0)
% this is the version without the photosynthesis term
% get parameters from p
% bc apparently lsqnonlin wants it like that?
params.k_R= p(1); % respiration constant
params.theta_R = p(2); % respiration temperature coefficient
params.k_aer = p(3); % reaeration coefficient 

try
    % try integrating the model ODE
    [~, DO_sim] = ode45(@(t, DO) oxygen_model_T(t, DO, T_fun, DO_sat_fun, p), t_DO, DO_0);
    % some security measures
    if any(isnan(DO_sim)) || any(isinf(DO_sim))
        fprintf('ODE integration produced NaN/Inf values.\n');
        r = 1e6 * ones(size(DO_obs));
        return
    end
    % residuals
    r = DO_sim - DO_obs;
    
catch
    %if ode45 fails
    r = 1e6 * ones(size(DO_obs));
    fprintf('ODE integration failed.\n');
end
end

    

    