%DO_in: condición inicial (agua que entra)
%ecuación: procesos dentro del canal
%DO_sim: DO que sale del canal
%DO_out: mediciones reales en la salida


%leer datos
rad = readtable("model_irradiance.xlsx","Sheet","irradiance","Range","A:B");
rad.Properties.VariableNames = {'time','irradiance'};

do = readtable("model_irradiance.xlsx","Sheet","DO","Range","A:C");
do.Properties.VariableNames = {'time','DO_in','DO_out'};

%me aseguro de que son datetime
rad.time = datetime(rad.time);
do.time = datetime(do.time);

%eliminar filas con tiempo no válidos
rad = rad(~isnat(rad.time),:);
do = do(~isnat(do.time),:);

%buscar el instante más temprano entre ambas series (tiempo de referencia)
t0 = min([rad.time; do.time]);

%convertir a horas desde origen (tiempo relativo en horas)
t_rad = hours(rad.time - t0);
t_DO = hours(do.time - t0);

%ordenar por tiempo
[t_rad, idxr] = sort(t_rad);
rad_I = rad.irradiance(idxr);

[t_rad, unique_idx] = unique(t_rad);
rad_I = rad_I(unique_idx);

[t_DO, idx] = sort(t_DO);
DO_in = do.DO_in(idx);
DO_out = do.DO_out(idx);

%eliminar NaN en DO
valid = ~isnan(DO_out) & ~isnan(t_DO);

t_DO = t_DO(valid);
DO_in = DO_in(valid);
DO_out = DO_out(valid);

length(t_DO);
min(t_DO);
max(t_DO);

[t_DO, ia] = unique(t_DO);
DO_in = DO_in(ia);
DO_out = DO_out(ia);

%irradiancia interpolada: convertir la irradiancia en función del tiempo
%cuando el modelo necesite el valor de irradiancia en un tiempo cualquiera,
%lo interpola a partir de los datos medidos. 
I_fun = @(t) interp1(t_rad, rad_I, t, 'linear','extrap');

%definir parámetros: valores iniciales razonables (luego se ajustarán)
params.A = 1.0;
params.alpha1 = 100;

params.B = 0.5;
params.beta1 = 80;


%condición inicial
O0 = do.DO_in(1);

%vector inicial de parámetros
p0 = [ ...
    1.0, ... %A
    100, ... %alpha1
    0.5, ... %B
    80, ... %beta1
    0.05, ... %kLoss
 ];

%limits
lb = [0, 1, 0, 1,0];
ub = [50, 1000, 50, 1000,5];

opts = optimoptions ('lsqnonlin','Display','iter');

%prueba directa del modelo con p0
params_test.A      = p0(1);
params_test.alpha1 = p0(2);
params_test.B      = p0(3);
params_test.beta1  = p0(4);
params_test.kLoss  = p0(5);

[t_test, DO_test] = ode45(@(t,O) oxygen_model_I(t,O,I_fun,params_test), t_DO, O0);


DO_test_interp = DO_test;

[min(DO_test_interp) max(DO_test_interp)]

%ajuste de parámetros
p_est = lsqnonlin (@(p) residuals_oxygen_I(p,t_DO,DO_out,I_fun,O0),p0, lb, ub, opts);

%parámetros ajustados
params.A = p_est(1);
params.alpha1 = p_est(2);
params.B = p_est(3);
params.beta1 = p_est(4);
params.kLoss = p_est(5);

%simulación final
[t_sim, DO_sim] = ode45(@(t,O) oxygen_model_I(t,O,I_fun,params), t_DO,O0);

%resultados
[min(DO_sim) max(DO_sim)]

%comparar con DO de salida
figure
plot(t_DO, DO_out, 'k.','DisplayName','DO salida (observado)')
hold on
plot(t_sim, DO_sim, 'b-', 'LineWidth', 1.5,'DisplayName','Modelo')
xlabel('Tiempo (h)')
ylabel('Oxígeno disuelto')
legend('DO salida','Modelo')
grid on


res = DO_sim - DO_out;
RSS = sum(res.^2);
n = numel(DO_out);
k = numel(p_est);

AIC = n*log(RSS/n) + 2*k