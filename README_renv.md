# Project Environment (renv)

This repository uses [renv](https://rstudio.github.io/renv) for per‑project R package isolation and reproducibility.

## Quick start
1. Open the project root in VS Code.
2. Start an R terminal; renv auto‑activates via `.Rprofile` (it sources `renv/activate.R`).
3. Restore packages recorded in `renv.lock` (first time or after clone):

```r
renv::restore()
```

4. (Optional) Install dev tooling (already listed in lockfile if present):
```r
renv::install(c("languageserver","lintr","styler","httpgd"))
renv::snapshot()
```

## Rendering R Markdown / Quarto
If you knit from the project root, activation happens automatically. If you need to knit while the working directory is a subfolder (e.g. `code/`), add the following chunk near the top of the document (after the YAML header):

```r
```{r renv-activate, include=FALSE}
if (!("renv" %in% loadedNamespaces())) {
  root <- rprojroot::find_root(rprojroot::has_file("renv/activate.R"))
  source(file.path(root, "renv/activate.R"))
}
```
```

(You may need to install `rprojroot` once: `install.packages("rprojroot")`.)

## Adding / updating packages
Use normal install functions (e.g. `install.packages`, `BiocManager::install`, or `remotes::install_github`). Then run:
```r
renv::snapshot()
```
Commit the updated `renv.lock`.

## Ignored packages
Some packages (e.g. legacy `scDEED`) are ignored during snapshot due to non‑current dependency pins. See `code/renv_setup.R` to adjust the ignore list. To include it later:
```r
renv::settings$ignored.packages(setdiff(renv::settings$ignored.packages(), "scDEED"))
renv::snapshot()
```

## Restoring on another machine
```r
renv::restore()  # installs from CRAN / Bioconductor / cache
```
If a binary is unavailable, renv will build from source (ensure system tools are installed, e.g. Xcode Command Line Tools on macOS: `xcode-select --install`).

## Updating tooling only
```r
source("code/renv_setup.R")
```

## Troubleshooting
- Library path check: `.libPaths()[1]` should point inside `renv/library/...`.
- Rebuild lockfile if corrupted: move `renv.lock` aside, run `renv::snapshot()` (last resort).
- Cache location: `renv::paths$cache()`.

## Do not commit
`renv/library/` and `renv/staging/` are excluded in `.gitignore` (only lockfile + infrastructure are tracked).

