clear all
close all

%% load the table from WaterQualityDataWithRain.csv
dataHourly = readtable('WaterQualityDataWithRain.csv');

% to start the fitting for the output
% let's drop all rows where AvgDissolvedOxygenOutput is NaN
dataVarsOut = {'DODiffOut', 'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput'};
dataOut = rmmissing(dataHourly, 'MinNumMissing', 1, 'DataVariables', {'DODiffOut', 'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput'});
dataIn= rmmissing(dataHourly, 'MinNumMissing', 1, 'DataVariables', {'DODiffIn', 'AvgDissolvedOxygenInput', 'AvgWaterTemperatureInput'});
head(dataOut(:, dataVarsOut));

%% let's try to simulate some stuff! Water temperature only version

% Extract relevant columns for fitting
deltaDO_obs = dataOut.DODiffOut; 
DO_t = dataOut.AvgDissolvedOxygenOutput; 
T = dataOut.AvgWaterTemperatureOutput;
DO_sat_fun = @DOsat_Weiss1970;

% initial guess
p0 = [
    0.3      % k_R: respiration ~0.05–1 mg/L/h
    1.08     % theta_R: respiration temperature coefficient
    0.05     % k_aer: reaeration ~0.01–0.3 1/h
];

% parameter bounds
lb = [
    0       % k_R ≥ 0
    0.95    % theta_R
    0       % k_aer ≥ 0
];

ub = [
    5       % k_R
    1.2     % theta_R
    1       % k_aer (1/h is already very strong)
];

% set function up with the given data to pass to lsqnonlin
% to estimate the parameters detailed in p
objfun = @(p) residuals_oxygen_T(p, deltaDO_obs, DO_t, T, DO_sat_fun);
% parameter estimation with nonlinear least squares
[p_hat, resnorm, residuals, exitflag, output] = lsqnonlin(objfun, p0, lb, ub);

params_hat.k_R        = p_hat(1);
params_hat.theta_R    = p_hat(2);
params_hat.k_aer      = p_hat(3);

% print results
fprintf('\nEstimated parameters (ΔDO model, T only):\n');
fprintf('---------------------------------\n');
fprintf('k_R         = %.4f mg/L/h\n', params_hat.k_R);
fprintf('theta_R     = %.4f\n', params_hat.theta_R);
fprintf('k_aer       = %.4f 1/h\n', params_hat.k_aer);
fprintf('Residual SS = %.4f\n', resnorm);

%% now let's plug the parameter estimates into the DO_model
% initialise array
N = numel(DO_t);
DO_sim = NaN(N,1);
deltaDO_sim = NaN(N-1,1);

% initial condition (starting DO level)
DO_sim(1) = DO_t(1);

% forward Euler integration
for t = 1:N-1
    deltaDO_sim(t) = oxygen_model_T(p_hat, T(t), DO_sim(t), DO_sat_fun);
    DO_sim(t+1) = DO_sim(t) + deltaDO_sim(t);
end
%% some stats
res_DO = DO_sim - DO_t;

fprintf('DO simulation diagnostics:\n');
fprintf('--------------------------\n');
fprintf('RMSE DO      = %.3f mg/L\n', sqrt(mean(res_DO.^2)));
fprintf('Mean bias DO = %.3f mg/L\n', mean(res_DO));
fprintf('Correlation  = %.3f\n', corr(DO_sim, DO_t));

%% plot time series

figure;
plot(DO_t, 'LineWidth', 1.2); hold on;
plot(DO_sim, '--', 'LineWidth', 1.2);
hold off;

xlabel('Time index (hours)');
ylabel('Dissolved Oxygen (mg/L)');
legend('Observed DO', 'Simulated DO', 'Location', 'best');
title('Observed vs Simulated Dissolved Oxygen');
grid on;

%% plot simulated vs observed DO

figure;
scatter(DO_t, DO_sim, 15, 'filled');
hold on;
plot([min(DO_t) max(DO_t)], [min(DO_t) max(DO_t)], 'k--', 'LineWidth', 1.2);
hold off;

xlabel('Observed DO (mg/L)');
ylabel('Simulated DO (mg/L)');
title('Simulated vs Observed DO');
axis equal;
grid on;

%% plot simulated vs observed delta DO
figure;
scatter(deltaDO_obs(1:end-1), deltaDO_sim, 15, 'filled');
hold on;
plot([min(deltaDO_obs) max(deltaDO_obs)], ...
     [min(deltaDO_obs) max(deltaDO_obs)], 'k--', 'LineWidth', 1.2);
hold off;

xlabel('Observed \DeltaDO (mg/L)');
ylabel('Simulated \DeltaDO (mg/L)');
title('\DeltaDO: Model vs Observations');
axis equal;
grid on;

