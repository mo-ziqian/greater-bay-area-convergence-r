# Analysis of Economic Convergence in the Guangdong-Hong Kong-Macao Greater Bay Area
## Release Package

---

###  Directory Structure
- `greater_bay_area_economy.R`: Main analysis script (directly runnable)
- `empirical_results_summary.csv`: Summary of core empirical findings
- `REPRODUCTION.md`: Reproduction guide and data preparation instructions
- `UPLOAD_CHECKLIST.md`: Pre-upload checklist
- `.gitignore`: Configuration to prevent accidental upload of raw data and local temporary files
- `data/raw/`: Directory for storing raw data (empty by default)
- `output/`: Directory for script outputs (empty by default)

---

###  Analysis Contents
- Data cleaning and wide-to-long format conversion
- Descriptive statistics and visualization
- σ-convergence test (coefficient of variation, range ratio)
- Absolute β-convergence test (cross-sectional OLS regression)
- Robustness tests and results summary

---

###  Quick Usage Guide
1. Place the 4 raw Excel files into the `data/raw/` directory (see `REPRODUCTION.md` for detailed requirements).
2. Run the main analysis script: `greater_bay_area_economy.R`.
3. All results (tables, figures, and outputs) will be automatically saved to the `output/` directory.
