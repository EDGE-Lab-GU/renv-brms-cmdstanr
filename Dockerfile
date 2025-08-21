FROM rocker/rstudio:4.4.1

ENV DEBIAN_FRONTEND=noninteractive
ENV RSPM=https://packagemanager.posit.co/cran/__linux__/jammy/latest
ENV MAKEFLAGS="-j4" R_REMOTES_NO_ERRORS_FROM_WARNINGS=true

# Base toolchain + prereqs for add-apt-repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential gfortran make cmake \
    libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
    ca-certificates wget unzip \
    software-properties-common dirmngr gnupg \
 && rm -rf /var/lib/apt/lists/*

# Add CRAN PPAs and install heavy packages as Ubuntu binaries
RUN add-apt-repository -y ppa:marutter/rrutter4.0 \
 && add-apt-repository -y ppa:c2d4u.team/c2d4u4.0+ \
 && apt-get update && apt-get install -y --no-install-recommends \
      r-cran-rlang r-cran-vctrs r-cran-cli r-cran-glue r-cran-cpp11 \
      r-cran-colorspace r-cran-isoband r-cran-farver r-cran-gtable \
 && rm -rf /var/lib/apt/lists/*

# Install cmdstanr (from stan-dev R-universe) and renv
RUN R -q -e "options(repos = c(stan='https://stan-dev.r-universe.dev', CRAN=Sys.getenv('RSPM')));" \
         -e "install.packages(c('cmdstanr','renv'))"

# Keep your CmdStan install exactly as-is
RUN Rscript -e "cmdstanr::install_cmdstan(dir = '/tmp', cores = 2, overwrite = TRUE)" \
 && mv /tmp/cmdstan-* /opt/cmdstan
ENV CMDSTAN=/opt/cmdstan

# Prefer binaries during renv restore
ENV RENV_CONFIG_INSTALL_PACKAGE_TYPE=binary

# Speed knobs + skip vignettes/manuals for any source fallbacks
RUN echo 'options(Ncpus = max(1L, parallel::detectCores()));' >> /usr/local/lib/R/etc/Rprofile.site
ENV R_INSTALL_OPTS="--no-build-vignettes --no-manual"

# Safety: if anything still compiles from source, don't die on rlang's format-security warnings
RUN sed -i 's/-Werror=format-security/-Wno-error=format-security/g' /usr/local/lib/R/etc/Makeconf \
 && printf 'CFLAGS += -Wno-error=format-security\nCXXFLAGS += -Wno-error=format-security\n' \
    > /usr/local/lib/R/etc/Makevars.site

# Project + renv restore
WORKDIR /home/rstudio/project
COPY . .
RUN R -q -e "options(repos=c(CRAN=Sys.getenv('RSPM')));" \
         -e "Sys.setenv(RENV_CONFIG_INSTALL_PACKAGE_TYPE='binary')" \
         -e "renv::restore(clean=TRUE, prompt=FALSE)"

EXPOSE 8787
