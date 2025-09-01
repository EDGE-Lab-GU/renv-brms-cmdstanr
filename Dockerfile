FROM rocker/r-ver:4.3.1

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV MAKEFLAGS="-j4"

# System deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git curl wget ca-certificates \
    build-essential cmake make g++ pandoc \
    libssl-dev libcurl4-openssl-dev libxml2-dev libgit2-dev \
    libharfbuzz-dev libfribidi-dev \
    libfontconfig1-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    libx11-dev \
    && rm -rf /var/lib/apt/lists/*

# Optional: use binaries for CRAN packages during renv::restore()
RUN Rscript -e "install.packages('bspm', repos='https://cloud.r-project.org'); bspm::enable(); options(bspm.version.check=FALSE)"

# ---- CmdStanR + CmdStan (your flow, with pin + parallel) ----
RUN Rscript -e "install.packages('cmdstanr', repos=c('https://mc-stan.org/r-packages/', getOption('repos')))"

ARG CMDSTAN_VERSION=2.35.0
ENV CMDSTAN=/opt/cmdstan
RUN Rscript -e "cmdstanr::install_cmdstan(dir = '/tmp', \
                                         version = Sys.getenv('CMDSTAN_VERSION', unset = NA), \
                                         cores = as.integer(Sys.getenv('MAKEFLAGS','-j2') |> sub('^-j','')), \
                                         overwrite = TRUE, \
                                         quiet = TRUE)" \
 && mv /tmp/cmdstan-* /opt/cmdstan

# Project setup
WORKDIR /home/rstudio/project
COPY renv.lock ./
ENV RENV_CONFIG_PAK_ENABLED=false
RUN Rscript -e "options(repos=c(CRAN='https://cloud.r-project.org')); renv::restore()"

COPY . .
RUN chown -R rstudio:rstudio /home/rstudio/project || true

