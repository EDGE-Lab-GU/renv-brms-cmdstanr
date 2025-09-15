ENV DEBIAN_FRONTEND=noninteractive \
CRAN=https://cloud.r-project.org


# System packages needed for compiling Stan models (rstan/brms) and many R deps
RUN apt-get update && apt-get install -y \
build-essential \
gfortran \
libssl-dev \
libxml2-dev \
libcurl4-openssl-dev \
&& rm -rf /var/lib/apt/lists/*


# Install R packages for Bayesian modeling
# rstan is the backend compiler used by brms by default
RUN R -q -e "install.packages(c('rstan','brms'), repos=Sys.getenv('CRAN'))"


# Optional: install other commonly used packages here
# RUN R -q -e "install.packages(c('tidyverse','data.table'), repos=Sys.getenv('CRAN'))"

# Optional: support for cmdstanr (lighter/more modern toolchain)
# Pass --build-arg INSTALL_CMDSTAN=true at build time to precompile CmdStan (large!)
ARG INSTALL_CMDSTAN=false
RUN if [ "$INSTALL_CMDSTAN" = "true" ]; then \
R -q -e "install.packages('cmdstanr', repos=c('https://mc-stan.org/r-packages/', Sys.getenv('CRAN'))); \" \
"cmdstanr::install_cmdstan(dir='~/cmdstan', cores=parallel::detectCores())" ; \
fi


# Add our startup wrapper to bind RStudio Server to Railway's $PORT
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh


# Use our wrapper; it will hand control back to Rocker’s s6 init (/init)
ENTRYPOINT ["/usr/local/bin/start.sh"]
