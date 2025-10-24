# Code Review Findings

## 1. `code/renv_setup.R`
- **Issue:** The `missing` package detection mixes the results of `renv::dependencies()` with package installation checks, producing a logical vector whose length rarely matches `needed_pkgs`. This triggers unintended recycling and often flags every helper package as "missing" even when it is already installed. 【F:code/renv_setup.R†L24-L31】
- **Recommendation:** Base the check solely on the installation status (e.g., `!vapply(needed_pkgs, requireNamespace, logical(1), quietly = TRUE)`) or call `renv::status()` to determine what should be installed. Avoid using `renv::dependencies()` in this context.

## 2. R Markdown notebooks in `code/`
- **Files affected:**
  - `P589-1_preprocessing.Rmd`
  - `P589-1_DGEAndGSEA.rmd`
  - `P589-1_manuscriptFigures.Rmd`
  - `P589-1_scratchArchive.Rmd`
  - `P589-1_seuratObjectOverview.rmd`

### 2.a Hard-coded file system paths
- **Issue:** Each notebook sets the working directory and downstream paths to absolute, machine-specific locations under `/Users/tedwards/...`, which prevents knitting the reports on any other system and conflicts with `renv` project isolation. 【F:code/P589-1_preprocessing.Rmd†L17-L118】【F:code/P589-1_DGEAndGSEA.rmd†L16-L119】【F:code/P589-1_manuscriptFigures.Rmd†L16-L121】【F:code/P589-1_scratchArchive.Rmd†L16-L115】【F:code/P589-1_seuratObjectOverview.rmd†L14-L86】
- **Recommendation:** Replace the `setwd()` and `baseDir` literals with project-relative helpers such as `here::here()` or `fs::path()` so the notebooks work across environments (including CI).

### 2.b Parallel cluster creation
- **Issue:** `optimizeRNAseqClustering()` creates parallel clusters with `type = "FORK"`, which is unsupported on Windows and on some HPC schedulers. The same notebooks also assume `parallel::detectCores() - 1` is always valid, which can return `0` or `NA` on constrained machines. 【F:code/P589-1_preprocessing.Rmd†L151-L166】
- **Recommendation:** Let R pick an appropriate backend (`parallel::makeCluster(nCores)`), guard the core count with `max(1L, ...)`, and optionally fall back to sequential execution when only one core is available.

### 2.c Counting trustworthy / intermediate cells
- **Issue:** The helper that annotates `scDEEDResult$full_results` blindly adds one to every `str_count()` result. When the field is `NA` or an empty string, the code produces `NA` or an off-by-one count, which breaks downstream summaries. 【F:code/P589-1_preprocessing.Rmd†L200-L214】
- **Recommendation:** Normalize the columns before counting (e.g., replace `NA`/`""` with `0` and skip the `+ 1` unless commas are actually present).

## 3. `code/SeuratRNAseqClusterOptGridSearchFunction.Rmd`
- **Parallelization portability:** The standalone version of `optimizeRNAseqClustering()` inherits the same `parallel::makeCluster(..., type = "FORK")` and `detectCores() - 1` assumptions discussed above, so the fixes from Section 2.b should be duplicated here. 【F:code/SeuratRNAseqClusterOptGridSearchFunction.Rmd†L31-L167】
- **Trustworthy-cell counting:** This copy also needs the defensive handling described in Section 2.c. 【F:code/SeuratRNAseqClusterOptGridSearchFunction.Rmd†L155-L167】

## Suggested Next Steps
1. Refactor path handling in all notebooks to rely on project-relative utilities, then verify they knit inside a fresh `renv` environment.
2. Harden the parallel grid-search helper to pick a safe backend (or to run sequentially) based on the available cores.
3. Normalize the `scDEED` output parsing so empty vectors yield a count of zero instead of `NA`/`1`.
4. Simplify the `renv_setup.R` bootstrap logic so it accurately reports which dev packages still need installation.
