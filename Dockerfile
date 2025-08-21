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
RUN Rscript -e "cmdstanr::install_cmdstan(dir = '/tmp', cores = 2, overwrite = TRUE)" && mv /tmp/cmdstan-* /opt/cmdstan

# Set the CMDSTAN environment variable so cmdstanr can find the installation.
# This avoids having to run set_cmdstan_path() in every R session.
ENV CMDSTAN /opt/cmdstan

# Fix rlang compile error (disable Werror for format-security) 
RUN printf 'CFLAGS += -Wno-error=format-security\nCXXFLAGS += -Wno-error=format-security\n' \
    > /usr/local/lib/R/etc/Makevars.site

# Avoid vignette/manual compiles and use all cores
RUN echo 'options(Ncpus = max(1L, parallel::detectCores()));' >> /usr/local/lib/R/etc/Rprofile.site
ENV R_INSTALL_OPTS="--no-build-vignettes --no-manual"

# Project + renv restore (will respect CRAN repo above)
WORKDIR /home/rstudio/project
COPY . .
RUN R -q -e "options(repos=c(CRAN=Sys.getenv('RSPM')));" \
         -e "renv::restore(clean=TRUE, prompt=FALSE)"

EXPOSE 8787
