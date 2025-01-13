clc;
clearvars;
close all;

SUBJ_list = { '02', '03', '04', '05' }; %, '01','02', '03', '04', '05', '06', '08', '09', '10'];
TP_list = { 'PRE', 'POST' }; 
INTER_list = { '30_RMT', '30_TOL', '50_RMT', '50_TOL', 'SHAM1','SHAM2' }; 

inter_valid_names = containers.Map(INTER_list, ...
                          {'RMT30', 'TOL30', 'RMT50', 'TOL50', 'SHAM1', 'SHAM2'});

aim1_folder = "Y:\Spinal Stim_Stroke R01\AIM 1"; 
subj_path = fullfile(aim1_folder, 'Subject Data');
subj_path_prefix = 'Y:\Spinal Stim_Stroke R01\AIM 1\Subject Data\SS';
subj_save_path_prefix = 'Y:\LabMembers\MTillman\Code\From_Nicole\MEPs Processing AIM 1\SS';

A_Smers_processing_dataPrep;
B_Smers_P2P_AUC;
C_Smers_RecruitmentCurves;