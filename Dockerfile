FROM rocker/rstudio:4.4.1

ENV DEBIAN_FRONTEND=noninteractive
# Fast CRAN binaries via Posit PPM
ENV RSPM=https://packagemanager.posit.co/cran/__linux__/jammy/latest
# Speed + fewer heavyweight builds
ENV MAKEFLAGS="-j4" \
    R_REMOTES_NO_ERRORS_FROM_WARNINGS=true

# Toolchain + headers
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran make cmake \
    libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
    ca-certificates wget unzip \
 && rm -rf /var/lib/apt/lists/*

# Install pak (fast, uses binaries) then install cmdstanr and renv
RUN R -q -e "install.packages('pak', repos='https://r-lib.github.io/p/pak/stable')" \
 && R -q -e "pak::pkg_install(c('cmdstanr','renv'), ask=FALSE)"

# Now that cmdstanr is installed, install CmdStan once into the image
RUN R -q -e "cmdstanr::install_cmdstan(dir='/opt/cmdstan', cores = parallel::detectCores(), quiet=TRUE)"
ENV CMDSTAN=/opt/cmdstan

# Optional: speed up installs and skip vignettes globally
RUN echo 'options(Ncpus = max(1L, parallel::detectCores()));' >> /usr/local/lib/R/etc/Rprofile.site
ENV R_INSTALL_OPTS="--no-build-vignettes --no-manual"

# Project files + renv restore (uses RSPM binaries)
WORKDIR /home/rstudio/project
COPY . .
RUN R -q -e "options(repos=c(CRAN=Sys.getenv('RSPM')));" \
         -e "renv::restore(clean=TRUE, prompt=FALSE)"

EXPOSE 8787
# Change ownership to the rstudio user
RUN chown -R rstudio:rstudio /home/rstudio/project
