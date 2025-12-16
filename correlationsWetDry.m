clear all
close all

%% Read all the data
dataHourly = loadDataAverages('WaterQualityData.xlsx', 'hourly');
head(dataHourly)

%% compute correlations between parameters
[correlationResultsIn, correlationResultsOut] = avgDissolvedOxygenCorrelations(dataHourly)

%% check if there are gaps in the date-time hourly data
% make a DateHour column to better check time
% although it might be super unncecessary, but idk
dataHourly.DateHour = datetime(dataHourly.Date.Year, dataHourly.Date.Month, ...
    dataHourly.Date.Day, dataHourly.Hour, 0, 0);

% check if there are gaps in the hourly data
timeStamps = dataHourly.DateHour; 
gaps = find(diff(timeStamps) > 1); % hopefully identify gaps greater than 1 hour
numGaps = numel(gaps);
display(numGaps);
% looks good, which means the method for wet/dry weather should be fine?

%% compute wet/dry weather
n = height(dataHourly);

% Compute 24-hour rolling sum including current hour.
% For hourly series use movsum with window 24: previous 23 hours + current
p = dataHourly.sum_Precipitation;
rolling24 = movsum(p, [23 0], 'Endpoints','shrink');  % I think that makes the most sense for endpoint handling here?

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
dataHourly.aggPrecipitation = rolling24; % just to check that the aggregation was done correctly

fprintf('Number of rainy hours: %d\n', sum(isRainy))

% write dataHourly to csv file
writetable(dataHourly, 'WaterQualityDataWithRain.csv');

%% split dataset into dry and wet weather table based on isRainy column
dataWet = dataHourly(dataHourly.IsRainy, :);
dataDry = dataHourly(~dataHourly.IsRainy, :);

[dryCorrelationResultsIn, dryCorrelationResultsOut] = avgDissolvedOxygenCorrelations(dataDry)
[wetCorrelationResultsIn, wetCorrelationResultsOut] = avgDissolvedOxygenCorrelations(dataWet)

