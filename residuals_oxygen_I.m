function r = residuals_oxygen_I(p, t_DO, DO_obs, I_fun, O0)
%residuales del modelo de oxígeno dependiente de la irradiancia
%se usan para el ajuste por mínimos cuadrados (lsqnonlin)

%asignar parámetros
params.A = p(1);
params.alpha1 = p(2);
params.B = p(3);
params.beta1 = p(4);
params.kLoss = p(5);

%resolver modelo solo entre inicio y fin
try
    [~, DO_sim] = ode45(@(t,O) oxygen_model_I(t,O,I_fun,params), t_DO, O0);

 
    % comprobaciones de seguridad
    if any(isnan(DO_sim)) || any(isinf(DO_sim))
        r = Inf(size(DO_obs));
        return
    end

    %residuos
    r = DO_sim - DO_obs;
    
catch
    %si ode45 falla
    r = Inf(size(DO_obs));
end
end