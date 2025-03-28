############################
## CONFIG
############################
# Read the config file
config_path <- "Y:\\LabMembers\\MTillman\\GitRepos\\Stroke-R01\\RCode\\config.toml"
config <- configr::read.config(file = config_path)

# Set the working directory and source the helper functions
setwd(config$paths$wd)
files <- list.files(config$paths$helper_functions, pattern = "\\.R$", full.names = TRUE)
sapply(files, source)

# TESTING ONLY
files <- list.files("Y:\\LabMembers\\MTillman\\GitRepos\\Stroke-R01\\RCode\\plotter", pattern = "\\.R$", full.names = TRUE)
sapply(files, source)

# Create the folder to store the results of this analysis
analysis_name <- config$analysis_name
analysis_output_folder = file.path(config$paths$root_save, analysis_name)
if (!dir.exists(analysis_output_folder)) {
  dir.create(analysis_output_folder)
}

# Initialize variables
# Factors
plot_grouping_factors <- config$plots$grouping_factors
fill_factor <- config$plots$fill_factor
factors_in_model <- config$stats$factors_in_model
all_factors_col_names <- config$all_factor_columns

# Levels in each factor
factors_levels_order <- config$factors_levels_order
factors_levels_to_remove <- config$factors_levels_to_remove

# Paths
data_file_path <- config$paths$data_file
colors<- config$plots$colors

# Linear mixed model & estimated marginal means formulae
lmer_formula <- config$stats$lmer_formula
emmeans_formula <- config$stats$emmeans_formula

#############################
## READ IN DATA
#############################
# Read the CSV file
all_data <- read_data(data_file_path, all_factors_col_names) # From fcns.R

# Order the levels of each factor for which the levels order was specified
factors_with_specified_levels_order <- names(factors_levels_order)
for (factor_name in factors_with_specified_levels_order) {
  all_data[[factor_name]] <- factor(all_data[[factor_name]], levels = factors_levels_order[[factor_name]])
}

# Remove any levels of any factors that we don't want to analyze
factors_with_levels_to_remove <- names(factors_levels_to_remove)
for (factor_name in factors_with_levels_to_remove) {
  all_data <- remove_levels(all_data, factor_name, factors_levels_to_remove[[factor_name]])
}

# Get the column names of interest from the data table
outcome_measures_cols <- names(all_data)[sapply(all_data, function(x) !is.factor(x))]
col_name = outcome_measures_cols[1]

emmeans_list <- list()
comps_list <- list()

# Run the hypothesis testing and plotting functions
for (col_name in outcome_measures_cols) {

  if (!is.numeric(all_data[[col_name]])) {
    print(paste("The column", col_name, " is not numeric."))
    next
  }

  # Open the PDF device
  # pdf(file = file.path(analysis_output_folder, paste0(col_name, ".pdf")))

  # Create a data frame for the current column
  curr_data <- curr_col_data(all_data, col_name, all_factors_col_names)

  # Create the lmer model
  lmer_model <- make_model(curr_data, lmer_formula, col_name)

  # Get the marginal means
  emmeans <- get_emmeans(lmer_model, emmeans_formula, col_name)
  emmeans_list[[col_name]] <- emmeans

  # Hypothesis tests
  comps <- hyp_tests(lmer_model, curr_data, emmeans, col_name)
  comps_list[[col_name]] <- comps
  
  # Plot the data in a way that will work with significant difference bars
  collapsed_df <- collapse_data(curr_data, c())
  plot_result <- plot_for_diff_bars(collapsed_df, plot_grouping_factors, col_name, plot_type = "scatter", fill_factor=fill_factor)
  plotted_df <- plot_result$df
  gp_no_sig_diff_bars <- plot_result$gp

  # Add the significant difference bars
  result <- plot_sig_diff_bars(gp_no_sig_diff_bars, plotted_df, comps, plot_grouping_factors, 
                      col_name, vert_bar_height=0.05, text_offset=0.02, min_y_distance=0.05, text_size=2, 
                      show_p_values = TRUE, horz_offset = 0.008)
  gp_sig_diff_bars <- result$plot
  print(gp_sig_diff_bars)
  sig_diff_bars_df <- result$sig_diff_bars_df
  
  # Bar graph with difference bars
  # bar_graph_with_diff_bars(curr_data, comps, plot_grouping_factors, col_name, emmeans, colors=colors, fill_factor=fill_factor, min_y_distance=0.05, text_size=2)

  # Line plots
  line_plot_from_lmer(curr_data, col_name, lmer_model)

  # Bar graphs
  bar_plot_from_lmer(curr_data, col_name, lmer_model, comps)

  # Interaction plots
  interaction_plot_from_lmer(curr_data, col_name, lmer_model, comps, x_axis_factor = plot_grouping_factors[1], color_factor = plot_grouping_factors[2], facet_factors = NULL)

  # Summarize and plot the residuals of the model
  summarize_model(lmer_model)

  # Create the histogram
  plot_all_histograms(curr_data, plot_grouping_factors, col_name, fill_factor = fill_factor)

  dev.off()
}

# toml_file_path <- "config_transverse_gaitphases.toml"
# latex_table_path <- file.path(pkg_output_folder, "latex_table.tex")
# 
# # Named list to map long factor names to shorter names
# name_mapping <- list(
#   "Gait_Phase" = list(
#     "LeftDoubleSupport" = "LDS",
#     "RightDoubleSupport" = "RDS",
#     "LeftSingleSupport" = "LSS",
#     "RightSingleSupport" = "RSS"
#   ),
#   "Task" = list(
#     "Straight_Line_Gait" = "SLG",
#     "TWW_Preplanned" = "PP",
#     "TWW_Latecued" = "LC"
#   )
# )
# 
# config <- read.config(file = toml_file_path, file.type = "toml")
# vars_list <- config$vars
# 
# # Generate the latex table
# latex_output <- generate_latex_table(comps_list, emmeans_list, name_mapping, vars_list, n_decimals=3)
# string_vector <- unlist(latex_output)
# writeLines(string_vector, latex_table_path)
