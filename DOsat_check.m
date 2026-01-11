clear all
close all

%% load the table from WaterQualityDataWithRain.csv
dataHourly = readtable('WaterQualityDataWithRain.csv');
DO_t = dataHourly.AvgDissolvedOxygenInput;
DO_pct_sat = dataHourly.AvgDOPercentSaturationInput;
T = dataHourly.AvgWaterTemperatureInput;

% Observed saturation DO from measurements
DOsat_obs = DO_t ./ (DO_pct_sat / 100);

% Weiss (1970) saturation DO
DOsat_weiss = DOsat_Weiss1970(T);

% check that points are valid
valid = isfinite(DOsat_obs(:)) & isfinite(DOsat_weiss(:)) & DO_pct_sat(:) > 0;
DOsat_obs_v   = DOsat_obs(valid);
DOsat_weiss_v = DOsat_weiss(valid);
T_v           = T(valid);


%% scatter plot

figure;
scatter(DOsat_obs_v, DOsat_weiss_v, 15, T_v, 'filled');
hold on;
plot([0 max(DOsat_obs_v)], [0 max(DOsat_obs_v)], 'r--', 'LineWidth', 1.2);
hold off;

xlabel('Observed DO_{sat} (mg/L)');
ylabel('Weiss (1970) DO_{sat} (mg/L)');
title('Comparison of Saturation DO: Observed vs Weiss (1970)');
colorbar;
ylabel(colorbar, 'Temperature (°C)');
axis equal;
grid on;

%% plot vs temp

figure;
scatter(T_v, DOsat_obs_v, 15, 'b', 'filled');
hold on;
scatter(T_v, DOsat_weiss_v, 15, 'r');
hold off;

xlabel('Temperature (°C)');
ylabel('DO_{sat} (mg/L)');
legend('Observed (from % saturation)', 'Weiss (1970)', 'Location', 'best');
title('Saturation DO vs Temperature');
grid on;

%% some stats

% Ensure column vectors and apply mask (assume valid is logical of size N×1)
obs = DOsat_obs(:);
wei = DOsat_weiss(:);
valid = isfinite(obs) & isfinite(wei) & (DO_pct_sat(:) > 0);

obs = obs(valid);
wei = wei(valid);

% Differences
d = obs - wei;           % signed difference
ad = abs(d);             % absolute difference

% Basic summaries
mean_abs = mean(ad);         % mean absolute difference
median_abs = median(ad);     % median absolute difference
max_abs = max(ad);           % maximum absolute difference
mean_signed = mean(d);       % mean signed difference (bias)
median_signed = median(d);   % median signed difference
prop_obs_gt_wei = mean(d > 0); % fraction where obs > weiss
n = numel(d);                % sample size

% Display results
fprintf('N = %d\n', n);
fprintf('Mean |diff| = %.4g, Median |diff| = %.4g, Max |diff| = %.4g\n', ...
        mean_abs, median_abs, max_abs);
fprintf('Mean diff = %.4g, Median diff = %.4g, prop(obs>wei) = %.3f\n', ...
        mean_signed, median_signed, prop_obs_gt_wei);