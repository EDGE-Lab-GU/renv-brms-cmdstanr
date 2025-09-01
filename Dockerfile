# syntax=docker/dockerfile:1.6
FROM rocker/rstudio:4.3.1

ENV DEBIAN_FRONTEND=noninteractive

# --- System deps (add a few common heavy hitters to avoid source builds) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git curl wget ca-certificates build-essential \
    libssl-dev libcurl4-openssl-dev libxml2-dev libgit2-dev \
    libharfbuzz-dev libfribidi-dev libfontconfig1-dev libfreetype6-dev \
    libpng-dev libtiff5-dev libjpeg-dev libx11-dev pandoc \
    cmake make g++ \
    # optional but often needed by popular R pkgs:
    libudunits2-dev libgdal-dev libgeos-dev libproj-dev libglpk-dev libgsl-dev \
    && rm -rf /var/lib/apt/lists/*

# --- Prefer binary CRAN via Posit Package Manager (Debian 12/bookworm) ---
ENV RENV_CONFIG_REPOS_OVERRIDE="https://packagemanager.posit.co/cran/__linux__/debian/12/latest"
ENV RENV_CONFIG_INSTALL_FROM_BINARY=true
ENV RENV_CONFIG_PACKAGE_INSTALL_ARGS="--no-manual --no-build-vignettes"
ENV MAKEFLAGS="-j2"

# Optional: direct renv cache path (also matches our cache mount target)
ENV RENV_PATHS_CACHE="/opt/renv/cache"
RUN mkdir -p "$RENV_PATHS_CACHE" && chown -R rstudio:rstudio "$RENV_PATHS_CACHE"

# --- R helpers up front for layer caching ---
RUN Rscript -e "install.packages('renv', repos = Sys.getenv('RENV_CONFIG_REPOS_OVERRIDE'))"

# Install cmdstanr from Stan repo (KEEP AS-IS)
RUN Rscript -e "install.packages('cmdstanr', repos=c('https://mc-stan.org/r-packages/', getOption('repos')))"

/* Pre-install CmdStan to avoid compilation delays (KEEP AS-IS) */
RUN Rscript -e "cmdstanr::install_cmdstan(dir = '/tmp', cores = 2, overwrite = TRUE)" && mv /tmp/cmdstan-* /opt/cmdstan
ENV CMDSTAN=/opt/cmdstan

# --- Project context ---
WORKDIR /home/rstudio/project

# Copy lockfile first to leverage Docker layer cache
COPY renv.lock ./

# Railway requires cache id format: id=s/<SERVICE_ID>-<target-path>
# Replace <SERVICE_ID> with your exact Railway Service ID, no variables.
RUN --mount=type=cache,id=s/<SERVICE_ID>-/opt/renv/cache,target=/opt/renv/cache \
    Rscript -e "renv::restore(lockfile = 'renv.lock', clean = TRUE)"

# Copy the rest of the project
COPY . .

# Permissions for the rstudio user
RUN chown -R rstudio:rstudio /home/rstudio/project

