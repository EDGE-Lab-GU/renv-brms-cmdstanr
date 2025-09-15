# Use a base image with R pre-installed
FROM rocker/r-ver:4.3.1

# Set a non-root user for security best practices
RUN useradd -m shiny && \
    mkdir /opt/cmdstan && \
    chown -R shiny:shiny /opt/cmdstan

USER shiny

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
    g++ \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libudunits2-dev \
    libgdal-dev \
    pandoc \
    pandoc-citeproc \
    zlib1g-dev \
    git \
    make \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages('renv')"
RUN R -e "renv::install(c('tidyverse', 'arrow', 'brms', 'Rcpp', 'rstan', 'rstanarm', 'cmdstanr'))"

# Pre-install CmdStan
# This step significantly speeds up model compilation later
RUN Rscript -e "cmdstanr::install_cmdstan(dir = '/opt/cmdstan', cores = 2, overwrite = TRUE)"

# Set the CMDSTAN environment variable
# This ensures cmdstanr can always find the installation
ENV CMDSTAN=/opt/cmdstan

# Default working directory
WORKDIR /home/rstudio/project

# Copy renv lockfile to restore packages.
# This leverages Docker's layer caching, so packages are not reinstalled
# on every build unless renv.lock changes.
COPY renv.lock .

# Restore the R environment
RUN Rscript -e "renv::restore()"

# Copy the rest of your project files
COPY . .

# Change ownership to the rstudio user
RUN chown -R rstudio:rstudio /home/rstudio/project
