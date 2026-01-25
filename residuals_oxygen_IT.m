function r = residuals_oxygen_IT(p, t_DO, DO_obs, T_fun, I_fun, DO_sat_fun, DO_0)

try
    opts = odeset('RelTol', 1e-4, ...  % Looser tolerance for optimization
              'AbsTol', 1e-6, ...
              'NonNegative', 1);
    % try integrating the model ODE
    [~, DO_sim] = ode45(@(t, DO) oxygen_model_IT(t, DO, T_fun, I_fun, DO_sat_fun, p), t_DO, DO_0, opts);
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

    