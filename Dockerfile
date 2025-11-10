FROM rocker/rstudio:4.4.1

WORKDIR /home/rstudio/mad-coc-IPW

# Install system dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libfontconfig1-dev \
    libfreetype6-dev \
    cmake \
    make \
    libpng-dev \
    libicu-dev \
    pandoc \
    imagemagick \
    libmagick++-dev \
    gsfonts \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libudunits2-dev \
    libgdal-dev \
    gdal-bin \
    libgeos-dev \
    libproj-dev \
    libsqlite3-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY renv.lock renv.lock
COPY renv/activate.R renv/activate.R
COPY .Rprofile /home/rstudio/.Rprofile
RUN echo 'setwd("/home/rstudio/mad-coc-IPW"); source("renv/activate.R")' > /home/rstudio/.Rprofile

RUN chown -R rstudio:rstudio /home/rstudio

USER rstudio
RUN R -e "renv::restore()"

USER root
