clear all
close all

%% load the table from WaterQualityDataWithRain.csv
dataHourly = readtable('WaterQualityDataWithRain.csv');
% take mean of GlobalSolarRadiationCampodarsego and GlobalSolarRadiationLegnaro
dataHourly.meanSolarRadiation = mean([dataHourly.mean_GlobalSolarRadiationCampodarsego, ...
    dataHourly.mean_GlobalSolarRadiationLegnaro], 2);

% let's drop all rows where AvgDissolvedOxygenOutput is NaN
dataVarsOut = {'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput', 'meanSolarRadiation'};
dataOut = rmmissing(dataHourly, 'MinNumMissing', 1, 'DataVariables', {'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput', 'meanSolarRadiation'});
dataIn= rmmissing(dataHourly, 'MinNumMissing', 1, 'DataVariables', {'AvgDissolvedOxygenInput', 'AvgWaterTemperatureInput', 'meanSolarRadiation'});
head(dataOut(:, dataVarsOut));

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

%% alright let's set our parameters & initial guesses

% for the irradiance-only model
% params.Model.param = [estimate lb ub]
params.I.P_PhS = [3.0, 0.01, 5];
params.I.k_PhS = [50, 10, 500];
params.I.P_PhR = [0.05, 0.01, 1];
params.I.k_PhR = [50, 10, 500];
params.I.k_loss = [0.05, 0, 1] ;
params.I.names = ["P_PhS", "k_PhS", "P_PhR", "k_PhR", "k_loss"];
params.I.p =  [
    params.I.P_PhS(1)           % max photosythesis
    params.I.k_PhS(1)           % solar irradiance half saturation
    params.I.P_PhR(1)           % max photorespiration
    params.I.k_PhR(1)           % photorespiration half saturation?
    params.I.k_loss(1)          % generic loss coefficient ?
];
params.I.lb =  [
    params.I.P_PhS(2)           % max photosythesis
    params.I.k_PhS(2)           % solar irradiance half saturation
    params.I.P_PhR(2)           % max photorespiration
    params.I.k_PhR(2)           % photorespiration half saturation?
    params.I.k_loss(2)          % generic loss coefficient ?
];
params.I.ub =  [
    params.I.P_PhS(3)           % max photosythesis
    params.I.k_PhS(3)           % solar irradiance half saturation
    params.I.P_PhR(3)           % max photorespiration
    params.I.k_PhR(3)           % photorespiration half saturation?
    params.I.k_loss(3)          % generic loss coefficient ?
];


% for the temperature-only model
params.T.P_R = [0.5, 0.1, 5];
params.T.theta_R = [1.08, 1.0, 1.2];
params.T.k_aer = [0.1, 0.01, 0.5];
params.T.names = ["P_R", "theta_R", "k_aer"];
params.T.p = [
    params.T.P_R(1)
    params.T.theta_R(1)
    params.T.k_aer(1)
];
params.T.lb = [
    params.T.P_R(2)
    params.T.theta_R(2)
    params.T.k_aer(2)
];
params.T.ub = [
    params.T.P_R(3)
    params.T.theta_R(3)
    params.T.k_aer(3)
];

% for the TI model
params.TI.P_PhS = [3.0, 0.01, 5];
params.TI.k_PhS = [50, 10, 500];
params.TI.theta_PhS = [1.04, 1.0, 1.1];
params.TI.P_R = [0.5, 0.1, 5];
params.TI.theta_R = [1.08, 1.0, 1.2];
params.TI.k_aer = [0.1, 0.01, 0.5];
params.TI.names = ["P_PhS", "k_PhS", "theta_PhS", "P_R", "theta_R", "k_aer"];
params.TI.p = [
    params.TI.P_PhS(1)
    params.TI.k_PhS(1)
    params.TI.theta_PhS(1)
    params.TI.P_R(1)
    params.TI.theta_R(1)
    params.TI.k_aer(1)
];

params.TI.lb = [
    params.TI.P_PhS(2)
    params.TI.k_PhS(2)
    params.TI.theta_PhS(2)
    params.TI.P_R(2)
    params.TI.theta_R(2)
    params.TI.k_aer(2)
];

params.TI.ub = [
    params.TI.P_PhS(3)
    params.TI.k_PhS(3)
    params.TI.theta_PhS(3)
    params.TI.P_R(3)
    params.TI.theta_R(3)
    params.TI.k_aer(3)
];


%% let's integrate the ODEs with the initial params & plot to have a baseline
[t_sim, DO_sim_TI] = ode45(@(t, DO) oxygen_model_IT(t, DO, T_fun, I_fun, DO_sat_fun, params.TI.p), t_DO, DO_0);
[~, DO_sim_I] = ode45(@(t, DO) oxygen_model_I(t, DO, I_fun, params.I.p), t_DO, DO_0);
[~, DO_sim_T] = ode45(@(t, DO) oxygen_model_T(t, DO, T_fun, DO_sat_fun, params.T.p), t_DO, DO_0);

%%%
%figure;
%plot(t_DO, DO_obs, 'LineWidth', 1.2); hold on;
%plot(t_sim, DO_sim_TI, '--', 'LineWidth', 1.2);
%plot(t_sim, DO_sim_I, '--', 'LineWidth', 1.2);
%plot(t_sim, DO_sim_T, '--', 'LineWidth', 1.2);
%
%hold off;
%
%xlabel('Time index (hours)');
%ylabel('Dissolved Oxygen (mg/L)');
%legend('Observed DO', 'TI-simulation', 'I-only simulation', 'T-only simulation', 'Location', 'best');
%title('Observed vs Simulated Dissolved Oxygen');
%grid on;
%saveas(gcf, 'figures/DOsimsInitialGuessesOverTime.png');

%% Sensitivity analysis 
% choose model
% e.g. I
%model_params = params.I;
%model_fun = @(t, DO, p) oxygen_model_I(t, DO, I_fun, p);
%model_type = 'I';

% e.g. T
% model_params = params.T;
% model_fun = @(t, DO, p) oxygen_model_T(t, DO, T_fun, DO_sat_fun, p);
% model_type = 'T';

% e.g. TI
 model_params = params.TI;
 model_fun = @(t, DO, p) oxygen_model_IT(t, DO, T_fun, I_fun, DO_sat_fun, p);
 model_type = 'TI';

n_params = length(model_params.p);
param_names = model_params.names;
perturbations = [0.10, 0.20, 0.50, 0.80]; 
n_perturbations = length(perturbations);

fprintf('Performing sensitivity analysis for Model %s\n', model_type);
fprintf('Using %d parameters\n', n_params);
fprintf('Perturbation levels: ');
fprintf('±%.0f%% ', perturbations*100);
fprintf('\n\n');

%% Run baseline simulation

try
    [t_baseline, DO_baseline] = ode45(@(t, DO) model_fun(t, DO, model_params.p), ...
        t_DO, DO_0);
    RSS_baseline = sum((DO_baseline - DO_obs).^2);
    fprintf('Baseline RSS: %.4e\n\n', RSS_baseline);
catch ME
    error('Baseline simulation failed: %s', ME.message);
end

%% Local Sensitivity Analysis (One-at-a-time) with DO-based sensitivity
sensitivity_results = struct();
sensitivity_results.param_names = param_names;
sensitivity_results.p_baseline = model_params.p;
sensitivity_results.t_DO = t_DO;
sensitivity_results.DO_baseline = DO_baseline;
sensitivity_results.perturbations = perturbations;

% Initialize storage for time-varying sensitivity
n_times = length(t_DO);
DO_perturbations = zeros(n_times, n_params, n_perturbations, 2); % (time, param, pert_level, +/-)
relative_sensitivity = zeros(n_times, n_params, n_perturbations); % relative sensitivity

% Summary statistics for each perturbation level
mean_rel_sensitivity = zeros(n_params, n_perturbations);
max_rel_sensitivity = zeros(n_params, n_perturbations);

fprintf('Parameter Sensitivity Analysis:\n');
fprintf('================================\n');

for i = 1:n_params
    fprintf('\n%s (baseline = %.4f):\n', param_names(i), model_params.p(i));
    
    for p_idx = 1:n_perturbations
        pert = perturbations(p_idx);
        
        % Perturb parameter upward
        p_plus = model_params.p;
        p_plus(i) = model_params.p(i) * (1 + pert);
        p_plus(i) = min(max(p_plus(i), model_params.lb(i)), model_params.ub(i));
        
        % Perturb parameter downward
        p_minus = model_params.p;
        p_minus(i) = model_params.p(i) * (1 - pert);
        p_minus(i) = min(max(p_minus(i), model_params.lb(i)), model_params.ub(i));
        
        % Simulate with perturbed parameters
        try
            [~, DO_plus] = ode45(@(t, DO) model_fun(t, DO, p_plus), t_DO, DO_0);
            [~, DO_minus] = ode45(@(t, DO) model_fun(t, DO, p_minus), t_DO, DO_0);
            
            % Store perturbed DO time series
            DO_perturbations(:, i, p_idx, 1) = DO_plus;
            DO_perturbations(:, i, p_idx, 2) = DO_minus;
            
            % Calculate relative (normalized) sensitivity: S_rel = (∂DO/∂p) * (p/DO)
            % This is dimensionless and easier to compare across parameters
            delta_DO = DO_plus - DO_minus;
            delta_p = p_plus(i) - p_minus(i);
            relative_sensitivity(:, i, p_idx) = (delta_DO ./ delta_p) .* (model_params.p(i) ./ DO_baseline);
            
            % Summary statistics
            mean_rel_sensitivity(i, p_idx) = mean(abs(relative_sensitivity(:, i, p_idx)));
            max_rel_sensitivity(i, p_idx) = max(abs(relative_sensitivity(:, i, p_idx)));
            
            fprintf('  ±%.0f%%: Mean |S_rel| = %.4f, Max |S_rel| = %.4f (dimensionless)\n', ...
                pert*100, mean_rel_sensitivity(i, p_idx), max_rel_sensitivity(i, p_idx));
            
        catch ME
            fprintf('  ±%.0f%%: SIMULATION FAILED (%s)\n', pert*100, ME.message);
            relative_sensitivity(:, i, p_idx) = NaN;
            mean_rel_sensitivity(i, p_idx) = NaN;
            max_rel_sensitivity(i, p_idx) = NaN;
        end
    end
end

% Store results
sensitivity_results.DO_perturbations = DO_perturbations;
sensitivity_results.relative_sensitivity = relative_sensitivity;
sensitivity_results.mean_rel_sensitivity = mean_rel_sensitivity;
sensitivity_results.max_rel_sensitivity = max_rel_sensitivity;

%% Rank parameters by sensitivity (for all perturbation levels)

for j = 1:n_perturbations
    [sorted_SI, sort_idx] = sort(mean_rel_sensitivity(:, j), 'descend');
    fprintf('\n================================\n');
    fprintf('Parameter Ranking (Most to Least Sensitive, ±%.0f%%):\n', perturbations(j)*100);
    fprintf('================================\n');
    for i = 1:n_params
        if ~isnan(sorted_SI(i))
            fprintf('%d. %s (Mean |S_rel| = %.4f)\n', i, param_names(sort_idx(i)), sorted_SI(i));
        end
    end
end

%% Visualize sensitivity results

% Create figures and results directories if needed
if ~exist('figures', 'dir')
    mkdir('figures');
end
if ~exist('results', 'dir')
    mkdir('results');
end

%% plot time series of relative sensitivity for each parameter
figure('Position', [100 100 1200 800]);

for i = 1:n_params
    subplot(ceil(n_params/2), 2, i);
    
    % Plot relative sensitivity time series for each perturbation level
    hold on;
    colors = lines(n_perturbations);
    for p_idx = 1:n_perturbations
        if ~all(isnan(relative_sensitivity(:, i, p_idx)))
            plot(t_DO, relative_sensitivity(:, i, p_idx), ...
                'Color', colors(p_idx,:), 'LineWidth', 1.5, ...
                'DisplayName', sprintf('±%.0f%%', perturbations(p_idx)*100));
        end
    end
    hold off;
    
    xlabel('Time (hours)');
    ylabel('Relative Sensitivity (dimensionless)');
    title(param_names(i));
    legend('Location', 'best');
    grid on;
end

sgtitle(sprintf('Relative Sensitivity Time Series - Model %s', model_type));
saveas(gcf, sprintf('figures/sensitivity_timeseries_Model_%s.png', model_type));

%% bar plot comparing mean relative sensitivity across perturbation levels
figure('Position', [100 100 900 600]);

x_pos = 1:n_params;
bar_width = 0.8 / n_perturbations;
colors = lines(n_perturbations);

hold on;
for p_idx = 1:n_perturbations
    bar(x_pos + (p_idx - (n_perturbations+1)/2) * bar_width, ...
        mean_rel_sensitivity(:, p_idx), bar_width, ...
        'FaceColor', colors(p_idx,:), ...
        'DisplayName', sprintf('±%.0f%%', perturbations(p_idx)*100));
end
hold off;

set(gca, 'XTick', 1:n_params, 'XTickLabel', param_names, 'XTickLabelRotation', 45);
ylabel('Mean Relative Sensitivity (dimensionless)');
title(sprintf('Parameter Sensitivity Comparison - Model %s', model_type));
legend('Location', 'best');
grid on;
saveas(gcf, sprintf('figures/sensitivity_comparison_Model_%s.png', model_type));

%% summary bar plot with max relative sensitivity
figure('Position', [100 100 900 600]);

x_pos = 1:n_params;
bar_width = 0.8 / n_perturbations;

hold on;
for p_idx = 1:n_perturbations
    bar(x_pos + (p_idx - (n_perturbations+1)/2) * bar_width, ...
        max_rel_sensitivity(:, p_idx), bar_width, ...
        'FaceColor', colors(p_idx,:), ...
        'DisplayName', sprintf('±%.0f%%', perturbations(p_idx)*100));
end
hold off;

set(gca, 'XTick', 1:n_params, 'XTickLabel', param_names, 'XTickLabelRotation', 45);
ylabel('Max Relative Sensitivity (dimensionless)');
title(sprintf('Maximum Parameter Sensitivity - Model %s', model_type));
legend('Location', 'best');
grid on;
saveas(gcf, sprintf('figures/sensitivity_max_Model_%s.png', model_type));

%% save sensitivity results
save(sprintf('results/sensitivity_Model_%s.mat', model_type), 'sensitivity_results');
fprintf('\n\nSensitivity results saved to results/sensitivity_Model_%s.mat\n', model_type);

%% Generate sensitivity report
fid = fopen(sprintf('results/sensitivity_Model_%s_report.txt', model_type), 'w');
fprintf(fid, 'Sensitivity Analysis Report - Model %s\n', model_type);
fprintf(fid, '=====================================\n\n');
fprintf(fid, 'Date: %s\n\n', datetime('now'));

fprintf(fid, 'Baseline Parameters:\n');
for i = 1:n_params
    fprintf(fid, '  %s = %.4f\n', param_names(i), model_params.p(i));
end
fprintf(fid, '\n');

fprintf(fid, 'Perturbation levels tested: ');
fprintf(fid, '±%.0f%% ', perturbations*100);
fprintf(fid, '\n\n');

fprintf(fid, 'SENSITIVITY ANALYSIS RESULTS:\n');
fprintf(fid, '-----------------------------\n\n');

for p_idx = 1:n_perturbations
    fprintf(fid, 'Perturbation Level: ±%.0f%%\n', perturbations(p_idx)*100);
    fprintf(fid, '------------------------\n');
    
    [sorted_sens, sort_idx_temp] = sort(mean_rel_sensitivity(:, p_idx), 'descend');
    
    for i = 1:n_params
        if ~isnan(sorted_sens(i))
            fprintf(fid, '%d. %s\n', i, param_names(sort_idx_temp(i)));
            fprintf(fid, '   Mean |S_rel|: %.4f (dimensionless)\n', sorted_sens(i));
            fprintf(fid, '   Max |S_rel|:  %.4f (dimensionless)\n', max_rel_sensitivity(sort_idx_temp(i), p_idx));
        end
    end
    fprintf(fid, '\n');
end

p_idx_largest = n_perturbations;
fprintf(fid, 'OVERALL RANKING (based on ±%.0f%% perturbation):\n', perturbations(p_idx_largest)*100);
fprintf(fid, '-------------------------------------------\n');
for i = 1:n_params
    if ~isnan(sorted_SI(i))
        fprintf(fid, '%d. %s\n', i, param_names(sort_idx(i)));
        fprintf(fid, '   Mean |S_rel|: %.4f (dimensionless)\n', sorted_SI(i));
        fprintf(fid, '   Max |S_rel|:  %.4f (dimensionless)\n', max_rel_sensitivity(sort_idx(i), p_idx_largest));
    end
end
fprintf(fid, '\n');

fprintf(fid, 'INTERPRETATION:\n');
fprintf(fid, '---------------\n');
fprintf(fid, '- Relative sensitivity S_rel = (∂DO/∂p) * (p/DO) is dimensionless\n');
fprintf(fid, '- It measures the percentage change in DO per percentage change in parameter\n');
fprintf(fid, '- Higher |S_rel| = parameter has stronger influence on DO predictions\n');
fprintf(fid, '- Time-varying sensitivity indicates when during the simulation each parameter matters most\n');
fprintf(fid, '- Focus optimization and uncertainty analysis on most sensitive parameters\n');
fprintf(fid, '\n');

fprintf(fid, 'RECOMMENDATIONS:\n');
fprintf(fid, '----------------\n');
fprintf(fid, 'High sensitivity parameters (should be carefully calibrated):\n');
high_sens_idx = find(mean_rel_sensitivity(:, end) > median(mean_rel_sensitivity(:, end)));
for i = 1:length(high_sens_idx)
    fprintf(fid, '  - %s\n', param_names(high_sens_idx(i)));
end
fprintf(fid, '\nLow sensitivity parameters (could potentially be fixed or have wider bounds):\n');
low_sens_idx = find(mean_rel_sensitivity(:, end) <= median(mean_rel_sensitivity(:, end)));
for i = 1:length(low_sens_idx)
    fprintf(fid, '  - %s\n', param_names(low_sens_idx(i)));
end

fclose(fid);
fprintf('Sensitivity report saved to results/sensitivity_Model_%s_report.txt\n\n', model_type);

fprintf('=== Sensitivity Analysis Complete ===\n');

%%
