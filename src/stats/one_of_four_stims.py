"""Pick one of the four stimulation parameters at random and compare against zero to check if STIM truly has an effect."""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

from csvstats.ttest import ttest_dep, ttest_ind
from csvstats.utils.save_stats import dict_to_pdf

n_iterations = 1000
subject_column = "Subject"
group_column = "Intervention"
speeds = ["SSV", "FV"]
tableNames = ['matchedCycles', 'unmatchedCycles', 'CGAM']

params = (
    "StepLengths_GR_Sym",
    "SwingDurations_GR_Sym",
    "CGAM",
)

for tableName in tableNames:
    for speed in speeds:
        data_path = f"results/stats/Cohensd_CSVs/cohensd_{tableName}_{speed}.csv"    

        df = pd.read_csv(data_path)
        df = df[df['Intervention'] != 'SHAM1']

        bootstrap_dfs = []
        all_results_stim_vs_sham = []
        all_results_stim = []
        
        columns_to_keep_all = [subject_column, group_column] + list(params)
        columns_to_keep = []
        for col in columns_to_keep_all:
            if col in df.columns:
                columns_to_keep.append(col)

        df = df[columns_to_keep]

        df_nosham2 = df[df['Intervention'] != 'SHAM2'].copy()
        df_sham2 = df[df['Intervention'] == 'SHAM2'].copy()
        df_nosham2["Intervention"] = "STIM"

        # For 1000 iterations, get the data frame with one randomly sampled intervention per subject, and run the t-test on it.
        for i in range(n_iterations):
            # For each subject, randomly select one intervention
            sample = df_nosham2.groupby(subject_column).sample(n=1, random_state=i)
            ttest_df = pd.concat([sample, df_sham2])
            results_stim_vs_sham = ttest_dep(ttest_df, group_column, "_", repeated_measures_column=subject_column, filename=None)
            results_stim = ttest_ind(sample, group_column, "_", filename=None)    
            # Move "iteration_n" field to be first
            results_stim_vs_sham = {'iteration_n': i, **results_stim_vs_sham}
            all_results_stim_vs_sham.append(results_stim_vs_sham)
            results_stim = {'iteration_n': i, **results_stim}
            all_results_stim.append(results_stim)
            ttest_df["iteration_n"] = i
            bootstrap_dfs.append(ttest_df)

        # Save the data and computation results
        all_samples_df = pd.concat(bootstrap_dfs)
        save_path_all_samples = f"results/stats/ttest_results/all_samples_df_{n_iterations}_{tableName}_{speed}.csv"
        # Reorder the columns - move "iteration_n" from last to first
        col_names = all_samples_df.columns.to_list()
        col_names.insert(0, col_names.pop())  # Remove last column and insert it at the beginning
        all_samples_df = all_samples_df[col_names]
        all_samples_df.to_csv(save_path_all_samples, index=False)
        save_path_all_results = f"results/stats/ttest_results/all_ttests_bootstrapped_{n_iterations}_{tableName}_{speed}.pdf"
        dict_to_pdf(all_results_stim_vs_sham, filename=save_path_all_results)

        # For each test, get the p-value, STIM group mean and std.
        p_values = {}
        means = {}
        stds = {}
        for param in params:
            p_values[param] = []
            means[param] = []
            stds[param] = []

        means_sham = {
            "FV": {
                "StepLengths_GR_Sym": 0.17,
                "SwingDurations_GR_Sym": 0.24,
                "CGAM": 0.05
            },
            "SSV": {
                "StepLengths_GR_Sym": 0.07,
                "SwingDurations_GR_Sym": -0.01,
                "CGAM": 0.07
            }
        }

        fig_save_path = "results/stats/ttest_results/scatter_{param}_{n_iterations}_{tableName}_{speed}.png"
        for param in params:
            if param not in all_results_stim[i].keys():
                continue

            for i in range(n_iterations):    
                p_val = all_results_stim[i][param]["p_value"]
                mean_val = all_results_stim[i][param]["summary_statistics"]["grouped"]["mean"]["STIM"]
                std_val = all_results_stim[i][param]["summary_statistics"]["grouped"]["std_dev"]["STIM"]
                p_values[param].append(p_val)
                means[param].append(mean_val)
                stds[param].append(std_val)

            p_values[param] = np.array(p_values[param])
            means[param] = np.array(means[param])
            stds[param] = np.array(stds[param])
            deltas = means_sham[speed][param] - means[param]

            sham_greater = deltas > 0
            sham_smaller = deltas < 0

            perc_p_below_alpha = sum(p_values[param] < 0.05) / len(p_values[param]) * 100

            plt.figure()
            x = np.array(range(0, n_iterations))
            plt.scatter(x[sham_greater], p_values[param][sham_greater], c="red", label="SHAM > STIM")
            plt.scatter(x[sham_smaller], p_values[param][sham_smaller], c="blue", label="STIM > SHAM")
            plt.xlabel("Iteration")
            plt.ylabel('p values')
            plt.legend(loc="upper left")

            plt.title(f"{speed} One random STIM vs. 0 ({round(perc_p_below_alpha,0)}% < 0.05): {param}")
            plt.axhline(y=0.05, c="black")    

            fig_save_path_param = fig_save_path.format(param=param, n_iterations=n_iterations, speed=speed, tableName=tableName)
            plt.savefig(fig_save_path_param)
            plt.close()

        # Run t-test to see if the standard deviations are different than the averaged STIM std.
        avg_stim_std_devs = {
            "FV": {
                "StepLengths_GR_Sym": 0.43,
                "SwingDurations_GR_Sym": 0.36,
                "CGAM": 0.15
            },
            "SSV": {
                "StepLengths_GR_Sym": 0.40,
                "SwingDurations_GR_Sym": 0.29,
                "CGAM": 0.30
            }
        }
        filename_format = "results/stats/ttest_results/one_random_stim_vs_avg_stim_std/{param}_{n_iterations}_iterations_{tableName}_{speed}.pdf"
        for param in params:
            if param not in stds.keys():
                continue

            stds_df = pd.DataFrame(stds[param], columns=[f"std_{param}"])    
            filename = filename_format.format(param=param, n_iterations=n_iterations, speed=speed, tableName=tableName)
            std_ttest_result = ttest_ind(stds_df, 
                                        "", 
                                        "_", 
                                        filename=filename, 
                                        popmean=avg_stim_std_devs[speed][param],
                                        render_plot=True)
            
        # Run t-test to see if the p-values are different than the averaged p-values
        avg_stim_p_values = {
            "FV": {
                "StepLengths_GR_Sym": 0.052,
                "SwingDurations_GR_Sym": 0.01,
                "CGAM": 0.0009
            },
            "SSV": {
                "StepLengths_GR_Sym": 0.4859,
                "SwingDurations_GR_Sym": 0.0161,
                "CGAM": 0.254
            }
        }
        filename_format = "results/stats/ttest_results/one_random_stim_vs_avg_stim_p_values/{param}_{n_iterations}_iterations_{tableName}_{speed}.pdf"
        for param in params:
            if param not in p_values.keys():
                continue

            p_values_df = pd.DataFrame(p_values[param], columns=[f"p_{param}"])
            filename = filename_format.format(param=param, n_iterations=n_iterations, speed=speed, tableName=tableName)
            p_ttest_result = ttest_ind(p_values_df, 
                                    "", 
                                    "_", 
                                    filename=filename, 
                                    popmean=avg_stim_p_values[speed][param],
                                    render_plot=True)

        # Run t-test to see if the mean values are different than the averaged means
        avg_stim_means = {
            "FV": {
                "StepLengths_GR_Sym": 0.2,
                "SwingDurations_GR_Sym": 0.22,
                "CGAM": 0.13
            },
            "SSV": {
                "StepLengths_GR_Sym": 0.06,
                "SwingDurations_GR_Sym": 0.17,
                "CGAM": 0.03
            }
        }
        filename_format = "results/stats/ttest_results/one_random_stim_vs_avg_stim_means/{param}_{n_iterations}_iterations_{tableName}_{speed}.pdf"
        for param in params:
            if param not in means.keys():
                continue

            means_df = pd.DataFrame(means[param], columns=[f"means_{param}"])
            filename = filename_format.format(param=param, n_iterations=n_iterations, speed=speed, tableName=tableName)
            means_ttest_result = ttest_ind(means_df, 
                                        "", 
                                        "_", 
                                        filename=filename, 
                                        popmean=avg_stim_means[speed][param],
                                        render_plot=True)