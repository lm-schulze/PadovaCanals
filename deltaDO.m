clear all
close all

%% load the table from WaterQualityDataWithRain.csv
dataHourly = readtable('WaterQualityDataWithRain.csv');
head(dataHourly)

%% let's try 

%% DO diff check

% compute differences between successive values of AvgDissolvedOxygenInput
DODiffIn = diff(dataHourly.AvgDissolvedOxygenInput);
DODiffOut = diff(dataHourly.AvgDissolvedOxygenOutput);
% check that the corresponding Datetime difference is 1h exactly, set to NaN if not
dataHourly.DateHour = datetime(dataHourly.Date.Year, dataHourly.Date.Month, ...
    dataHourly.Date.Day, dataHourly.Hour, 0, 0);
timeDiff = diff(dataHourly.DateHour);

DODiffIn(timeDiff ~= hours(1)) = NaN;
DODiffOut(timeDiff ~= hours(1)) = NaN;

% append NaN entry to DODiff & add to table
dataHourly.DODiffIn = [NaN; DODiffIn];
dataHourly.DODiffOut = [NaN; DODiffOut];
head(dataHourly)

%%
xlsxFile = 'WaterQualityData.xlsx';
mode ='hourly';

% Read sheets (same ranges as before)
inputDOT  = readtable(xlsxFile, 'Sheet','miniDOT data', 'Range', 'C6:F122606', 'VariableNamesRange', 6);
outputDOT = readtable(xlsxFile, 'Sheet','miniDOT data', 'Range', 'H6:K126925', 'VariableNamesRange', 6);
hydraulic_input  = readtable(xlsxFile, 'Sheet','HydraulicData', 'Range', 'C5:D124792');
hydraulic_output = readtable(xlsxFile, 'Sheet','HydraulicData', 'Range', 'G5:H129345');
arpavHourly = readtable(xlsxFile, 'Sheet','ARPAV_hourly', 'Range', 'C:I', 'VariableNamesRange', 3);

% Ensure datetime columns are datetime
if ~isdatetime(inputDOT.Datetime);  inputDOT.Datetime  = datetime(inputDOT.Datetime); end
if ~isdatetime(outputDOT.Datetime); outputDOT.Datetime = datetime(outputDOT.Datetime); end
if ~isdatetime(hydraulic_input.Datetime);  hydraulic_input.Datetime  = datetime(hydraulic_input.Datetime); end
if ~isdatetime(hydraulic_output.Datetime); hydraulic_output.Datetime = datetime(hydraulic_output.Datetime); end
if ~isdatetime(arpavHourly.Datetime); arpavHourly.Datetime = datetime(arpavHourly.Datetime); end

% Create grouping variables depending on mode
switch mode
    case 'hourly'
        % Date and Hour grouping
        inputDOT.Date  = dateshift(inputDOT.Datetime, 'start', 'day');
        outputDOT.Date = dateshift(outputDOT.Datetime, 'start', 'day');
        inputDOT.Hour  = hour(inputDOT.Datetime);
        outputDOT.Hour = hour(outputDOT.Datetime);
        grpVarsDOT = {'Date','Hour'};

        hydraulic_input.Date  = dateshift(hydraulic_input.Datetime, 'start', 'day');
        hydraulic_output.Date = dateshift(hydraulic_output.Datetime, 'start', 'day');
        hydraulic_input.Hour  = hour(hydraulic_input.Datetime);
        hydraulic_output.Hour = hour(hydraulic_output.Datetime);
        grpVarsHyd = {'Date','Hour'};

        arpavHourly.Date = dateshift(arpavHourly.Datetime, 'start', 'day');
        arpavHourly.Hour = hour(arpavHourly.Datetime);
        grpVarsArpav = {'Date','Hour'};

    case 'daily'
        % Date-only grouping
        inputDOT.Date  = dateshift(inputDOT.Datetime, 'start', 'day');
        outputDOT.Date = dateshift(outputDOT.Datetime, 'start', 'day');
        grpVarsDOT = {'Date'};

        hydraulic_input.Date  = dateshift(hydraulic_input.Datetime, 'start', 'day');
        hydraulic_output.Date = dateshift(hydraulic_output.Datetime, 'start', 'day');
        grpVarsHyd = {'Date'};

        arpavHourly.Date = dateshift(arpavHourly.Datetime, 'start', 'day');
        grpVarsArpav = {'Date'};
end

%% Aggregate miniDOT (input and output)
inputVarsDOT = {'DissolvedOxygen','WaterTemperature', 'DOPercentSaturation'};
InputAverages = varfun(@mean, inputDOT, 'InputVariables', inputVarsDOT, 'GroupingVariables', grpVarsDOT);
OutputAverages = varfun(@mean, outputDOT, 'InputVariables', inputVarsDOT, 'GroupingVariables', grpVarsDOT);

dotTable = outerjoin(InputAverages, OutputAverages, 'Keys', grpVarsDOT, 'MergeKeys', true);

% Standardize names for clarity
otherNames = {'GroupCountInput','AvgDissolvedOxygenInput','AvgWaterTemperatureInput','AvgDOPercentSaturationInput','GroupCountOutput','AvgDissolvedOxygenOutput','AvgWaterTemperatureOutput','AvgDOPercentSaturationOutput'};
newNames = [grpVarsDOT otherNames];
if numel(dotTable.Properties.VariableNames) == numel(newNames)
    dotTable.Properties.VariableNames = newNames;
end
