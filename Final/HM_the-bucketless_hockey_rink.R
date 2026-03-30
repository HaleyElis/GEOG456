# ============================================
# Setup: Install and Load Libraries
# ============================================

library(sportyR)
library(ggplot2)
library(dplyr)
library(readr)
library(arrow)

# ============================================
# Section 1: Load Data
# ============================================

# Load BDC data
bdc_url <- "https://raw.githubusercontent.com/the-bucketless/bdc/refs/heads/main/data/pxp_womens_oly_2022_v2.csv"
bdc_pbp <- read_csv(bdc_url)

# Load NHL data
nhl_url <- "https://github.com/sportsdataverse/fastRhockey-data/blob/main/nhl/pbp/parquet/play_by_play_2023.parquet?raw=true"
nhl_shots <- read_parquet(nhl_url) %>%
  filter(event_type %in% c("GOAL", "SHOT", "MISS")) %>%
  mutate(
    is_goal = event_type == "GOAL",
    y = y * sign(x),
    x = abs(x)
  )

# ============================================
# Section 2: Plot a Line on the Rink
# ============================================

# Create base rink plot, then add layers
p_line <- geom_hockey("nhl") +
  geom_segment(
    aes(x = 35, y = 0, xend = 110, yend = 0),
    color = "purple",
    size = 2,
    lineend = "round"
  )

print(p_line)

# ============================================
# Section 3: Simple Scatter Plot - Shot Chart
# ============================================

RINK_LENGTH <- 200
RINK_WIDTH <- 85
teams <- c("Olympic (Women) - Canada", "Olympic (Women) - United States")

canada_usa_shots <- bdc_pbp %>%
  filter(
    event == "Shot",
    team_name %in% teams,
    opp_team_name %in% teams
  )

# Plot with basic coordinates
p_scatter_basic <- geom_hockey("nhl") +
  geom_point(
    data = canada_usa_shots,
    aes(x = x_coord, y = y_coord),
    color = "red",
    size = 2,
    alpha = 0.6
  )

print(p_scatter_basic)

# ============================================
# Section 4: Scatter Plot with Shifted Coordinates
# ============================================

# Adjust coordinate system (0-200 to -100 to 100, 0-85 to -42.5 to 42.5)
canada_usa_shots <- canada_usa_shots %>%
  mutate(
    x_adjusted = x_coord - RINK_LENGTH / 2,
    y_adjusted = y_coord - RINK_WIDTH / 2
  )

p_scatter_adjusted <- geom_hockey("nhl") +
  geom_point(
    data = canada_usa_shots,
    aes(x = x_adjusted, y = y_adjusted),
    color = "red",
    size = 2,
    alpha = 0.6
  )

print(p_scatter_adjusted)

# ============================================
# Section 5: Color by Team (Shot Chart)
# ============================================

canada_usa_shots <- canada_usa_shots %>%
  mutate(
    # Mirror one team's shots to the same side of the rink
    x_final = ifelse(team_name == teams[2], -x_adjusted, x_adjusted),
    y_final = ifelse(team_name == teams[2], -y_adjusted, y_adjusted),
    team_color = ifelse(team_name == teams[1], "red", "blue")
  )

p_scatter_colored <- geom_hockey("nhl") +
  geom_point(
    data = canada_usa_shots,
    aes(x = x_final, y = y_final, color = team_color),
    size = 3,
    alpha = 0.7
  ) +
  scale_color_identity() +
  theme(legend.position = "bottom")

print(p_scatter_colored)

# ============================================
# Section 6: Offensive Zone Plots (Side-by-side)
# ============================================

ozone_shots <- canada_usa_shots %>%
  filter(x_coord > 100)

p_ozone <- geom_hockey("nhl", display_range = "offensive zone") +
  geom_point(
    data = ozone_shots,
    aes(x = x_adjusted, y = y_adjusted, color = team_name),
    size = 3,
    alpha = 0.7
  ) +
  facet_wrap(~team_name) +
  scale_color_manual(
    values = c(
      "Olympic (Women) - Canada" = "red",
      "Olympic (Women) - United States" = "blue"
    ),
    guide = "none"
  ) +
  theme(
    strip.text = element_text(size = 12, face = "bold")
  )

print(p_ozone)

# ============================================
# Section 7: Arrow Plots - Pass Visualization
# ============================================

finland_pp_passes <- bdc_pbp %>%
  filter(
    team_name == "Olympic (Women) - Finland",
    event == "Play",
    situation_type == "5 on 4",
    !is.na(frame_id_1)
  ) %>%
  mutate(
    x_start = x_coord - RINK_LENGTH / 2,
    y_start = y_coord - RINK_WIDTH / 2,
    x_end = x_coord_2 - RINK_LENGTH / 2,
    y_end = y_coord_2 - RINK_WIDTH / 2
  )

p_arrows <- geom_hockey("nhl") +
  geom_segment(
    data = finland_pp_passes,
    aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
    arrow = arrow(length = unit(0.3, "cm"), type = "closed"),
    color = "purple",
    size = 1,
    alpha = 0.7
  )

print(p_arrows)

# ============================================
# Section 8: Endpoint-based Arrows
# ============================================

p_arrows_endpoints <- geom_hockey("nhl") +
  geom_segment(
    data = finland_pp_passes,
    aes(x = x_coord, y = y_coord, xend = x_coord_2, yend = y_coord_2),
    arrow = arrow(length = unit(0.3, "cm"), type = "closed"),
    color = "purple",
    size = 1,
    alpha = 0.7
  )

print(p_arrows_endpoints)

# ============================================
# Section 9: Wavy Arrows (Curved Movements)
# ============================================

p_player_movement <- geom_hockey("nhl") +
  # Zone exit (curved path)
  geom_smooth(
    aes(x = c(-35, 10), y = c(25, 35)),
    method = "loess",
    se = FALSE,
    color = "darkblue",
    size = 1.5,
    inherit.aes = FALSE
  ) +
  # Passing line
  geom_segment(
    aes(x = 10, y = 35, xend = 15, yend = 55),
    color = "black",
    linetype = "dotted",
    size = 1,
    inherit.aes = FALSE
  ) +
  # Zone entry (curved path)
  geom_smooth(
    aes(x = c(15, 65), y = c(55, 50)),
    method = "loess",
    se = FALSE,
    color = "darkblue",
    size = 1.5,
    inherit.aes = FALSE
  )

print(p_player_movement)

# ============================================
# Section 10: Rotation Example
# ============================================

p_rotated <- geom_hockey("nhl", rotation = 90) +
  geom_point(
    data = canada_usa_shots %>% slice(1:100),
    aes(x = x_adjusted, y = y_adjusted),
    color = "red",
    size = 2,
    alpha = 0.6
  )

print(p_rotated)

# ============================================
# Section 11: Complex Multi-Layer Plot
# ============================================

p_combined <- geom_hockey("nhl") +
  # Shot locations
  geom_point(
    data = canada_usa_shots %>% slice(1:200),
    aes(x = x_final, y = y_final, color = team_color, fill = team_color),
    size = 3,
    alpha = 0.6,
    shape = 21
  ) +
  # Pass arrows (subset for clarity)
  geom_segment(
    data = finland_pp_passes %>% slice(1:15),
    aes(x = x_start, y = y_start, xend = x_end, yend = y_end),
    arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
    color = "green",
    size = 0.8,
    alpha = 0.5
  ) +
  scale_color_identity() +
  scale_fill_identity() +
  theme(plot.title = element_text(hjust = 0.5, size = 14, face = "bold")) +
  labs(title = "Combined Shot and Pass Chart")

print(p_combined)

# ============================================
# Section 12: Display Range Examples
# ============================================

# Offensive zone zoom
p_ozone_zoom <- geom_hockey("nhl", display_range = "offensive zone") +
  geom_point(
    data = canada_usa_shots,
    aes(x = x_adjusted, y = y_adjusted),
    color = "red",
    size = 3,
    alpha = 0.7
  )

print(p_ozone_zoom)

# Defensive zone zoom
p_dzone_zoom <- geom_hockey("nhl", display_range = "defensive zone") +
  geom_point(
    data = canada_usa_shots,
    aes(x = x_adjusted, y = y_adjusted),
    color = "blue",
    size = 3,
    alpha = 0.7
  )

print(p_dzone_zoom)

# ============================================
# Section 13: Custom Function for Reusability
# ============================================

plot_hockey_chart <- function(data = NULL, 
                              x_col = "x",
                              y_col = "y",
                              color_col = NULL,
                              point_size = 3,
                              title = "Hockey Chart",
                              league = "nhl",
                              display_range = NULL) {
  
  # Start with base rink plot
  if (!is.null(display_range)) {
    p <- geom_hockey(league, display_range = display_range)
  } else {
    p <- geom_hockey(league)
  }
  
  # Add points
  if (!is.null(color_col)) {
    p <- p + geom_point(
      data = data,
      aes(x = .data[[x_col]], y = .data[[y_col]], color = .data[[color_col]]),
      size = point_size,
      alpha = 0.7
    )
  } else {
    p <- p + geom_point(
      data = data,
      aes(x = .data[[x_col]], y = .data[[y_col]]),
      color = "red",
      size = point_size,
      alpha = 0.7
    )
  }
  
  # Add theming
  p <- p +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5, face = "bold")) +
    labs(title = title)
  
  return(p)
}

# Example usage
p_example <- plot_hockey_chart(
  data = canada_usa_shots,
  x_col = "x_final",
  y_col = "y_final",
  color_col = "team_color",
  title = "Custom Function Example",
  league = "nhl"
)

print(p_example)

# ============================================
# Section 14: Check Available Leagues & Features
# ============================================

# Check if you can plot hockey
cani_plot_sport("hockey")

# Check which hockey leagues are available
cani_plot_league("PWHL")

# Check which features can be colored for NHL
cani_color_league_features("PWHL")

# ============================================
# BONUS: Custom Color Schemes
# ============================================

# Get available colors for PWHL
pwhl_colors <- cani_color_league_features("PWHL")

# Create a custom colored rink
p_custom_colors <- geom_hockey(
  "nhl",
  color_updates = list(
    boards = "#1f77b4",           # Blue boards
    center_line = "#ff7f0e",      # Orange center line
    goal_line = "#2ca02c",        # Green goal line
    ozone_ice = "#e7f3ff",        # Light blue offensive zone
    dzone_ice = "#ffe7f3",        # Light red defensive zone
    nzone_ice = "#fff7e7"         # Light yellow neutral zone
  )
) +
  geom_point(
    data = canada_usa_shots %>% slice(1:100),
    aes(x = x_adjusted, y = y_adjusted),
    color = "black",
    size = 2.5,
    alpha = 0.8
  ) +
  theme_minimal()

print(p_custom_colors)

# ============================================
# BONUS: Unit Conversion (CORRECTED)
# ============================================

# The correct parameter name is just the league parameter
# sportyR automatically handles unit conversions based on league
# NHL uses feet by default, IIHF uses meters

# For custom unit handling, use x_trans and y_trans for shifts
p_custom_units <- geom_hockey("nhl") +
  geom_point(
    data = canada_usa_shots %>% slice(1:50),
    aes(x = x_adjusted, y = y_adjusted),
    color = "red",
    size = 2,
    alpha = 0.6
  ) +
  labs(title = "NHL Rink (Feet)")

print(p_custom_units)

# ============================================
# BONUS: Heatmap with Updated Syntax
# ============================================

# Use after_stat() instead of ..level.. for newer ggplot2
p_heatmap <- geom_hockey("nhl") +
  stat_density2d(
    data = canada_usa_shots,
    aes(x = x_adjusted, y = y_adjusted, fill = after_stat(level)),
    geom = "polygon",
    alpha = 0.4
  ) +
  scale_fill_gradient(low = "yellow", high = "red") +
  labs(title = "Shot Location Density")

print(p_heatmap)

# ============================================
# BONUS: Hexbin Binning (CORRECTED)
# ============================================

# Use after_stat() instead of ..count..
p_hexbin <- geom_hockey("nhl") +
  geom_hex(
    data = canada_usa_shots,
    aes(x = x_adjusted, y = y_adjusted, fill = after_stat(count)),
    binwidth = c(10, 10),
    alpha = 0.7
  ) +
  scale_fill_gradient(low = "lightblue", high = "darkblue") +
  labs(title = "Shot Locations (Hexagonal Binning)")

print(p_hexbin)

# ============================================
# BONUS: Coordinate Transformation Function (CORRECTED)
# ============================================

# R uses # for comments, not triple quotes
transform_bdc_to_sportyR <- function(data, rink_length = 200, rink_width = 85) {
  # Convert BDC coordinates (0-200, 0-85) to sportyR coordinates (-100 to 100, -42.5 to 42.5)
  data %>%
    mutate(
      x_adjusted = x_coord - rink_length / 2,
      y_adjusted = y_coord - rink_width / 2
    )
}

# Test the function
canada_usa_shots_transformed <- transform_bdc_to_sportyR(canada_usa_shots)
head(canada_usa_shots_transformed)

# ============================================
# BONUS: Animation-Ready Data (CORRECTED)
# ============================================

# Check the columns in your data first
glimpse(canada_usa_shots)

# Prepare data for potential animation with gganimate
shot_timeline <- canada_usa_shots %>%
  mutate(
    time_minutes = clock_seconds / 60,
    period_label = paste("Period", period)
  ) %>%
  select(x_adjusted, y_adjusted, team_name, team_color, time_minutes, period_label, event, period)

# Static example showing periods - filter on the actual period column
p_by_period <- geom_hockey("nhl") +
  geom_point(
    data = shot_timeline %>% filter(period %in% c(1, 2)),
    aes(x = x_adjusted, y = y_adjusted, color = team_color),
    size = 2,
    alpha = 0.6
  ) +
  facet_wrap(~period_label) +
  scale_color_identity() +
  labs(title = "Shots by Period")

print(p_by_period)

# ============================================
# BONUS: Advanced Statistics & Visualization
# ============================================

# Shot efficiency by zone
shot_efficiency <- canada_usa_shots %>%
  mutate(
    zone = case_when(
      x_coord > 150 ~ "Offensive Zone",
      x_coord < 50 ~ "Defensive Zone",
      TRUE ~ "Neutral Zone"
    ),
    is_goal = event == "Goal"  # Assuming "Goal" is the event type for goals
  ) %>%
  group_by(team_name, zone) %>%
  summarise(
    total_shots = n(),
    goals = sum(is_goal, na.rm = TRUE),
    shot_pct = round(goals / total_shots * 100, 1),
    .groups = "drop"
  )

print(shot_efficiency)

# Visualize shot efficiency
p_efficiency <- shot_efficiency %>%
  ggplot(aes(x = zone, y = shot_pct, fill = team_name)) +
  geom_col(position = "dodge") +
  scale_fill_manual(
    values = c(
      "Olympic (Women) - Canada" = "red",
      "Olympic (Women) - United States" = "blue"
    )
  ) +
  theme_minimal() +
  labs(
    title = "Shot Efficiency by Zone",
    x = "Zone",
    y = "Shooting Percentage (%)",
    fill = "Team"
  )

print(p_efficiency)

# ============================================
# BONUS: Expected Goals Map (xG)
# ============================================

# Create shot location plot with size based on frequency
shot_frequency <- canada_usa_shots %>%
  mutate(
    x_bin = round(x_adjusted / 5) * 5,  # Bin by 5-foot increments
    y_bin = round(y_adjusted / 5) * 5
  ) %>%
  group_by(x_bin, y_bin) %>%
  summarise(
    shot_count = n(),
    .groups = "drop"
  )

p_frequency <- geom_hockey("nhl") +
  geom_point(
    data = shot_frequency,
    aes(x = x_bin, y = y_bin, size = shot_count),
    color = "darkred",
    alpha = 0.6
  ) +
  scale_size_continuous(range = c(1, 8)) +
  labs(
    title = "Shot Frequency Heat Map",
    size = "Number of Shots"
  )

print(p_frequency)

# ============================================
# BONUS: Compare Teams Side-by-Side
# ============================================

# Side-by-side comparison with mirrored shots
p_team_comparison <- geom_hockey("nhl") +
  # Canada shots (left side)
  geom_point(
    data = canada_usa_shots %>% 
      filter(team_name == "Olympic (Women) - Canada"),
    aes(x = x_adjusted, y = y_adjusted),
    color = "red",
    size = 2.5,
    alpha = 0.7
  ) +
  # USA shots (right side, mirrored)
  geom_point(
    data = canada_usa_shots %>% 
      filter(team_name == "Olympic (Women) - United States") %>%
      mutate(x_adjusted = -x_adjusted, y_adjusted = -y_adjusted),
    aes(x = x_adjusted, y = y_adjusted),
    color = "blue",
    size = 2.5,
    alpha = 0.7
  ) +
  labs(title = "Canada (Red) vs USA (Blue) - Shot Locations")

print(p_team_comparison)

# ============================================
# BONUS: Save High-Quality Plot
# ============================================

# Save the custom colored rink as high-resolution image
ggsave(
  filename = "hockey_rink_shots.png",
  plot = p_custom_colors,
  width = 12,
  height = 8,
  dpi = 300,
  units = "in"
)

# Save as PDF
ggsave(
  filename = "hockey_rink_shots.pdf",
  plot = p_custom_colors,
  width = 12,
  height = 8,
  units = "in"
)

cat("Plots saved!\n")