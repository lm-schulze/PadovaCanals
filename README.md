# Water Quality in Padova's Canals
Course project for *Nature in Context* on the Water quality in the canals of Padova. A.Y. 2025/26. Goal: Determine the main factors (human, natural) driving dissolved oxygen variability in the canals of Padova in dry and wet weather. (E.g. light, temperature, rainfall, hydraulic gate operation and water levels, …).

The project consists of the following files and folders:
- **Data files**:
  -`WaterQualityDataWithRain.csv`: CSV file containing the cleaned data on DO, weather and hydraulic data at hourly averages, as well as label for wet/dry weather conditions.
- **Model & Residual functions**:
  -`oxygen_model_I.m`, `oxygen_model_T.m`, `oxygen_model_TI.m`: Matlab functions defining the Dissolved Oxygen evolution ODEs of the 3 different models (using solar irradiance $I$, water temperature $T$, or both)
  -`residuals_oxygen_I.m`, `residuals_oxygen_T.m`, `residuals_oxygen_TI.m`: Matlab functions computing the residuals between the observed DO values and the ones obtained from integrating the ODEs for each of the models.
- **Optimization scripts**:
  -`DO_I_PSO.m`, `DO_T_PSO.m`, `DO_TI_PSO.m` : Matlab scripts fitting the model parameters for each of the models using Particle Swarm Optimization (PSO).
-**/figures/**: folder containing all plots.
-**/results/**: folder containing optimization results (parameter estimates, residuals, basic analytics).
-**/preliminaryAnalysis/**: folder containing all files and scripts used for data cleaning & the preliminary explorations of the data and correlations.
