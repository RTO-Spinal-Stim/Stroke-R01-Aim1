function [preprocessed_data_new] = fixMuscleMappings(preprocessed_data)

%% PURPOSE: REARRANGE THE MUSCLE NAMES FOR SPECIFIC SUBJECTS & INTERVENTIONS

preprocessed_data_new.RVL = preprocessed_data.RTA;
preprocessed_data_new.LHAM = preprocessed_data.RVL;
preprocessed_data_new.LRF = preprocessed_data.LHAM;
preprocessed_data_new.LMG = preprocessed_data.LRF;
preprocessed_data_new.LTA = preprocessed_data.LMG;
preprocessed_data_new.LVL = preprocessed_data.LTA;
preprocessed_data_new.RTA = preprocessed_data.LVL;