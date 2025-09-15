# Use the official RStudio Server image from the Rocker project
FROM rocker/rstudio

# Set the working directory for your project
WORKDIR /home/rstudio/project

# Copy your R project files into the container.
# The --chown flag ensures the files are owned by the `rstudio` user.
# This is the single most important fix for your issue.
COPY --chown=rstudio:rstudio . /home/rstudio/project

# Optional: Install any additional R packages your project needs
# You can also use renv::restore() here if you have a renv.lock file
# RUN R -e "install.packages(c('brms', 'rstanarm'))"

# No need to specify CMD, as the base image has a 
