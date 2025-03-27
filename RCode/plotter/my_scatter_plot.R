my_scatter_plot <- function(df, grouping_factors, first_grouping_factor_displayname, 
                            col_name, colors=colors, patterns=patterns, fill_factor=fill_factor, 
                            outline_factor=outline_factor, x_axis_factors=x_axis_factors) {
  # PURPOSE: PLOT A SCATTER PLOT COMPATIBLE WITH SIGNIFICANT DIFFERENCE BARS
  # Inputs:
  #   df: data frame with collapsed data
  #   grouping_factors: factors to group by
  #   first_grouping_factor_displayname: display name for first grouping factor
  #   col_name: column name for y values
  #   colors: colors for each group
  #   patterns: patterns for each group
  #   fill_factor: factor to use for fill
  #   outline_factor: factor to use for outline
  #   x_axis_factors: factors to use for x axis
  #
  # Outputs:
  #   gp: ggplot object

  # Initialize variables
  if (!is.null(fill_factor)) {
    gp <- ggplot(df, aes(x = x, y = y, fill = fill_factor))
  } else {
    gp <- ggplot(df, aes(x = x, y = y))
  }

  # Run the plot
  gp <- gp +
    geom_point(aes(shape = shape_factor), size = size, color = color) + 
    scale_x_continuous(
      breaks = df$group_mean_x,
      labels = df[[first_grouping_factor_displaynames]]
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      axis.ticks.x = element_blank(),
      axis.title.x = element_blank()
    )
}