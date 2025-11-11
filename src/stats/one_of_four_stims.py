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
tableNames = ['matchedCycles', 'unmatchedCycles']

params = (
    "StepLengths_GR_Sym",
    "SwingDurations_GR_Sym",
    "CGAM_all",
    # "CGAM_EMG",
    "CGAM_GR",
    "CGAM_JointAngles"
)

# Means of the SHAM group
MEANS_SHAM = {
    "FV": {
        "StepLengths_GR_Sym": 0.17,
        "SwingDurations_GR_Sym": 0.24,
        "CGAM_all": 0.05,
        "CGAM_GR": 0.18,
        "CGAM_JointAngles": 0.13
    },
    "SSV": {
        "StepLengths_GR_Sym": 0.07,
        "SwingDurations_GR_Sym": -0.01,
        "CGAM_all": 0.07,
        "CGAM_GR": -0.036,
        "CGAM_JointAngles": 0.2
    }
}

# Std. deviation of the average stim
AVG_STIM_STD_DEVS = {
    "FV": {
        "StepLengths_GR_Sym": 0.43,
        "SwingDurations_GR_Sym": 0.36,
        "CGAM_all": 0.15,
        "CGAM_GR": 0.45,
        "CGAM_JointAngles": 0.22
    },
    "SSV": {
        "StepLengths_GR_Sym": 0.40,
        "SwingDurations_GR_Sym": 0.29,
        "CGAM_all": 0.30,
        "CGAM_GR": 0.38,
        "CGAM_JointAngles": 0.16
    }
}

# P values vs zero of the average stim
AVG_STIM_P_VALUES = {
    "FV": {
        "StepLengths_GR_Sym": 0.052,
        "SwingDurations_GR_Sym": 0.01,
        "CGAM_all": 0.0009,
        "CGAM_GR": 0.1294,
        "CGAM_JointAngles": 0.0003
    },
    "SSV": {
        "StepLengths_GR_Sym": 0.4859,
        "SwingDurations_GR_Sym": 0.0161,
        "CGAM_all": 0.254,
        "CGAM_GR": 0.775,
        "CGAM_JointAngles": 0.12
    }
}

# Means of the average stim group
AVG_STIM_MEANS = {
    "FV": {
        "StepLengths_GR_Sym": 0.2,
        "SwingDurations_GR_Sym": 0.22,
        "CGAM_all": 0.13,
        "CGAM_GR": 0.16,
        "CGAM_JointAngles": 0.22
    },
    "SSV": {
        "StepLengths_GR_Sym": 0.06,
        "SwingDurations_GR_Sym": 0.17,
        "CGAM_all": 0.03,
        "CGAM_GR": -0.025,
        "CGAM_JointAngles": 0.056
    }
}

def run_ttest_random_vs_averaged_value(all_param_values: dict, avg_stim_values: dict, column_prefix: str, params: list, n_iterations: int, speed: str, tableName: str, filename_format: str) -> dict:    
    for param in params:
        if param not in means.keys():
            continue

        df = pd.DataFrame(all_param_values[param], columns=[f"{column_prefix}_{param}"])
        filename = filename_format.format(param=param, n_iterations=n_iterations, speed=speed, tableName=tableName)
        result = ttest_ind(df, 
                            "", 
                            "_", 
                            filename=filename, 
                            popmean=avg_stim_values[speed][param],
                            render_plot=True)
        
def get_all_values_from_result_dict(result_dict: dict, param: str, key: str, n_iterations: int) -> np.array:
    values = []
    key = param + "." + key
    keys = key.split(".")
    for i in range(n_iterations):
        value = result_dict[i]
        for k in keys:
            value = value[k]
        values.append(value)

    return np.array(values)

def plot_significances(
                means_sham: dict,
                speed: str,
                param: str,
                means_stim: dict,
                p_values: dict,
                title_substring: str,
                n_iterations: int,
                tableName: str,
                fig_save_path: str):

    deltas = means_sham[speed][param] - means_stim[param]

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

    plt.title(f"{speed} {title_substring} ({round(perc_p_below_alpha,0)}% < 0.05): {param}")
    plt.axhline(y=0.05, c="black")    

    fig_save_path_param = fig_save_path.format(param=param, n_iterations=n_iterations, speed=speed, tableName=tableName)
    plt.savefig(fig_save_path_param)
    plt.close()

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
        p_values = {param: [] for param in params}
        means = {param: [] for param in params}
        stds = {param: [] for param in params}    
        p_values_stim_vs_sham = {param: [] for param in params}   
        fig_save_path = "results/stats/ttest_results/scatter_{param}_{n_iterations}_{tableName}_{speed}.png"
        fig_save_path_2sample = "results/stats/ttest_results/scatter_2sample_{param}_{n_iterations}_{tableName}_{speed}.png"
        for param in params:
            if param not in all_results_stim[i].keys():
                continue

            p_values[param] = get_all_values_from_result_dict(all_results_stim, param, "p_value", n_iterations)
            means[param] = get_all_values_from_result_dict(all_results_stim, param, "summary_statistics.grouped.mean.STIM", n_iterations)
            stds[param] = get_all_values_from_result_dict(all_results_stim, param, "summary_statistics.grouped.std_dev.STIM", n_iterations)

            p_values_stim_vs_sham[param] = get_all_values_from_result_dict(all_results_stim_vs_sham, param, "p_value", n_iterations)

            # One sample t-test plot
            plot_significances(
                MEANS_SHAM,
                speed=speed,
                param=param,
                means_stim=means,
                p_values=p_values,
                title_substring="Stim vs. 0",
                n_iterations=n_iterations,
                tableName=tableName,
                fig_save_path=fig_save_path
            )

            # Two sample t-test plot
            plot_significances(
                MEANS_SHAM,
                speed=speed,
                param=param,
                means_stim=means,
                p_values=p_values_stim_vs_sham,
                title_substring="STIM vs. SHAM",
                n_iterations=n_iterations,
                tableName=tableName,
                fig_save_path=fig_save_path_2sample
            )

        # Run t-test to see if the standard deviations are different than the averaged STIM std.        
        filename_format = "results/stats/ttest_results/one_random_stim_vs_avg_stim_std/{param}_{n_iterations}_iterations_{tableName}_{speed}.pdf"
        run_ttest_random_vs_averaged_value(
            stds,
            avg_stim_values = AVG_STIM_STD_DEVS,
            column_prefix="std",
            params=params,
            n_iterations=n_iterations,
            speed=speed,
            tableName=tableName,
            filename_format=filename_format
        )
            
        # Run t-test to see if the p-values are different than the averaged p-values        
        filename_format = "results/stats/ttest_results/one_random_stim_vs_avg_stim_p_values/{param}_{n_iterations}_iterations_{tableName}_{speed}.pdf"            
        run_ttest_random_vs_averaged_value(
            p_values,
            avg_stim_values = AVG_STIM_P_VALUES,
            column_prefix="p",
            params=params,
            n_iterations=n_iterations,
            speed=speed,
            tableName=tableName,
            filename_format=filename_format
        )

        # Run t-test to see if the mean values are different than the averaged means        
        filename_format = "results/stats/ttest_results/one_random_stim_vs_avg_stim_means/{param}_{n_iterations}_iterations_{tableName}_{speed}.pdf"
        run_ttest_random_vs_averaged_value(
            means,
            avg_stim_values = AVG_STIM_MEANS,
            column_prefix="means",
            params=params,
            n_iterations=n_iterations,
            speed=speed,
            tableName=tableName,
            filename_format=filename_format
        )