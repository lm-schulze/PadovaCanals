clear all
close all

%% load the table from WaterQualityDataWithRain.csv
dataHourly = readtable('WaterQualityDataWithRain.csv');
% take mean of GlobalSolarRadiationCampodarsego and GlobalSolarRadiationLegnaro
dataHourly.meanSolarRadiation = mean([dataHourly.mean_GlobalSolarRadiationCampodarsego, ...
    dataHourly.mean_GlobalSolarRadiationLegnaro], 2);

% to start the fitting for the output
% let's drop all rows where AvgDissolvedOxygenOutput is NaN
dataVarsOut = {'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput', 'meanSolarRadiation'};
dataOut = rmmissing(dataHourly, 'MinNumMissing', 1, 'DataVariables', {'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput', 'meanSolarRadiation'});
dataIn= rmmissing(dataHourly, 'MinNumMissing', 1, 'DataVariables', {'AvgDissolvedOxygenInput', 'AvgWaterTemperatureInput', 'meanSolarRadiation'});
head(dataOut(:, dataVarsOut));

% Prepare data for fitting
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

%% prepare initial guesses and bounds:

% initial guesses
Pmax_ig       = 0.5;    % max photosythesis
k_PhS_ig      = 200;    % solar irradiance half saturation
theta_PhS_ig  = 1.05;   % photosynthesis temperature coefficient
k_R_ig        = 0.3;    % respiration constant
theta_R_ig    = 1.05;   % respiration temperature coefficient
k_aer_ig      = 0.05;   % reaeration coefficient
% constants for the I model
Pmax_resp_ig  = 0.5;    % max photorespiration
k_PhR_ig      = 100;    % photorespiration half saturation?
k_loss_ig        = 0.05;   % generic loss coefficient ?


% lower bounds
Pmax_lb       = 0;      % max photosythesis
k_PhS_lb      = 1;      % solar irradiance half saturation
theta_PhS_lb  = 0.9;    % photosynthesis temperature coefficient
k_R_lb        = 0;      % respiration constant
theta_R_lb    = 0.9;    % respiration temperature coefficient
k_aer_lb      = 0;      % reaeration coefficient
Pmax_resp_lb  = 0;      % max photorespiration
k_PhR_lb      = 1;      % photorespiration half saturation?
k_loss_lb     = 0;      % generic loss coefficient ?

% upper bounds
Pmax_ub       = 10;     % max photosythesis
k_PhS_ub      = 2000;   % solar irradiance half saturation
theta_PhS_ub  = 1.5;    % photosynthesis temperature coefficient
k_R_ub        = 5;      % respiration constant
theta_R_ub    = 1.5;    % respiration temperature coefficient
k_aer_ub      = 5;      % reaeration coefficient
Pmax_resp_ub  = 10;     % max photorespiration
k_PhR_ub      = 1000;   % photorespiration half saturation?
k_loss_ub     = 1000;    % generic loss coefficient ?


% initial guess
% for T-I-model
p0_TI = [
    Pmax_ig         % max photosythesis
    k_PhS_ig        % solar irradiance half saturation
    theta_PhS_ig    % photosynthesis temperature coefficient
    k_R_ig          % respiration constant
    theta_R_ig      % respiration temperature coefficient
    k_aer_ig        % reaeration coefficient
];
% T-only model
p0_T = [
    k_R_ig          % respiration constant
    theta_R_ig      % respiration temperature coefficient
    k_aer_ig        % reaeration coefficient
];
% I-only model 
p0_I = [
    Pmax_ig         % max photosythesis
    k_PhS_ig        % solar irradiance half saturation
    theta_PhS_ig    % photosynthesis temperature coefficient
    Pmax_resp_ig    % max photorespiration
    k_PhR_ig        % photorespiration half saturation?
    k_loss_ig       % generic loss coefficient ?
];


% lower bounds
% for T-I-model
lb_TI = [
    Pmax_lb         % max photosythesis
    k_PhS_lb        % solar irradiance half saturation
    theta_PhS_lb    % photosynthesis temperature coefficient
    k_R_lb          % respiration constant
    theta_R_lb      % respiration temperature coefficient
    k_aer_lb        % reaeration coefficient
];
% T-only model
lb_T = [
    k_R_lb          % respiration constant
    theta_R_lb      % respiration temperature coefficient
    k_aer_lb        % reaeration coefficient
];
% I-only model 
lb_I = [
    Pmax_lb         % max photosythesis
    k_PhS_lb        % solar irradiance half saturation
    theta_PhS_lb    % photosynthesis temperature coefficient
    Pmax_resp_lb    % max photorespiration
    k_PhR_lb        % photorespiration half saturation?
    k_loss_lb       % generic loss coefficient ?
];

% upper bounds
ub_TI = [
    Pmax_ub         % max photosythesis
    k_PhS_ub        % solar irradiance half saturation
    theta_PhS_ub    % photosynthesis temperature coefficient
    k_R_ub          % respiration constant
    theta_R_ub      % respiration temperature coefficient
    k_aer_ub        % reaeration coefficient
];
% T-only model
ub_T = [
    k_R_ub          % respiration constant
    theta_R_ub      % respiration temperature coefficient
    k_aer_ub        % reaeration coefficient
];
% I-only model 
ub_I = [
    Pmax_ub         % max photosythesis
    k_PhS_ub        % solar irradiance half saturation
    theta_PhS_ub    % photosynthesis temperature coefficient
    Pmax_resp_ub    % max photorespiration
    k_PhR_ub        % photorespiration half saturation?
    k_loss_ub       % generic loss coefficient ?
];

opts = optimoptions('lsqnonlin', ...
    'Display','iter', ...
    'ScaleProblem','jacobian', ...
    'FiniteDifferenceType','central', ...
    'FunctionTolerance',1e-8, ...
    'StepTolerance',1e-8);

%% run simulations for TI, T only, I only

% ---- T-I model --------------------------------
% set function up with the given data to pass to lsqnonlin
% to estimate the parameters detailed in p
objfun_TI = @(p) residuals_oxygen_IT(p, t_DO, DO_obs, T_fun, I_fun, DO_sat_fun, DO_0);
% parameter estimation with nonlinear least squares
[p_hat_TI, resnorm_TI, residuals_TI, exitflag_TI, output_TI] = lsqnonlin(objfun_TI, p0_TI, lb_TI, ub_TI, opts);

% print results
fprintf('\nEstimated parameters (TI-model):\n');
fprintf('---------------------------------\n');
fprintf('Pmax        = %.4f mg/L/h\n', p_hat_TI(1));
fprintf('k_PhS       = %.2f\n', p_hat_TI(2));
fprintf('theta_PhS   = %.4f\n', p_hat_TI(3));
fprintf('k_R         = %.4f mg/L/h\n', p_hat_TI(4));
fprintf('theta_R     = %.4f\n', p_hat_TI(5));
fprintf('k_aer       = %.4f 1/h\n', p_hat_TI(6));
fprintf('RSS         = %.4f\n', resnorm_TI);

%%
% ---- I-only model --------------------------------
% set up objective function
objfun_I = @(p) residuals_oxygen_I(p, t_DO, DO_obs, I_fun, DO_0);
% parameter estimation with nonlinear least squares
[p_hat_I, resnorm_I, residuals_I, exitflag_I, output_I] = lsqnonlin(objfun_I, p0_I, lb_I, ub_I, opts);
% print results
fprintf('\nEstimated parameters (I-only model):\n');
fprintf('---------------------------------\n');
fprintf('Pmax        = %.4f mg/L/h\n', p_hat_I(1));
fprintf('k_PhS       = %.2f\n', p_hat_I(2));
fprintf('Pmax_resp   = %.4f\n', p_hat_I(3));
fprintf('k_PhR       = %.4f mg/L/h\n', p_hat_I(4));
fprintf('k_loss      = %.4f\n', p_hat_I(5));
fprintf('RSS         = %.4f\n', resnorm_I);

%%
% ---- T-only model --------------------------------
% set up objective function
objfun_T = @(p) residuals_oxygen_T(p, t_DO, DO_obs, T_fun, DO_sat_fun, DO_0);
% parameter estimation with nonlinear least squares
[p_hat_T, resnorm_T, residuals_T, exitflag_T, output_T] = lsqnonlin(objfun_T, p0_T, lb_T, ub_T, opts);
% print results
fprintf('\nEstimated parameters (T-only model):\n');
fprintf('---------------------------------\n');
fprintf('k_R         = %.4f mg/L/h\n', p_hat_T(1));
fprintf('theta_R     = %.4f\n', p_hat_T(2));
fprintf('k_aer       = %.4f 1/h\n', p_hat_T(3));
fprintf('RSS         = %.4f\n', resnorm_T);

%% now let's plug the parameter estimates into the DO_models
N = numel(DO_obs);
[t_sim, DO_sim_TI] = ode45(@(t, DO) oxygen_model_IT(t, DO, T_fun, I_fun, DO_sat_fun, p_hat_TI), t_DO, DO_0);
[~, DO_sim_I] = ode45(@(t, DO) oxygen_model_I(t, DO, I_fun, p_hat_I), t_DO, DO_0);
[~, DO_sim_T] = ode45(@(t, DO) oxygen_model_T(t, DO, T_fun, DO_sat_fun, p_hat_T), t_DO, DO_0);

%% some stats
fprintf('TI simulation diagnostics:\n');
fprintf('--------------------------\n');
fprintf('RSS          = %.3f mg^2/L^2\n', resnorm_TI);
fprintf('RMSE DO      = %.3f mg/L\n', sqrt(mean(residuals_TI.^2)));
fprintf('Mean bias DO = %.3f mg/L\n', mean(residuals_TI));
fprintf('Correlation  = %.3f\n', corr(DO_sim_TI, DO_obs));

fprintf('T-only simulation diagnostics:\n');
fprintf('--------------------------\n');
fprintf('RSS          = %.3f mg^2/L^2\n', resnorm_T);
fprintf('RMSE DO      = %.3f mg/L\n', sqrt(mean(residuals_T.^2)));
fprintf('Mean bias DO = %.3f mg/L\n', mean(residuals_T));
fprintf('Correlation  = %.3f\n', corr(DO_sim_T, DO_obs));

fprintf('I-only simulation diagnostics:\n');
fprintf('--------------------------\n');
fprintf('RSS          = %.3f mg^2/L^2\n', resnorm_I);
fprintf('RMSE DO      = %.3f mg/L\n', sqrt(mean(residuals_I.^2)));
fprintf('Mean bias DO = %.3f mg/L\n', mean(residuals_I));
fprintf('Correlation  = %.3f\n', corr(DO_sim_I, DO_obs));

%% plot time series

figure;
plot(t_DO, DO_obs, 'LineWidth', 1.2); hold on;
plot(t_sim, DO_sim_TI, '--', 'LineWidth', 1.2);
plot(t_sim, DO_sim_I, '--', 'LineWidth', 1.2);
plot(t_sim, DO_sim_T, '--', 'LineWidth', 1.2);

hold off;

xlabel('Time index (hours)');
ylabel('Dissolved Oxygen (mg/L)');
legend('Observed DO', 'TI-simulation', 'I-only simulation', 'T-only simulation', 'Location', 'best');
title('Observed vs Simulated Dissolved Oxygen');
grid on;
saveas(gcf, 'DissolvedOxygenObservedAndSimulatedOverTime.png');


%% plot simulated vs observed DO
% TI-----------------------
figure;
scatter(DO_obs, DO_sim_TI, 15, 'filled');
hold on;
plot([min(DO_obs) max(DO_obs)], [min(DO_obs) max(DO_obs)], 'k--', 'LineWidth', 1.2);
hold off;

xlabel('Observed DO (mg/L)');
ylabel('Simulated DO (mg/L)');
title('TI-simulation vs Observed DO');
axis equal;
grid on
saveas(gcf, 'DissolvedOxygenObservedVsSimulatedTI.png');

% T only-------------------
figure;
scatter(DO_obs, DO_sim_I, 15, 'filled');
hold on;
plot([min(DO_obs) max(DO_obs)], [min(DO_obs) max(DO_obs)], 'k--', 'LineWidth', 1.2);
hold off;

xlabel('Observed DO (mg/L)');
ylabel('Simulated DO (mg/L)');
title('T-only simulation vs Observed DO');
axis equal;
grid on;
saveas(gcf, 'DissolvedOxygenObservedVsSimulatedTOnly.png');


% I only --------------------
figure;
scatter(DO_obs, DO_sim_I, 15, 'filled');
hold on;
plot([min(DO_obs) max(DO_obs)], [min(DO_obs) max(DO_obs)], 'k--', 'LineWidth', 1.2);
hold off;

xlabel('Observed DO (mg/L)');
ylabel('Simulated DO (mg/L)');
title('I-only simulation vs Observed DO');
axis equal;
grid on;
saveas(gcf, 'DissolvedOxygenObservedVsSimulatedIOnly.png');

%% AIC evaluation
% compute AIC of lsqnonlin-optimised models
% TI
k_TI = numel(p_hat_TI); % number of parameters
AIC_TI = 2*k_TI + N*log(resnorm_TI/N);
fprintf('TI-model: AIC = %.4f\n', AIC_TI);

% I only
k_I = numel(p_hat_I); % number of parameters
AIC_I = 2*k_I + N*log(resnorm_I/N);
fprintf('I-onl ymodel: AIC = %.4f\n', AIC_I);

% T only
k_T = numel(p_hat_T); % number of parameters
AIC_T = 2*k_T + N*log(resnorm_T/N);
fprintf('T-only model: AIC = %.4f\n', AIC_T);

