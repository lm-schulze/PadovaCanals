function [correlationResultsIn, correlationResultsOut] = avgDissolvedOxygenCorrelations(dataInput)
% avgDissolvedOxygenCorrelations  Compute and display pairwise correlations.
%   [corrIn, corrOut] = avgDissolvedOxygenCorrelations(dataHourly)
%   - dataHourly : table that contains variables such as
%       AvgDissolvedOxygenInput, AvgDissolvedOxygenOutput, Date, Hour, GroupCount...
%   - corrIn  : table of (Variable, Correlation) between AvgDissolvedOxygenInput and each variable
%   - corrOut : table of (Variable, Correlation) between AvgDissolvedOxygenOutput and each variable
%
% The function:
%   - removes any variables whose names contain 'GroupCount'
%   - excludes date/hour/oxygen columns from the candidate variable list
%   - computes correlations using pairwise row handling (corr with 'Rows','pairwise')
%   - displays the results

% Input validation
if ~istable(dataInput)
    error('Input must be a table.');
end

% Remove GroupCount columns
grpMask = contains(dataInput.Properties.VariableNames, 'GroupCount', 'IgnoreCase', true);
data = removevars(dataInput, find(grpMask));

% Build list of candidate variables (exclude date/hour/oxygen)
excludePattern = ["oxygen","date","hour"];
allNames = data.Properties.VariableNames;
varMask = ~contains(allNames, excludePattern, 'IgnoreCase', true);
varNames = allNames(varMask);

% Ensure AvgDissolvedOxygenInput/Output exist
hasIn  = ismember('AvgDissolvedOxygenInput', data.Properties.VariableNames);
hasOut = ismember('AvgDissolvedOxygenOutput', data.Properties.VariableNames);
if ~hasIn && ~hasOut
    error('Table must contain at least one of AvgDissolvedOxygenInput or AvgDissolvedOxygenOutput.');
end

% Filter varNames to numeric variables only
isNumericVar = false(size(varNames));
for k = 1:numel(varNames)
    v = data.(varNames{k});
    isNumericVar(k) = isnumeric(v) || islogical(v);
end
varNames = varNames(isNumericVar);

% Prepare results
correlationResultsIn = table([],[], 'VariableNames', {'Variable','Correlation'});
correlationResultsOut = table([],[], 'VariableNames', {'Variable','Correlation'});

% If there are no candidate variables, return empty tables
if isempty(varNames)
    disp('No numeric variables found to correlate with dissolved oxygen.');
    return
end

% Compute correlations using vectorized call if possible
DATA = data{:, varNames}; % numeric matrix (rows x vars), will error if mixed types but filtered above

% Correlations for AvgDissolvedOxygenInput
if hasIn
    IN = data.AvgDissolvedOxygenInput;
    corrValsIn = corr(IN, DATA, 'Rows', 'pairwise'); % 1 x numVars
    correlationResultsIn = table(varNames(:), corrValsIn(:), 'VariableNames', {'Variable','Correlation'});
    disp('Correlation Results between AvgDissolvedOxygenInput and other variables:');
    disp(correlationResultsIn);
else
    disp('AvgDissolvedOxygenInput not present; skipping input correlations.');
end

% Correlations for AvgDissolvedOxygenOutput
if hasOut
    OUT = data.AvgDissolvedOxygenOutput;
    corrValsOut = corr(OUT, DATA, 'Rows', 'pairwise'); % 1 x numVars
    correlationResultsOut = table(varNames(:), corrValsOut(:), 'VariableNames', {'Variable','Correlation'});
    disp('Correlation Results between AvgDissolvedOxygenOutput and other variables:');
    disp(correlationResultsOut);
else
    disp('AvgDissolvedOxygenOutput not present; skipping output correlations.');
end

end


