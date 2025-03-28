plot_sig_diff_bars <- function(df, gp, comps, grouping_factors, col_name, emmeans, 
                                vert_bar_height=0.02, text_offset=0.01, bar_offsets=0.02,
                                min_y_distance=0.05, text_size=2, diff_bars_config=NULL, diff_bars_factors=NULL,
                                fig_dims=NULL, show_p_values=TRUE, horz_offset=0.008, p_cutoff=0.05, step_increase=0.1, panel_id=1) {
    # PURPOSE: Add significant difference bars to a plot
    # INPUTS:
    #   df: data frame with the following columns:
    #       - group_mean_x: mean x value for each group
    #       - group_mean_y: mean y value for each group
    #       - group_min_x: min x value for each group
    #       - group_max_x: max x value for each group
    #       - group_min_y: min y value for each group
    #       - group_max_y: max y value for each group
    #   gp: ggplot object
    #   comps: comparison object (output of lmer)
    #   grouping_factors: factors to use for grouping
    #   col_name: column name for y data
    #   emmeans: emmeans object
    #   vert_bar_height: height of vertical bars
    #   text_offset: offset for text
    #   bar_offsets: offset for bars
    #   min_y_distance: minimum distance between y values
    #   text_size: size of text
    #   diff_bars_config: configuration for significant difference bars
    #   diff_bars_factors: factors to use for significant difference bars
    #   fig_dims: dimensions of figure
    #   show_p_values: show p values
    #   horz_offset: horizontal offset for p values
    #   p_cutoff: p-value cutoff for significance
    #   step_increase: step increase for y values
    #   panel_id: panel id
    #
    # OUTPUTS:
    #   gp: ggplot object

    # Get the x data, p-values, and colors for the significant difference bars
    sig_diff_bars_x_df <- sig_diff_bars_x_data_and_colors(comps, grouping_factors, df, col_name, interactions=FALSE, diff_bars_config=diff_bars_config, diff_bars_factors=diff_bars_factors)

    # Get the y values for the significant difference bars
    sig_diff_bars_y_df <- sig_diff_bars_y_data(gp, df, comps, col_name, p_cutoff=p_cutoff,
                                                step_increase=step_increase, panel_id=panel_id, 
                                                vert_bar_height=vert_bar_height, min_y_distance=min_y_distance)

    # Add the significant difference bars to the plot
    gp <- plot_sig_diff_bars(gp, sig_diff_bars_x_df, sig_diff_bars_y_df, fig_dims=fig_dims, text_offset=text_offset, bar_offsets=bar_offsets,
                             text_size=text_size, show_p_values=show_p_values, horz_offset=horz_offset)
}