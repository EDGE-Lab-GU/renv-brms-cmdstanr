# Build from the official Rocker RStudio image
FROM rocker/rstudio:latest


# Optional: install extra system deps / R packages here
# RUN apt-get update && apt-get install -y libpq-dev && rm -rf /var/lib/apt/lists/*
# RUN R -q -e 'install.packages(c("tidyverse","data.table"), repos="https://cloud.r-project.org")'


# Add our startup wrapper to bind RStudio Server to Railway's $PORT
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh


# Use our wrapper; it will hand control back to Rocker’s s6 init (/init)
ENTRYPOINT ["/usr/local/bin/start.sh"]
