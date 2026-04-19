# =========================================================
# PACKAGES
# =========================================================
#install.packages(c("fastRhockey","DBI","RSQLite","dplyr","jsonlite"))
install.packages("fastRhockey")
# You can install using the pak package using the following code:
if (!requireNamespace('pak', quietly = TRUE)){
  install.packages('pak')
}
pak::pak("sportsdataverse/fastRhockey")

library(fastRhockey)
library(DBI)
library(RSQLite)
library(dplyr)
library(jsonlite)

# =========================================================
# STEP 1 — BUILD DATABASE (RUN ONCE)
# =========================================================
update_pwhl_db()

update_pwhl_db(
  dbdir = ".",
  dbname = "fastRhockey_db",
  tblname = "fastRhockey_pwhl_pbp",
  force_rebuild = FALSE,
  db_connection = NULL
)

ls("package:fastRhockey")


# =========================================================
# STEP 2 — CONNECT TO DATABASE
# =========================================================
con <- dbConnect(RSQLite::SQLite(), "fastRhockey_db.sqlite")

# =========================================================
# STEP 3 — LOAD PLAY-BY-PLAY
# =========================================================
pbp <- dbReadTable(con, "fastRhockey_pwhl_pbp")

# quick check
print(names(pbp))
print(head(pbp))

# =========================================================
# STEP 4 — CLEAN DATA (THIS IS YOUR CORE DATASET)
# =========================================================
clean_pwhl <- pbp |>
  mutate(
    event_type = ifelse(event == "goal", "goal",
                        ifelse(event == "shot", "shot", NA)),
    
    x = as.numeric(x_coord),
    y = as.numeric(y_coord)
  ) |>
  filter(!is.na(event_type), !is.na(x), !is.na(y)) |>
  transmute(
    game_id,
    period = period_of_game,
    clock = time_of_period,
    event_type,
    
    # convert to full rink for your HTML
    x = x + 100,
    y = y + 42.5
  )

# =========================================================
# STEP 5 — EXPORT ONE GAME (TEST)
# =========================================================
game_id_test <- unique(clean_pwhl$game_id)[1]

game <- clean_pwhl |>
  filter(game_id == game_id_test)

write_json(game, paste0("game_", game_id_test, ".json"), pretty = TRUE)

# =========================================================
# STEP 6 — EXPORT ALL GAMES
# =========================================================
dir.create("pwhl_games", showWarnings = FALSE)

game_ids <- unique(clean_pwhl$game_id)

for (gid in game_ids) {
  game <- clean_pwhl |> filter(game_id == gid)
  
  write_json(
    game,
    paste0("pwhl_games/game_", gid, ".json"),
    pretty = TRUE
  )
}

# =========================================================
# DONE
# =========================================================
print("All PWHL JSON files created")