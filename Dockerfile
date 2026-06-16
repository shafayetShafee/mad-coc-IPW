FROM rocker/rstudio:4.4.1

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    # font rendering — systemfonts, ragg, ggplot2, svglite
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    # image processing — magick, ggplot2 (PNG output)
    imagemagick \
    libmagick++-dev \
    gsfonts \
    # build tools — compiled packages (e.g. Stan, data.table)
    cmake \
    make \
    # string encoding — stringi, readr
    libicu-dev \
    # document rendering — rmarkdown, knitr, pagedown
    pandoc \
    # web / auth — curl, httr, httr2, openssl
    libcurl4-openssl-dev \
    libssl-dev \
    # XML parsing — xml2, rvest, xlsx
    libxml2-dev \
    # spatial — sf, terra, stars, sp
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
