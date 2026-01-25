function r = residuals_oxygen_I(p, t_DO, DO_obs, I_fun, O0)
%residuales del modelo de oxígeno dependiente de la irradiancia

%resolver modelo solo entre inicio y fin
try
    opts = odeset('RelTol', 1e-4, ...  % Looser tolerance for optimization
              'AbsTol', 1e-6, ...
              'NonNegative', 1);
    [~, DO_sim] = ode45(@(t,O) oxygen_model_I(t, O, I_fun, p), t_DO, O0, opts);

 
    % comprobaciones de seguridad
    if any(isnan(DO_sim)) || any(isinf(DO_sim))
        r = 1e6 * ones(size(DO_obs));
        return
    end

    %residuos
    r = DO_sim - DO_obs;
    
catch
    %si ode45 falla
    r = 1e6 * ones(size(DO_obs));
end
end