# Dockerfile
FROM rocker/rstudio:latest

ENV DEBIAN_FRONTEND=noninteractive \
    CRAN=https://cloud.r-project.org

# Toolchain for rstan/brms
RUN apt-get update && apt-get install -y \
    build-essential \
    gfortran \
    libssl-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Preinstall rstan + brms
RUN R -q -e "install.packages(c('rstan','brms'), repos=Sys.getenv('CRAN'))"

# Startup wrapper to bind to Railway's $PORT
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Use our wrapper; it will hand control back to Rocker’s s6 init (/init)
ENTRYPOINT ["/usr/local/bin/start.sh"]
