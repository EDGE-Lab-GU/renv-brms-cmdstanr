# Use a base image with R pre-installed. The rocker images are a great choice.
FROM rocker/r-ver:4.3.1

# Install system dependencies required for R packages.
# These include dependencies for Stan and brms compilation (g++, libcurl, etc.)
RUN apt-get update -qq && apt-get install -y \
    g++ \
    libcurl4-gnutls-dev \
    libxml2-dev \
    libssl-dev \
    libudunits2-dev \
    libgdal-dev \
    pandoc \
    pandoc-citeproc \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages.
# The `install2.r` script from the littler package is a convenient way to install packages.
# We'll install a bunch of tidyverse packages, brms, Stan, and arrow for parquet.
RUN R -e "install.packages('renv')"
RUN R -e "renv::install(c('tidyverse', 'arrow', 'brms', 'Rcpp', 'rstan', 'rstanarm'))"

# Set the working directory inside the container
WORKDIR /app

# Copy your R project files into the container.
COPY . /app
