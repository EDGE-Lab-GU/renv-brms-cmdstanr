# Use the official RStudio Server image from the Rocker project
FROM rocker/rstudio

# Set the working directory for your project
WORKDIR /home/rstudio

# Copy your R project files (e.g., .Rproj, scripts, data) into the container
COPY . /home/rstudio/
