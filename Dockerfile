FROM rocker/rstudio:4.4.1

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

USER rstudio

RUN R -e "install.packages('rstudioapi')"

USER root

WORKDIR /home/rstudio/mad-coc-IPW

COPY . .

RUN chown -R rstudio:rstudio /home/rstudio/mad-coc-IPW

USER rstudio

RUN R -e "renv::restore()"

USER root

COPY create_rprofile.sh /tmp/create_rprofile.sh
RUN /bin/bash /tmp/create_rprofile.sh && rm /tmp/create_rprofile.sh

