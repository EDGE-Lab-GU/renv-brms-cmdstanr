# Use a base image with R pre-installed
FROM rocker/r-ver:4.3.1

# Install system dependencies as root.
# Added libglpk-dev to resolve igraph's dependency
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
    libglpk-dev \
    && rm -rf /var/lib/apt/lists/*

# Install renv first, as it's required for the next step.
RUN R -e "install.packages('renv')"

# Install CRAN packages that are less problematic using renv
RUN R -e "renv::install(c('tidyverse', 'arrow', 'brms', 'Rcpp', 'rstan'))"

# Install rstanarm and its dependencies separately using install.packages()
# This often succeeds where renv::install() fails due to its strict checks
RUN R -e "install.packages('rstanarm')"

# Install cmdstanr from the Stan R-universe repository
RUN R -e "install.packages('cmdstanr', repos = c('https://mc-stan.org/r-packages/', getOption('repos')))"

# Create the directory for CmdStan installation as root
RUN mkdir -p /opt/cmdstan

# Pre-install CmdStan
RUN Rscript -e "cmdstanr::install_cmdstan(dir = '/opt/cmdstan', cores = 2, overwrite = TRUE)"

# Set the CMDSTAN environment variable
ENV CMDSTAN=/opt/cmdstan

# Default working directory
WORKDIR /home/rstudio/project

# Copy your R project files into the container.
COPY --chown=rstudio:rstudio . /home/rstudio/project
