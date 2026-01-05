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

[t_DO, idx] = sort(t_DO);
DO_in = do.DO_in(idx);
DO_out = do.DO_out(idx);


%irradiancia interpolada: convertir la irradiancia en función del tiempo
%cuando el modelo necesite el valor de irradiancia en un tiempo cualquiera,
%lo interpola a partir de los datos medidos. 
I_fun = @(t) interp1(t_rad, rad_I, t, 'linear','extrap');

%definir parámetros: valores iniciales razonables (luego se ajustarán)
params.A = 1.0;
params.alpha1 = 100;

params.B = 0.5;
params.beta1 = 80;

params.kReaer = 0.3;
params.O_sat = 9;

%condición inicial
O0 = do.DO_in(1);

any(isnan(t_DO))
any(isinf(t_DO))

%modelo
[t_sim, DO_sim] = ode45(@(t,O) oxygen_model_I(t,O,I_fun,params), t_DO,O0);

[min(DO_sim) max(DO_sim)]

%comparar con DO de salida
figure
plot(t_DO, do.DO_out, 'k.','DisplayName','DO salida (observado)')
hold on
plot(t_sim, DO_sim, 'b-', 'LineWidth', 1.5,'DisplayName','Modelo')
xlabel('Tiempo (h)')
ylabel('Oxígeno disuelto')
legend('DO salida','Modelo')
grid on