# renv_setup.R
# One-time (or infrequent) bootstrap for project-local renv (Option A)
# Run this from the project root or source via: source("code/renv_setup.R")
# Safe to re-run; it will only install missing packages.

needed_pkgs <- c(
  "languageserver",  # VSCode language server
  "lintr",           # linting (optional but useful)
  "styler",          # formatting
  "httpgd"           # fast graphics device for VSCode/Browser
)

# Packages to ignore in renv snapshot (e.g., those with overly strict / stale dependency pins)
ignore_problem_pkgs <- c("scDEED")

# Initialize renv if not already
if (!file.exists("renv/activate.R")) {
  message("Initializing renv project...")
  renv::init(bare = FALSE)  # will snapshot current state
} else {
  renv::activate()
}

# Install any missing packages (cached after first download)
missing <- needed_pkgs[!renv::dependencies()$Package %in% needed_pkgs & !sapply(needed_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing)) {
  message("Installing missing dev/tooling packages: ", paste(missing, collapse = ", "))
  renv::install(missing)
} else {
  message("All dev/tooling packages already installed.")
}

# Add problematic packages to ignored list (idempotent)
current_ignored <- renv::settings$ignored.packages()
renv::settings$ignored.packages(unique(c(current_ignored, ignore_problem_pkgs)))
if (length(ignore_problem_pkgs)) {
  message("Ignoring packages in snapshot: ", paste(ignore_problem_pkgs, collapse = ", "))
}

# Snapshot to record versions (exclude if you prefer to snapshot manually)
renv::snapshot(prompt = FALSE, force = TRUE)

message("renv setup complete. You can now use VSCode R features with project-local packages.")
