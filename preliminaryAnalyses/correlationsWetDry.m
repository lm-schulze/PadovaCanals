clear all
close all

%% Read all the data
dataHourly = loadDataAverages('WaterQualityData.xlsx', 'hourly');
head(dataHourly)

%% compute correlations between parameters
[correlationResultsIn, correlationResultsOut] = avgDissolvedOxygenCorrelations(dataHourly);

%% check if there are gaps in the date-time hourly data
% make a DateHour column to better check time
% although it might be super unncecessary, but idk
dataHourly.DateHour = datetime(dataHourly.Date.Year, dataHourly.Date.Month, ...
    dataHourly.Date.Day, dataHourly.Hour, 0, 0);

% filter rows to where sum_Precipitation is not NaN
dataHourlyCheck = dataHourly(~isnan(dataHourly.sum_Precipitation), :);

% check if there are gaps in the hourly data
timeStamps = dataHourlyCheck.DateHour; 
gaps = find(diff(timeStamps) > 1); % hopefully identify gaps greater than 1 hour
numGaps = numel(gaps);
disp(numGaps);
% 2 gaps, which we need to account for when determining the wet/dry 
% weather condition :((

%% compute wet/dry weather
n = height(dataHourly);

% Compute 24-hour rolling sum including current hour.
% For hourly series use movsum with window 24: previous 23 hours + current
p = dataHourly.sum_Precipitation;
rolling24 = movsum(p, [23 0], 'Endpoints','shrink');  % I think that makes the most sense for endpoint handling here?

% for each 24h window, check if p(i-23:i) has any NaN entries
nanCount = movsum(isnan(p), [23 0], 'Endpoints','shrink');  % 
% window is complete when nanCount == 0
completeWindow = (nanCount == 0);

% Find times t where rolling24 >= 5 mm
idx_high = find(rolling24 >= 5 & completeWindow);

% prepare logical vector 
isRainy= false(n, 1);

% For each > 5mm index find the first non-zero precipitation within the preceding 24 hours (including current)
% and mark from that start for exactly 4 days (96 hours) ????
% though it still doesn't make a ton of sense to me
% and this is probably a super inefficient way of doing this
durHours = 4*24; % 96
for k = 1:numel(idx_high)
    i = idx_high(k);
    % determine window start index (24 hours preceding t, include t)
    % shouldn't contain any NaNs bc of the previous filtering
    winStart = max(1, i-23);
    winRange = winStart:i;
    % find first non-zero precip in that window
    nz = find(p(winRange) > 0, 1, 'first');
    if isempty(nz)
        % no non-zero precipitation in the preceding 24h 
        % (shouldn't happen because rolling24>=5 and window complete)
        % but just to be sure
        continue
    end
    startIdx = winRange(1) + (nz - 1);
    endIdx = min(n, startIdx + durHours - 1);
    isRainy(startIdx:endIdx) = true;
end

% create categorical array to store wet/dry/undefined weather
% Missing weather is due to the gaps in precipitation data
WeatherRegime = categorical(repmat("Missing", n, 1), ...
                            ["Wet","Dry","Missing"], ...
                            'Protected', true);

WeatherRegime(isRainy) = "Wet";
WeatherRegime(~isRainy & completeWindow) = "Dry";

% Add column to output table
dataHourly.WeatherRegime = WeatherRegime;
dataHourly.aggPrecipitation = rolling24; % just to check that the aggregation was done correctly

fprintf('Number of rainy hours: %d\n', sum(isRainy))

% write dataHourly to csv file
writetable(dataHourly, 'WaterQualityDataWithRain.csv');

%% split dataset into dry and wet weather table based on isRainy column
dataWet = dataHourly(dataHourly.WeatherRegime == "Wet", :);
dataDry = dataHourly(dataHourly.WeatherRegime == "Dry", :);

[dryCorrelationResultsIn, dryCorrelationResultsOut] = avgDissolvedOxygenCorrelations(dataDry);
[wetCorrelationResultsIn, wetCorrelationResultsOut] = avgDissolvedOxygenCorrelations(dataWet);

