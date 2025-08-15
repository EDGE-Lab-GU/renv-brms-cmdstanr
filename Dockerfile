FROM rocker/rstudio:4.3.1
# Install system dependencies for your R packages
# Install system dependencies
RUN apt-get update && apt-get install -y \
    sudo git curl wget build-essential \
    libssl-dev libcurl4-openssl-dev libxml2-dev \
    libgit2-dev libharfbuzz-dev libfribidi-dev \
    libfontconfig1-dev libfreetype6-dev \
    libpng-dev libtiff5-dev libjpeg-dev \
    libx11-dev pandoc \
    cmake make g++ \
    && rm -rf /var/lib/apt/lists/*

# Install renv globally so it's available before restore
RUN Rscript -e "install.packages('renv', repos='https://cloud.r-project.org')"
# Install cmdstanr from Stan repo
RUN Rscript -e "install.packages('cmdstanr', repos=c('https://mc-stan.org/r-packages/', getOption('repos')))"

# Pre-install CmdStan to avoid compilation delays
RUN Rscript -e "cmdstanr::install_cmdstan(cores = 2)"

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
