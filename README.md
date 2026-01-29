# Water Quality in Padova's Canals
Course project for *Nature in Context* on the Water quality in the canals of Padova. A.Y. 2025/26. Goal: Determine the main factors (human, natural) driving dissolved oxygen variability in the canals of Padova in dry and wet weather. (E.g. light, temperature, rainfall, hydraulic gate operation and water levels, …).

**Authors:**
- [@igoridelsohn](https://github.com/igoridelsohn)
- [@kuraszaleksandra](https://github.com/kuraszaleksandra)
- [@lauramoll2004](https://github.com/lauramoll2004)
- [@lm-schulze](https://github.com/lm-schulze)

## Project Outline:
Within this Project, we investigate the dissolved oxygen dynamics in Padova's canals using DO-measurement and weather data acquired between December 2022 and February 2024. Three different models of varying complexity were designed and tested, focussing on water temperature- and solar irradiance-dependent mechanisms (Photosynthesis, Re-aeration, Respiration), with one model describing the water-temperature dependence (labelled T-only), one describing the solar irradiance-dependence (I-only), and one describing both (TI). We perform a sensitivity analysis for each, and calibrate the parameters using Particle Swarm Optimization. The calibrated models are evaluated on different metrics (RMSE, NSE), and compared via AIC.

## Files & Folders
The project consists of the following files and folders:
- **data/**: Folder containing the data files.
  - `data/WaterQualityData.xlsx`: Original excel file containing the full, uncleaned data on DO, weather and hydraulic data.
  - `data/WaterQualityDataWithRain.csv`: CSV file containing the cleaned data on DO, weather and hydraulic data aggregated at hourly averages, as well as label for wet/dry weather conditions.
- **Model & Residual functions**:
  - `oxygen_model_I.m`, `oxygen_model_T.m`, `oxygen_model_TI.m`: Matlab functions defining the Dissolved Oxygen evolution ODEs of the 3 different models (using solar irradiance $I$, water temperature $T$, or both)
  - `residuals_oxygen_I.m`, `residuals_oxygen_T.m`, `residuals_oxygen_TI.m`: Matlab functions computing the residuals between the observed DO values and the ones obtained from integrating the ODEs for each of the models.
- **Optimization scripts**:
  - `DO_I_PSO.m`, `DO_T_PSO.m`, `DO_TI_PSO.m` : Matlab scripts fitting the model parameters for each of the models using Particle Swarm Optimization (PSO).
- **figures/**: folder containing all plots.
- **results/**: folder containing sensitivity analysis results and optimization results (parameter estimates, residuals, basic analytics).
- **preliminaryAnalysis/**: folder containing all files and scripts used for data cleaning & the preliminary explorations of the data and correlations.
