clear all
close all

%% load the table from WaterQualityDataWithRain.csv
dataHourly = readtable('data/WaterQualityDataWithRain.csv');
% take mean of GlobalSolarRadiationCampodarsego and GlobalSolarRadiationLegnaro
dataHourly.meanSolarRadiation = mean([dataHourly.mean_GlobalSolarRadiationCampodarsego, ...
    dataHourly.mean_GlobalSolarRadiationLegnaro], 2);

% to start the fitting for the output
% let's drop all rows where AvgDissolvedOxygenOutput is NaN
dataVarsOut = {'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput', 'meanSolarRadiation'};
dataOut = rmmissing(dataHourly, 'MinNumMissing', 1, 'DataVariables', {'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput', 'meanSolarRadiation'});
dataIn= rmmissing(dataHourly, 'MinNumMissing', 1, 'DataVariables', {'AvgDissolvedOxygenInput', 'AvgWaterTemperatureInput', 'meanSolarRadiation'});
head(dataOut(:, dataVarsOut));

%% let's try to simulate some stuff!
% I model

% Extract relevant columns for fitting
t_0 = min(dataOut.DateHour);
t_DO = hours(dataOut.DateHour - t_0);
DO_obs = dataOut.AvgDissolvedOxygenOutput; 
DO_0 = DO_obs(1);
I_obs = dataOut.meanSolarRadiation; 
T_obs = dataOut.AvgWaterTemperatureOutput;
% interpolate I, T to obtain functions of t
I_fun = @(t) interp1(t_DO, I_obs, t, 'linear','extrap');
T_fun = @(t) interp1(t_DO, T_obs, t, 'linear','extrap');
% DO saturation function
DO_sat_fun = @DOsat_Weiss1970;


% parameter bounds
lb_I = [
    0.01   % Pmax
    10     % k_PhS
    0.001  % P_phR
    10     % k_PhR
    0.01   % k_loss
];

ub_I = [
    5      % Pmax 
    500    % k_PhS
    1      % P_PhR
    500    % k_PhR
    1.0    % k_loss
];
%% let's to subsampling for global search
% Very aggressive subsampling for global search
idx_sub = 1:3:length(t_DO);
t_DO_sub = t_DO(idx_sub);
DO_obs_sub = DO_obs(idx_sub);

fprintf('Dataset: %d points (using %d for optimization)\n\n', length(t_DO), length(t_DO_sub));

%% particle swarm optimization

pso_opts = optimoptions('particleswarm', ...
    'Display', 'iter', ...
    'SwarmSize', 100, ...
    'MaxIterations', 100, ...
    'FunctionTolerance', 1e-4, ...
    'MaxStallIterations', 20);

% set function up with the given data to pass to particleswarm
% to estimate the parameters detailed in p
%objfun = @(p) sum(residuals_oxygen_I(p, t_DO, DO_obs, T_fun, I_fun, DO_sat_fun, DO_0).^2);
objfun_sub = @(p) sum(residuals_oxygen_I(p, t_DO_sub, DO_obs_sub, I_fun, DO_0).^2);

tic;
[p_pso_I, fval_pso_I] = particleswarm(objfun_sub, numel(lb_I), lb_I, ub_I, pso_opts);
time_pso = toc;

fprintf('\nPSO Results:\n');
fprintf('  Time: %.1f sec\n', time_pso);

% print results
fprintf('\nEstimated parameters (PSO, I-model):\n');
fprintf('---------------------------------\n');
fprintf('P_PhS  = %.4f mg/L/h\n', p_pso_I(1));
fprintf('k_PhS  = %.2f\n', p_pso_I(2));
fprintf('P_PhR  = %.4f\n', p_pso_I(3));
fprintf('k_PhR  = %.4f mg/L/h\n', p_pso_I(4));
fprintf('k_loss = %.4f\n', p_pso_I(5));
fprintf('RSS    = %.4f\n', fval_pso_I);


%% now let's plug the parameter estimates into the DO_model
% using the full estimates
% TODO: maybe do a local optmization from the best params with lsqnonlin?
% initialise array
N = numel(DO_obs);
[t_sim, DO_sim] = ode45(@(t, DO) oxygen_model_I(t, DO, I_fun, p_pso_I), t_DO, DO_0);

%% some stats
residuals = DO_sim - DO_obs;
resnorm = sum(residuals.^2);
mean_DO_obs = mean(DO_obs);
SS_tot = sum((DO_obs - mean_DO_obs).^2);  % Total sum of squares
NSE = 1 - (resnorm / SS_tot);

fprintf('DO simulation diagnostics:\n');
fprintf('--------------------------\n');
fprintf('RSS          = %.3f mg^2/L^2\n', resnorm);
fprintf('RMSE DO      = %.3f mg/L\n', sqrt(mean(residuals.^2)));
fprintf('Nash-Sutcliffe Efficiency (NSE) = %.4f\n', NSE);
fprintf('Mean bias DO = %.3f mg/L\n', mean(residuals));
fprintf('Correlation  = %.3f\n', corr(DO_sim, DO_obs));

%% plot time series

figure;
plot(t_DO, DO_obs, 'LineWidth', 1.2); hold on;
plot(t_sim, DO_sim, '--', 'LineWidth', 1.2);
hold off;

xlabel('Time index (hours)');
ylabel('Dissolved Oxygen (mg/L)');
legend('Observed DO', 'Simulated DO', 'Location', 'best');
title('I-only model: Observed vs Simulated Dissolved Oxygen');
grid on;
saveas(gcf, 'figures/DO_I_PSO10_vs_Obs_timeseries.png');


%% plot simulated vs observed DO

figure;
scatter(DO_obs, DO_sim, 15, 'filled');
hold on;
plot([min(DO_obs) max(DO_obs)], [min(DO_obs) max(DO_obs)], 'k--', 'LineWidth', 1.2);
hold off;

xlabel('Observed DO (mg/L)');
ylabel('Simulated DO (mg/L)');
title('I-only model: Simulated vs Observed DO');
axis equal;
grid on;
saveas(gcf, 'figures/DO_I_PSO10_vs_Obs.png');

%% AIC evaluation
% compute AIC of lsqnonlin-optimised model
k = numel(p_pso_I); % number of parameters
AIC = 2*k + N*log(resnorm/N);
fprintf('AIC = %.4f\n', AIC);

%% Save results to file

% Create results structure
results = struct();

% Model parameters
results.parameters.P_PhS = p_pso_I(1);
results.parameters.k_PhS = p_pso_I(2);
results.parameters.P_PhR = p_pso_I(3);
results.parameters.k_PhR = p_pso_I(4);
results.parameters.k_loss = p_pso_I(5);

% Parameter bounds used
results.bounds.lower = lb_I;
results.bounds.upper = ub_I;

% Optimization info
results.optimization.method = 'particleswarm';
results.optimization.swarm_size = pso_opts.SwarmSize;
results.optimization.max_iterations = pso_opts.MaxIterations;
results.optimization.time_seconds = time_pso;
results.optimization.final_RSS = fval_pso_I;

% Model diagnostics
results.diagnostics.RSS = resnorm;
results.diagnostics.RMSE = sqrt(mean(residuals.^2));
results.diagnostics.NSE = NSE;
results.diagnostics.mean_bias = mean(residuals);
results.diagnostics.correlation = corr(DO_sim, DO_obs);
results.diagnostics.AIC = AIC;
results.diagnostics.n_parameters = k;
results.diagnostics.n_observations = N;
results.diagnostics.n_observations_optimization = length(t_DO_sub);

% Data used
results.data.t_DO = t_DO;
results.data.DO_obs = DO_obs;
results.data.DO_sim = DO_sim;
results.data.residuals = residuals;
results.data.I_obs = I_obs;
results.data.T_obs = T_obs;

% Metadata
results.metadata.date_run = datetime('now');
results.metadata.matlab_version = version;
results.metadata.script_name = 'DO_I_PSO.m';

% Save as .mat file
save('results/DO_I_PSO_results.mat', 'results');
fprintf('\nResults saved to results/DO_I_PSO_results.mat\n');

% Also save a human-readable text summary
fid = fopen('results/DO_I_PSO_summary.txt', 'w');
fprintf(fid, 'Dissolved Oxygen Model (I-only) - PSO Optimization Results\n');
fprintf(fid, '=================================================\n\n');
fprintf(fid, 'Run date: %s\n\n', datetime('now'));

fprintf(fid, 'ESTIMATED PARAMETERS:\n');
fprintf(fid, '  P_PhS     = %.4f mg/L/h\n', results.parameters.P_PhS);
fprintf(fid, '  k_PhS     = %.2f\n', results.parameters.k_PhS);
fprintf(fid, '  P_PhR     = %.4f\n', results.parameters.P_PhR);
fprintf(fid, '  k_PhR     = %.4f mg/L/h\n', results.parameters.k_PhR);
fprintf(fid, '  k_loss    = %.4f\n', results.parameters.k_loss);

fprintf(fid, '\nOPTIMIZATION INFO:\n');
fprintf(fid, '  Method         = %s\n', results.optimization.method);
fprintf(fid, '  Time           = %.1f sec\n', results.optimization.time_seconds);
fprintf(fid, '  Swarm size     = %d\n', results.optimization.swarm_size);
fprintf(fid, '  Max iterations = %d\n', results.optimization.max_iterations);
fprintf(fid, '  RSS (PSO)      = %.4f\n', results.optimization.final_RSS);

fprintf(fid, '\n INVESTIGATED PARAMETER RANGE:\n');
fprintf(fid, '  Lower bounds   = %s\n', results.bounds.lower);
fprintf(fid, '  Upper bounds   = %s\n', results.bounds.upper);

fprintf(fid, '\nMODEL DIAGNOSTICS:\n');
fprintf(fid, '  RSS            = %.3f mg^2/L^2\n', results.diagnostics.RSS);
fprintf(fid, '  RMSE           = %.3f mg/L\n', results.diagnostics.RMSE);
fprintf(fid, '  Mean bias      = %.3f mg/L\n', results.diagnostics.mean_bias);
fprintf(fid, '  Correlation    = %.3f\n', results.diagnostics.correlation);
fprintf(fid, '  NSE            = %.3f mg/L\n', results.diagnostics.NSE);
fprintf(fid, '  AIC            = %.4f\n', results.diagnostics.AIC);
fprintf(fid, '  N observations = %d (full), %d (optimization)\n', ...
    results.diagnostics.n_observations, results.diagnostics.n_observations_optimization);

fclose(fid);
fprintf('Summary saved to results/DO_I_PSO_summary.txt\n');

% Optional: Save results as CSV for easy import to other software
results_table = table(...
    results.data.t_DO, ...
    results.data.DO_obs, ...
    results.data.DO_sim, ...
    results.data.residuals, ...
    'VariableNames', {'Time_hours', 'DO_observed', 'DO_simulated', 'Residuals'});

writetable(results_table, 'results/DO_I_PSO_timeseries.csv');
fprintf('Time series saved to results/DO_I_PSO_timeseries.csv\n\n');