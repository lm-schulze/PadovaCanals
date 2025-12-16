function [mergedData, dotTable, hydraulicTable, arpavTable] = loadDataAverages(xlsxFile, mode, rmGroupCounts)
% loadDataAverages  Load Excel data and compute merged averages.
%   [mergedData, dotTable, hydraulicTable, arpavTable] = processWaterQuality(xlsxFile, mode)
%     xlsxFile - filename of the Excel workbook (char or string)
%     mode     - 'hourly' (default) or 'daily'
%     rmGroupCounts - Boolean, (default True), whether to remove the GroupCount columns
%     left from the averages
%
%
%   Outputs:
%     mergedData     - merged table aggregated per mode (Date+Hour for hourly, Date for daily)
%     dotTable       - aggregated miniDOT table (input+output merged)
%     hydraulicTable - aggregated hydraulic table (input+output merged)
%     arpavTable     - ARPAV aggregated table

if nargin < 2 || isempty(mode)
    mode = 'hourly';
end
mode = validatestring(lower(mode), {'hourly','daily'});

if nargin < 3 || isempty(rmGroupCounts)
    rmGroupCounts = true;
end

% Validate file input
if ~(ischar(xlsxFile) || isStringScalar(xlsxFile))
    error('Provide the Excel filename as a string.');
end
xlsxFile = char(xlsxFile);

%% Read sheets (same ranges as before)
inputDOT  = readtable(xlsxFile, 'Sheet','miniDOT data', 'Range', 'C6:F122606', 'VariableNamesRange', 6);
outputDOT = readtable(xlsxFile, 'Sheet','miniDOT data', 'Range', 'H6:K126925', 'VariableNamesRange', 6);
hydraulic_input  = readtable(xlsxFile, 'Sheet','HydraulicData', 'Range', 'C5:D124792');
hydraulic_output = readtable(xlsxFile, 'Sheet','HydraulicData', 'Range', 'G5:H129345');
arpavHourly = readtable(xlsxFile, 'Sheet','ARPAV_hourly', 'Range', 'C:I', 'VariableNamesRange', 3);

%% Ensure datetime columns are datetime
if ~isdatetime(inputDOT.Datetime);  inputDOT.Datetime  = datetime(inputDOT.Datetime); end
if ~isdatetime(outputDOT.Datetime); outputDOT.Datetime = datetime(outputDOT.Datetime); end
if ~isdatetime(hydraulic_input.Datetime);  hydraulic_input.Datetime  = datetime(hydraulic_input.Datetime); end
if ~isdatetime(hydraulic_output.Datetime); hydraulic_output.Datetime = datetime(hydraulic_output.Datetime); end
if ~isdatetime(arpavHourly.Datetime); arpavHourly.Datetime = datetime(arpavHourly.Datetime); end

%% Create grouping variables depending on mode
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
inputVarsDOT = {'DissolvedOxygen','WaterTemperature'};
InputAverages = varfun(@mean, inputDOT, 'InputVariables', inputVarsDOT, 'GroupingVariables', grpVarsDOT);
OutputAverages = varfun(@mean, outputDOT, 'InputVariables', inputVarsDOT, 'GroupingVariables', grpVarsDOT);

dotTable = outerjoin(InputAverages, OutputAverages, 'Keys', grpVarsDOT, 'MergeKeys', true);

% Standardize names for clarity
otherNames = {'GroupCountInput','AvgDissolvedOxygenInput','AvgWaterTemperatureInput', ...
                  'GroupCountOutput','AvgDissolvedOxygenOutput','AvgWaterTemperatureOutput'};
newNames = [grpVarsDOT otherNames];
if numel(dotTable.Properties.VariableNames) == numel(newNames)
    dotTable.Properties.VariableNames = newNames;
end


% Fill missing group counts if present and compute GroupCount and OxygenDiff if available
if ismember('GroupCountInput', dotTable.Properties.VariableNames)
    dotTable.GroupCountInput  = fillmissing(dotTable.GroupCountInput,  'constant', 0);
end
if ismember('GroupCountOutput', dotTable.Properties.VariableNames)
    dotTable.GroupCountOutput = fillmissing(dotTable.GroupCountOutput, 'constant', 0);
end
if ismember('GroupCountInput', dotTable.Properties.VariableNames) && ismember('GroupCountOutput', dotTable.Properties.VariableNames)
    dotTable.GroupCount = dotTable.GroupCountInput + dotTable.GroupCountOutput;
end
if ismember('AvgDissolvedOxygenInput', dotTable.Properties.VariableNames) && ismember('AvgDissolvedOxygenOutput', dotTable.Properties.VariableNames)
    dotTable.OxygenDiff = dotTable.AvgDissolvedOxygenInput - dotTable.AvgDissolvedOxygenOutput;
end

%% Aggregate hydraulic data
hydVars = {'WaterSurfaceElevation'};
HydInputAverages = varfun(@mean, hydraulic_input, 'InputVariables', hydVars, 'GroupingVariables', grpVarsHyd);
HydOutputAverages = varfun(@mean, hydraulic_output, 'InputVariables', hydVars, 'GroupingVariables', grpVarsHyd);

hydraulicTable = outerjoin(HydInputAverages, HydOutputAverages, 'Keys', grpVarsHyd, 'MergeKeys', true);
hydraulicTable.Properties.VariableNames = [grpVarsHyd {'GroupCountInput', 'AvgWaterSurfaceElevationInput', 'GroupCountOutput', 'AvgWaterSurfaceElevationOutput'}];

% Rename fill counts and compute total count
if ismember('GroupCountInput', hydraulicTable.Properties.VariableNames)
    hydraulicTable.GroupCountInput  = fillmissing(hydraulicTable.GroupCountInput,  'constant', 0);
end
if ismember('GroupCountOutput', hydraulicTable.Properties.VariableNames)
    hydraulicTable.GroupCountOutput = fillmissing(hydraulicTable.GroupCountOutput, 'constant', 0);
end
if ismember('GroupCountInput', hydraulicTable.Properties.VariableNames) && ismember('GroupCountOutput', hydraulicTable.Properties.VariableNames)
    hydraulicTable.GroupCount = hydraulicTable.GroupCountInput + hydraulicTable.GroupCountOutput;
end

%% Aggregate ARPAV (already hourly in sheet; just group/mean in case of daily mode)
arpavMean = varfun(@mean, arpavHourly, 'InputVariables', setdiff(arpavHourly.Properties.VariableNames, [{'Datetime'},{grpVarsArpav{:}}, {'Precipitation'}]), 'GroupingVariables', grpVarsArpav);
% Merge grouping vars back into arpavMean naming convention is handled by varfun

% compute daily sum of 'Precipitation' variable and store in table arpavSum to be
% joined with arpavMean later
arpavSum = varfun(@sum, arpavHourly, 'InputVariables', 'Precipitation', 'GroupingVariables', grpVarsArpav);

arpavTable = outerjoin(arpavMean, arpavSum, 'Keys', grpVarsArpav, 'MergeKeys', true);

%% Merge everything
mergedData = outerjoin(dotTable, hydraulicTable, 'Keys', grpVarsDOT, 'MergeKeys', true);
% mergedData keys may be group vars; ensure consistent keys with arpav
mergedData = outerjoin(mergedData, arpavTable, 'Keys', grpVarsDOT, 'MergeKeys', true);

% get rid of all the GroupCount vars
if rmGroupCounts
    grpMask = contains(mergedData.Properties.VariableNames, 'GroupCount', 'IgnoreCase', true);
    mergedData = removevars(mergedData, find(grpMask));
end
end
