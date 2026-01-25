clear all
close all

%% Read all the data

% miniDOT data
%reading the excel file and second sheet
inputDOT = readtable('WaterQualityData.xlsx', 'Sheet','miniDOT data', 'Range', ...
    'C6:F122606', 'VariableNamesRange', 6);
outputDOT = readtable('WaterQualityData.xlsx', 'Sheet','miniDOT data', 'Range', ...
    'H6:K126925', 'VariableNamesRange', 6);

% hydraulic data
hydraulic_input = readtable('WaterQualityData.xlsx', 'Sheet','HydraulicData', ...
    'Range', 'C5:D124792');
hydraulic_output = readtable('WaterQualityData.xlsx', 'Sheet','HydraulicData', ...
    'Range', 'G5:H129345');
discharge_upstream = readtable('WaterQualityData.xlsx', 'Sheet','HydraulicData', ...
    'Range', 'K9:M15');
discharge_downstream = readtable('WaterQualityData.xlsx', 'Sheet','HydraulicData', ...
    'Range', 'K23:M32');
discharge_SMichele = readtable('WaterQualityData.xlsx', 'Sheet','HydraulicData', ...
    'Range', 'O9:Q13');

% ARPAV hourly data
% for this one I changed the column labels for the global solar radiation
% in the Excel file itself, to 'Global solar radiation
% Campodarsego/Legnaro' respectively
arpavHourly = readtable('WaterQualityData.xlsx', 'Sheet','ARPAV_hourly', ...
    'Range', 'C:I', 'VariableNamesRange', 3);

%% hourly averages for miniDOT data
% Calculate hourly averages for input/output
inputDOT.Date = dateshift(inputDOT.Datetime, 'start', 'day');
outputDOT.Date = dateshift(outputDOT.Datetime, 'start', 'day');
inputDOT.Hour = hour(inputDOT.Datetime);
outputDOT.Hour = hour(outputDOT.Datetime);

hourlyInputAverages = varfun(@mean, inputDOT, 'InputVariables', ...
    {'DissolvedOxygen', 'WaterTemperature'}, 'GroupingVariables', {'Date', 'Hour'});
hourlyOutputAverages = varfun(@mean, outputDOT, 'InputVariables', ...
    {'DissolvedOxygen', 'WaterTemperature'}, 'GroupingVariables', {'Date', 'Hour'});

% outer join again
hourlyDOTAverages = outerjoin(hourlyInputAverages, hourlyOutputAverages, 'Keys', {'Date', 'Hour'}, 'MergeKeys', true);
% rename variables for clarity
hourlyDOTAverages.Properties.VariableNames = {'Date', 'Hour', 'GroupCountInput', 'AvgDissolvedOxygenInput', 'AvgWaterTemperatureInput', 'GroupCountOutput', 'AvgDissolvedOxygenOutput', 'AvgWaterTemperatureOutput'};

% Replace NaN in hourly group counts with 0
hourlyDOTAverages.GroupCountInput = fillmissing(hourlyDOTAverages.GroupCountInput, 'constant', 0);
hourlyDOTAverages.GroupCountOutput = fillmissing(hourlyDOTAverages.GroupCountOutput, 'constant', 0);
% Sum group counts for hourly averages
hourlyDOTAverages.GroupCount = hourlyDOTAverages.GroupCountInput + hourlyDOTAverages.GroupCountOutput;

% Calculate hourly oxygen difference
hourlyDOTAverages.OxygenDiff = hourlyDOTAverages.AvgDissolvedOxygenInput - hourlyDOTAverages.AvgDissolvedOxygenOutput;

%% hourly averages for hydraulic data
% Calculate hourly averages for hydraulic data
hydraulic_input.Date = dateshift(hydraulic_input.Datetime, 'start', 'day');
hydraulic_output.Date = dateshift(hydraulic_output.Datetime, 'start', 'day');
hydraulic_input.Hour = hour(hydraulic_input.Datetime);
hydraulic_output.Hour = hour(hydraulic_output.Datetime);
hourlyHydraulicInputAverages = varfun(@mean, hydraulic_input, 'InputVariables', ...
    {'WaterSurfaceElevation'}, 'GroupingVariables', {'Date', 'Hour'});
hourlyHydraulicOutputAverages = varfun(@mean, hydraulic_output, 'InputVariables', ...
    {'WaterSurfaceElevation'}, 'GroupingVariables', {'Date', 'Hour'});
% outer join for hydraulic data
hourlyHydraulicAverages = outerjoin(hourlyHydraulicInputAverages, hourlyHydraulicOutputAverages, 'Keys', {'Date', 'Hour'}, 'MergeKeys', true);
% rename variables for clarity
hourlyHydraulicAverages.Properties.VariableNames = {'Date', 'Hour', 'GroupCountInput', 'AvgWaterSurfaceElevationInput', 'GroupCountOutput', 'AvgWaterSurfaceElevationOutput'};
hourlyHydraulicAverages.GroupCountInput = fillmissing(hourlyHydraulicAverages.GroupCountInput, 'constant', 0);
hourlyHydraulicAverages.GroupCountOutput = fillmissing(hourlyHydraulicAverages.GroupCountOutput, 'constant', 0);
hourlyHydraulicAverages.GroupCount = hourlyHydraulicAverages.GroupCountInput + hourlyHydraulicAverages.GroupCountOutput;

%% ARPAV
% it's already hourly averages, let's just do the Date and Hour thing for merging
arpavHourly.Date = dateshift(arpavHourly.Datetime, 'start', 'day');
arpavHourly.Hour = hour(arpavHourly.Datetime);
%% merging time!
% merge miniDot with hydraulic data based on date and hour
mergedData = outerjoin(hourlyDOTAverages, hourlyHydraulicAverages, 'Keys', {'Date', 'Hour'}, 'MergeKeys', true);
% merge that with ARPAV hourly
mergedData = outerjoin(mergedData, arpavHourly, 'Keys', {'Date', 'Hour'}, 'MergeKeys', true);

%% miniDOT plots
% DOT over time
figure;
plot(inputDOT.Datetime, inputDOT.DissolvedOxygen);
hold on
plot(outputDOT.Datetime, outputDOT.DissolvedOxygen);
hold off
legend('INPUT', 'OUTPUT')
xlabel('Datetime');
ylabel('Dissolved oxygen [mg/L]');
title('Dissolved Oxygen at input/output over time');
grid on;
saveas(gcf, 'DissolvedOxygenOverTime.png');

% Temperature over time
% Plot Temperature over time
figure;
plot(inputDOT.Datetime, inputDOT.WaterTemperature);
hold on
plot(outputDOT.Datetime, outputDOT.WaterTemperature);
hold off
legend('INPUT', 'OUTPUT')
xlabel('Datetime');
ylabel('Water Temperature [°C]');
title('Water Temperature at input/output over time');
grid on;
saveas(gcf, 'WaterTemperatureOverTime.png');

% Differences of daily/hourly output & input DOT over time
% merge Date and Hour into one column for plotting
hourlyDOTAverages.DateHour = datetime(hourlyDOTAverages.Date.Year, hourlyDOTAverages.Date.Month, hourlyDOTAverages.Date.Day, hourlyDOTAverages.Hour, 0, 0);
% plot
figure;
plot(hourlyDOTAverages.DateHour, hourlyDOTAverages.OxygenDiff);
xlabel('Datetime');
ylabel('Dissolved oxygen difference [mg/L]');
title('Difference of hourly averages of dissolved oxygen between Input and Output');
grid on;
saveas(gcf, 'HourlyDissolvedOxygenDiffOverTime.png');

% DOT vs Temperature
figure;
scatter(inputDOT.WaterTemperature, inputDOT.DissolvedOxygen);
hold on
scatter(outputDOT.WaterTemperature, outputDOT.DissolvedOxygen);
hold off
legend('INPUT', 'OUTPUT')
xlabel('Temperature [°C]');
ylabel('Dissolved oxygen [mg/L]');
title('Dissolved Oxygen dependence on Temperature');
grid on;
saveas(gcf, 'DissolvedOxygenOverTemperature.png');

%% hydraulic data plots

% Plot Water Surface Elevation over time
figure;
plot(hydraulic_input.Datetime, hydraulic_input.WaterSurfaceElevation);
hold on
plot(hydraulic_output.Datetime, hydraulic_output.WaterSurfaceElevation);
hold off
legend('INPUT', 'OUTPUT')
xlabel('Datetime');
ylabel('Water Surface Elevation [m.a.m.s.l.]');
title('Water Surface Elevation at input/output over time');
grid on;
saveas(gcf, 'WaterSurfaceElevationOverTime.png');

% DOT vs Water surface elevation
% this is super useless
figure;
scatter(mergedData.AvgWaterSurfaceElevationInput, mergedData.AvgDissolvedOxygenInput);
%hold on
%plot(mergedData.AvgWaterSurfaceElevationOutput, mergedData.AvgDissolvedOxygenOutput);
%hold off
legend('INPUT', 'OUTPUT')
xlabel('Water Surface Elevation [m.a.m.s.l.]');
ylabel('Dissolved oxygen [mg/L]');
title('Dissolved Oxygen dependence on Water Surface Elevation at Input');
grid on;
saveas(gcf, 'DissolvedOxygenOverWaterSurfaceElevationInput.png');

% DOT vs Water surface elevation
% this is super useless
figure;
scatter(mergedData.AvgWaterSurfaceElevationOutput, mergedData.AvgDissolvedOxygenOutput);
xlabel('Water Surface Elevation [m.a.m.s.l.]');
ylabel('Dissolved oxygen [mg/L]');
title('Dissolved Oxygen dependence on Water Surface Elevation at Output');
grid on;
saveas(gcf, 'DissolvedOxygenOverWaterSurfaceElevationOutput.png');

%% ARPAV plots
mergedData.DateHour = datetime(mergedData.Date.Year, mergedData.Date.Month, mergedData.Date.Day, mergedData.Hour, 0, 0);

% plot air and water temperatures over time
figure;
plot(mergedData.DateHour, mergedData.Tair_mean);
hold on
plot(mergedData.DateHour, mergedData.AvgWaterTemperatureInput);
plot(mergedData.DateHour, mergedData.AvgWaterTemperatureOutput);
hold off
xlabel('Datetime');
ylabel('Temperature [°C]');
legend('Air temperature', 'Water Temperature IN', 'Water Temperature OUT')
title('Air and Water Temperature (hourly averages) over Time');
grid on;
saveas(gcf, 'AirWaterTemperatureOverTime.png');

% plot minimum and maximum relative Air humidity over time
figure;
plot(mergedData.DateHour, mergedData.Min_AirRel_Humidity);
hold on
plot(mergedData.DateHour, mergedData.Max_AirRel_Humidity);
hold off
xlabel('Datetime');
ylabel('relative Air humidity [%]');
legend('Min', 'Max')
title('Hourly minimum and maximum relative air humidity over time');
grid on;
saveas(gcf, 'RelAirHumidityOverTime.png');

% Plot global solar radiation in Campodarsego and Legnaro over time
figure;
plot(mergedData.DateHour, mergedData.GlobalSolarRadiationCampodarsego, '-o');
hold on
plot(mergedData.DateHour, mergedData.GlobalSolarRadiationLegnaro, '-o');
hold off
xlabel('Datetime');
ylabel('Global Solar Radiation [W/m^2]');
legend('Campodarsego', 'Legnaro');
title('Global Solar Radiation over Time');
grid on;
saveas(gcf, 'GlobalSolarRadiationOverTime.png');

% plot precipitation over time
figure;
plot(mergedData.DateHour, mergedData.Precipitation);
xlabel('Datetime');
ylabel('Precipitation [mm]');
title('Precipitation over Time');
grid on;
saveas(gcf, 'PrecipitationOverTime.png');

%% compute correlations between parameters
% remove all of the GroupCount variables from mergedData
% Remove all GroupCount columns from mergedData
groupCountColumns = contains(mergedData.Properties.VariableNames, 'GroupCount');
mergedData = removevars(mergedData, groupCountColumns);

pat = ["oxygen", "date", "hour"]
varNames = mergedData.Properties.VariableNames(~contains(mergedData.Properties.VariableNames, pat, 'IgnoreCase', true))


% Initialize an array to store correlation results
correlationResults = table();


% Loop through each variable in mergedData
for i = 1:length(varNames)
    Var = varNames{i};

    Vars = table(mergedData.AvgDissolvedOxygenInput, mergedData.(Var), 'VariableNames', {'A', 'B'});
    Vars = rmmissing(Vars); % Remove NaN entries from Vars
    
    % Remove entries where either AvgDissolvedOxygenInput or Var is NaN
    %validEntries = mergedData(~isnan(mergedData.AvgDissolvedOxygenInput) & ~isnan(mergedData.(Var)), :);
    
    % Compute correlation if there are valid entries
    if height(Vars) > 0
        correlationValue = corr(Vars.A, Vars.B);
        correlationResults = [correlationResults; table({Var}, correlationValue, 'VariableNames', {'Variable', 'Correlation'})];
    end
end

% Display the correlation results
disp('Correlation Results between AvgDissolvedOxygenInput and other variables:');
disp(correlationResults); 

%% Compute Correlation between AvgDissolvedOxygen and all other Vars
% Exclude pattern-matching variables
% excluding the Datetimerelated columns and the DissolvedOxygen itself
pat = ["oxygen","date","hour"];
allNames = mergedData.Properties.VariableNames;
varNames = allNames(~contains(allNames, pat, 'IgnoreCase', true));

% Extract arrays
IN = mergedData.AvgDissolvedOxygenInput;     
OUT = mergedData.AvgDissolvedOxygenOutput;          % column vector
% column vector
DATA = mergedData{:, varNames};                      % numeric matrix (rows x vars)

% Compute correlations in one call using pairwise row handling
corrValsInput = corr(IN, DATA, 'Rows', 'pairwise');       % 1 x numVars
corrValsOutput = corr(OUT, DATA, 'Rows', 'pairwise');       % 1 x numVars

% Build result table (preallocated)
correlationResultsIn = table(varNames(:), corrValsInput(:), ...
    'VariableNames', {'Variable', 'Correlation'});
correlationResultsOut = table(varNames(:), corrValsOutput(:), ...
    'VariableNames', {'Variable', 'Correlation'});

% Display
disp('Correlation Results between AvgDissolvedOxygenInput and other variables:');
disp(correlationResultsIn);
disp('Correlation Results between AvgDissolvedOxygenOutput and other variables:');
disp(correlationResultsOut);



