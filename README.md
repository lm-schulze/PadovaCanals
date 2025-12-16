# Water Quality in Padova's Canals
Course project for *Nature in Context* on the Water quality in the canals of Padova. A.Y. 2025/26. Goal: Determine the main factors (human, natural) driving dissolved oxygen variability in the canals of Padova in dry and wet weather. (E.g. light, temperature, rainfall, hydraulic gate operation and water levels, …).

The project consists of the following files and folders:
- **WaterQualityData.xsxl**: Original excel spreadsheet containing data on Dissolved oxygen, hydraulic gate operation, weather conditions etc.
- **WaterQualityDataWithRain.csv**: CSV file containing the merged DO, weather and hydraulic data at hourly averages, as well as label for wet/dry weather conditions.
- **miniDOT_playground.m**: MATLAB code exploring the Dissolved Oxygen and Water temperature data.
- **preliminaryAnalysisPlots.m**: MATLAB code exploring the available data, creating preliminary plots of the available data.
- **loadDataAverages.m**: Function to simplify the loading and merge of daily or hourly data into one table.
- **avgDissolvedOxygenCorrelations.m**: Helper function to compute and display the linear correlation coefficients between Avg. Dissolved Oxygen and other data.
- **correlationsWetDry.m**: Determine wet or dry weather conditions and seperate data accordingly.
