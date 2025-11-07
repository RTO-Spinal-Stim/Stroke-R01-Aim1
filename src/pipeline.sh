#!/bin/bash
# Run with "bash src/pipeline.sh" from the project directory

# Run the MATLAB pipeline to generate CSVs from raw data
matlab -batch "addpath('src/overground'); mainAllSubjects"

# Compute CGAM
python3 src/stats/cgam_pipeline.py

# Compute Cohen's d
python3 src/stats/create_cohensd_df.py

# Compute stats (using average stim)
python3 src/stats/csv-stats.py

# Look at the one of four stims
python3 src/stats/one_of_four_stims.py