# Use R 4.4 on Ubuntu 22.04 (Jammy)
FROM rocker/rstudio:4.4.1

# Fast binary CRAN mirror
ENV RSPM=https://packagemanager.posit.co/cran/__linux__/jammy/latest

# System deps (C/C++, Fortran, SSL, XML, Git, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran make cmake \
    libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
    libjpeg-dev libpng-dev libtiff5-dev libfreetype6-dev libfontconfig1-dev \
    ca-certificates wget unzip \
 && rm -rf /var/lib/apt/lists/*

# Speed knobs + no vignettes/manuals anywhere
ENV MAKEFLAGS="-j4"
RUN echo 'options(Ncpus = max(1L, parallel::detectCores()));' >> /usr/local/lib/R/etc/Rprofile.site
ENV R_INSTALL_OPTS="--no-build-vignettes --no-manual"
ENV R_REMOTES_NO_ERRORS_FROM_WARNINGS=true
ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE

# Pre-install renv and cmdstanr from binaries where possible
RUN R -q -e "install.packages(c('renv','cmdstanr'), repos=Sys.getenv('RSPM'))"

# Install cmdstan once at build time (cached in image)
# If this is still heavy on your network, comment this block and build in CI instead.
RUN R -q -e "cmdstanr::install_cmdstan(dir='/opt/cmdstan', cores = parallel::detectCores(), quiet=TRUE)"
ENV CMDSTAN=/opt/cmdstan

# Cache for renv to make layer reusable
ENV RENV_PATHS_CACHE=/opt/renv/cache
RUN mkdir -p /opt/renv/cache && chown -R rstudio:rstudio /opt/renv

# Copy project and restore packages according to renv.lock
WORKDIR /home/rstudio/project
COPY . .
# Respect global install opts and repos, restore without prompts
RUN R -q -e "Sys.setenv(RSPM=Sys.getenv('RSPM')); options(repos=c(CRAN=Sys.getenv('RSPM')));" \
         -e "renv::restore(clean=TRUE, prompt=FALSE)"

# RStudio listens on 8787; Railway will proxy
EXPOSE 8787

# Change ownership to the rstudio user
RUN chown -R rstudio:rstudio /home/rstudio/project
