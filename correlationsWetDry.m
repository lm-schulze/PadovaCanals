clear all
close all

%% Read all the data
dataHourly = loadDataAverages('WaterQualityData.xlsx', 'hourly');
head(dataHourly)

%% compute correlations between parameters
[correlationResultsIn, correlationResultsOut] = avgDissolvedOxygenCorrelations(dataHourly)

%% compute wet/dry weather
n = height(dataHourly);

% Compute 24-hour rolling sum including current hour.
% For hourly series use movsum with window 24: previous 23 hours + current
p = dataHourly.sum_Precipitation;
rolling24 = movsum(p, [23 0], 'Endpoints','shrink');  % returns shorter edges; we'll treat edges as available

% Find times t where rolling24 >= 5 mm
idx_high = find(rolling24 >= 5);

% Prepare output logical vector (in sorted order)
isRainy= false(n, 1);

% For each such index find the first non-zero precipitation within the preceding 24 hours (including current)
% and mark from that start for exactly 4 days (96 hours)
durHours = 4*24; % 96
for k = 1:numel(idx_high)
    i = idx_high(k);
    % determine window start index (24 hours preceding t, include t)
    winStart = max(1, i-23);
    winRange = winStart:i;
    % find first non-zero precip in that window
    nz = find(p(winRange) > 0, 1, 'first');
    if isempty(nz)
        % no non-zero precipitation in the preceding 24h (should be rare because rolling24>=5 implies some non-zero)
        continue
    end
    startIdx = winRange(1) + (nz - 1);
    endIdx = min(n, startIdx + durHours - 1);
    isRainy(startIdx:endIdx) = true;
end

% Add column to output table (logical)
dataHourly.IsRainy = isRainy;
display(sum(isRainy))

%% split dataset into dry and wet weather table based on isRainy column
dataWet = dataHourly(dataHourly.IsRainy, :);
dataDry = dataHourly(~dataHourly.IsRainy, :);

[dryCorrelationResultsIn, dryCorrelationResultsOut] = avgDissolvedOxygenCorrelations(dataDry)
[wetCorrelationResultsIn, wetCorrelationResultsOut] = avgDissolvedOxygenCorrelations(dataWet)

