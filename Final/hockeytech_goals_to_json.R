library(fastRhockey)
library(dplyr)
library(jsonlite)

seasons_to_load <- c(2024, 2025, 2026)

pbp <- load_pwhl_pbp(seasons = seasons_to_load)
schedule <- load_pwhl_schedule(seasons = seasons_to_load)

schedule_clean <- schedule |>
  transmute(
    game_id = as.character(game_id),
    game_date = substr(game_date, 1, 10),
    home_team = home_team,
    away_team = away_team,
    label = paste0(substr(game_date, 1, 10), " — ", away_team, " @ ", home_team)
  ) |>
  distinct(game_id, .keep_all = TRUE) |>
  arrange(game_date, game_id)

writeLines(
  paste0(
    "window.pwhl_schedule = ",
    toJSON(schedule_clean, pretty = TRUE, auto_unbox = TRUE),
    ";"
  ),
  "pwhl_schedule.js"
)

events_clean <- pbp |>
  mutate(
    event_type = case_when(
      event == "goal" ~ "goal",
      event == "shot" ~ "shot",
      TRUE ~ NA_character_
    ),
    team = case_when(
      player_team_id == home_team_id ~ home_team,
      player_team_id == away_team_id ~ away_team,
      TRUE ~ NA_character_
    ),
    x = as.numeric(x_coord),
    y = as.numeric(y_coord)
  ) |>
  filter(!is.na(event_type), !is.na(x), !is.na(y)) |>
  transmute(
    game_id = as.character(game_id),
    team,
    period = as.integer(period_of_game),
    clock = time_of_period,
    event_type,
    x = x + 100,
    y = y + 42.5
  )

dir.create("pwhl_games", showWarnings = FALSE)

for (gid in unique(schedule_clean$game_id)) {
  game_events <- events_clean |>
    filter(game_id == gid)
  
  writeLines(
    paste0(
      "window.pwhl_game_", gid, " = ",
      toJSON(game_events, pretty = TRUE, auto_unbox = TRUE),
      ";"
    ),
    file.path("pwhl_games", paste0("game_", gid, ".js"))
  )
}
