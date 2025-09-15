# Use a base image with R pre-installed
FROM rocker/r-ver:4.3.1

# Install system dependencies as root.
# This must be done before switching to a non-root user.
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

# Install R packages as root
RUN R -e "install.packages('renv')"
RUN R -e "renv::install(c('tidyverse', 'arrow', 'brms', 'Rcpp', 'rstan', 'rstanarm', 'cmdstanr'))"

# Pre-install CmdStan as root
RUN Rscript -e "cmdstanr::install_cmdstan(dir = '/opt/cmdstan', cores = 2, overwrite = TRUE)"

# Set the CMDSTAN environment variable
ENV CMDSTAN=/opt/cmdstan

# Switch to the rstudio user for subsequent commands and application runtime
# The base image `rocker/r-ver` already creates this user.
USER rstudio

# Set the working directory
WORKDIR /home/rstudio/project

# Copy your R project files into the container, ensuring correct ownership
# The --chown flag ensures that the files are owned by the rstudio user
COPY --chown=rstudio:rstudio . /home/rstudio/project

# Optional: Set permissions on the working directory
RUN chown -R rstudio:rstudio /home/rstudio/project
