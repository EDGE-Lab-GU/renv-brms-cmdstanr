# syntax=docker/dockerfile:1.6
FROM rocker/rstudio:4.3.1

ENV DEBIAN_FRONTEND=noninteractive

# ---- System deps ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git curl wget ca-certificates build-essential \
    libssl-dev libcurl4-openssl-dev libxml2-dev libgit2-dev \
    libharfbuzz-dev libfribidi-dev libfontconfig1-dev libfreetype6-dev \
    libpng-dev libtiff5-dev libjpeg-dev libx11-dev pandoc \
    cmake make g++ \
    # common extras for packages that often need them
    libudunits2-dev libgdal-dev libgeos-dev libproj-dev libglpk-dev libgsl-dev \
    && rm -rf /var/lib/apt/lists/*

# ---- Binary CRAN mirror (Debian 12) ----
ENV RENV_CONFIG_REPOS_OVERRIDE="https://packagemanager.posit.co/cran/__linux__/debian/12/latest"
ENV RENV_CONFIG_INSTALL_FROM_BINARY=true
ENV RENV_CONFIG_PACKAGE_INSTALL_ARGS="--no-manual --no-build-vignettes"
ENV MAKEFLAGS="-j2"

# ---- R helpers ----
RUN Rscript -e "install.packages('renv', repos = Sys.getenv('RENV_CONFIG_REPOS_OVERRIDE'))"

# Install cmdstanr from Stan repo (keep as-is)
RUN Rscript -e "install.packages('cmdstanr', repos=c('https://mc-stan.org/r-packages/', getOption('repos')))"

# Pre-install CmdStan to avoid compilation delays (keep as-is)
RUN Rscript -e "cmdstanr::install_cmdstan(dir = '/tmp', cores = 2, overwrite = TRUE)" \
 && mv /tmp/cmdstan-* /opt/cmdstan
ENV CMDSTAN=/opt/cmdstan

# ---- Project context ----
WORKDIR /home/rstudio/project

# Copy lockfile first
COPY renv.lock ./

# Faster restore via binary mirror
RUN --mount=type=cache,target=/opt/renv/cache \
    Rscript -e "renv::restore(lockfile = 'renv.lock', clean = TRUE)"

# Copy rest of project
COPY . .

RUN chown -R rstudio:rstudio /home/rstudio/project

