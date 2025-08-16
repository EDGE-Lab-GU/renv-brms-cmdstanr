#!/usr/bin/env Rscript

# A script to check if all required packages are installed and can be loaded,
# with a special check for the cmdstanr configuration.

required_packages <- c(
  "brms",
  "tidyverse",
  "tidybayes",
  "furrr",
  "purrr",
  "fs",
  "stringr",
  "progressr",
  "cmdstanr"
)

cat("Step 1: Checking if all required R packages are installed...\n")

# Use `requireNamespace` for a lightweight check without attaching the package
is_installed <- sapply(required_packages, requireNamespace, quietly = TRUE)

if (!all(is_installed)) {
  failed_packages <- names(is_installed[!is_installed])
  error_message <- paste(
    "\nError: The following packages could not be loaded:\n",
    paste(" -", failed_packages, collapse = "\n"),
    "\n\nPlease install them, for example by running:\n",
    "  install.packages(c('", paste(failed_packages, collapse = "', '"), "'))\n",
    sep = ""
  )
  # Stop execution with an informative message. This works for both
  # interactive (source) and non-interactive (Rscript) sessions.
  stop(error_message, call. = FALSE)
}

cat("All packages are installed.\n\n")
cat("Step 2: Checking if cmdstanr is configured correctly...\n")

# Check if cmdstanr can find the CmdStan installation and report its version.
# This is a more robust check that the environment is set up correctly.
cmdstan_version <- try(cmdstanr::cmdstan_version(error_on_NA = TRUE), silent = TRUE)

if (inherits(cmdstan_version, "try-error")) {
  cat("\nError: 'cmdstanr' is installed, but is not configured correctly.\n")
  cat("Could not find a valid CmdStan installation.\n\n")
  cat("Details from cmdstanr:\n")
  # The error message from try() is often informative
  cat(as.character(cmdstan_version), "\n")
  cat("Please ensure CmdStan was installed correctly in the Docker build process\n")
  cat("and that the CMDSTAN environment variable is pointing to the right location.\n")
  quit(save = "no", status = 1)
}

cat("Found CmdStan version:", cmdstan_version, "\n")
cat("CmdStan path:", cmdstanr::cmdstan_path(), "\n")

cat("\nSuccess! All required packages are installed and correctly configured.\n")
quit(save = "no", status = 0)
