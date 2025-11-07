# Run the MATLAB pipeline to generate CSVs from raw data
Push-Location src/overground
matlab -batch "mainAllSubjects"
Pop-Location

# Compute CGAM
python src/stats/cgam_pipeline.py

# Compute Cohen's d
python src/stats/create_cohensd_df.py

# Compute stats (using average stim)
python src/stats/csv-stats.py

# Look at the one of four stims
python src/stats/one_of_four_stims.py