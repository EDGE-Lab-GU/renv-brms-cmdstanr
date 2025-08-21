FROM rocker/rstudio:4.4.1

ENV DEBIAN_FRONTEND=noninteractive
# Posit binaries for speed
ENV RSPM=https://packagemanager.posit.co/cran/__linux__/jammy/latest
ENV MAKEFLAGS="-j4" R_REMOTES_NO_ERRORS_FROM_WARNINGS=true

# Toolchain + headers
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran make cmake \
    libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
    ca-certificates wget unzip \
 && rm -rf /var/lib/apt/lists/*

# Use stan-dev R-universe for cmdstanr
RUN R -q -e "options(repos = c(stan='https://stan-dev.r-universe.dev', CRAN=Sys.getenv('RSPM')));" \
         -e "install.packages(c('cmdstanr','renv'))"

# Install CmdStan once into the image
RUN R -q -e "cmdstanr::install_cmdstan(dir='/opt/cmdstan', cores = parallel::detectCores(), quiet=TRUE)"
ENV CMDSTAN=/opt/cmdstan

# Faster installs, no vignettes/manuals
RUN echo 'options(Ncpus = max(1L, parallel::detectCores()));' >> /usr/local/lib/R/etc/Rprofile.site
ENV R_INSTALL_OPTS="--no-build-vignettes --no-manual"

# Project + renv restore (will respect CRAN repo above)
WORKDIR /home/rstudio/project
COPY . .
RUN R -q -e "options(repos=c(CRAN=Sys.getenv('RSPM')));" \
         -e "renv::restore(clean=TRUE, prompt=FALSE)"

EXPOSE 8787
