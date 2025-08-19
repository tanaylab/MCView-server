FROM rocker/shiny-verse:4.2.1

# Build arguments
ARG GITHUB_PAT
ARG MCVIEW_USER_UID=1000
ARG MCVIEW_USER_GID=1000

# Set environment variables
ENV GITHUB_PAT=$GITHUB_PAT
ENV MCVIEW_USER_UID=$MCVIEW_USER_UID
ENV MCVIEW_USER_GID=$MCVIEW_USER_GID

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    git-core \
    libcurl4-openssl-dev \
    libgit2-dev \
    libicu-dev \
    libssl-dev \
    libxml2-dev \
    make \
    pandoc \
    pandoc-citeproc \
    zlib1g-dev \
    lbzip2 \
    libfftw3-dev \
    libgdal-dev \
    libgeos-dev \
    libgsl0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libhdf4-alt-dev \
    libhdf5-dev \
    libjq-dev \
    libpq-dev \
    libproj-dev \
    libprotobuf-dev \
    libnetcdf-dev \
    libsqlite3-dev \
    libudunits2-dev \
    netcdf-bin \
    postgis \
    protobuf-compiler \
    sqlite3 \
    tk-dev \
    unixodbc-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configure R repository and parallel compilation
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" >> /usr/local/lib/R/etc/Rprofile.site

# Install core R packages
RUN R -e 'install.packages("remotes")'

# Install essential R packages for MCView and Shiny
RUN install2.r --error --ncpus 4 \
    # Core data manipulation and visualization
    dplyr \
    ggplot2 \
    plotly \
    DT \
    tibble \
    tidyr \
    purrr \
    forcats \
    # Shiny ecosystem
    shiny \
    shinydashboard \
    shinydashboardPlus \
    shinyWidgets \
    shinyjs \
    shinycssloaders \
    shinybusy \
    # Visualization and graphics
    viridis \
    RColorBrewer \
    ggrepel \
    ggnewscale \
    cowplot \
    circlize \
    scales \
    # Data processing
    matrixStats \
    qs \
    config \
    yaml \
    # Utility packages
    glue \
    cli \
    htmltools \
    markdown \
    rmarkdown \
    Cairo \
    ragg \
    # Scientific computing
    mclust \
    dendextend \
    scattermore \
    RcppRoll \
    TSP \
    # Web and file handling
    fs \
    zip \
    processx \
    promises \
    # Statistical packages
    tgstat \
    tglkmeans \
    # Interface packages
    bslib \
    ggtext \
    colourpicker

# Install Bioconductor packages
RUN R -e "BiocManager::install(c('rhdf5', 'MatrixGenerics', 'ComplexHeatmap', 'sparseMatrixStats'), update=FALSE, ask=FALSE)"

# Install MCView and related packages from GitHub
RUN Rscript -e 'remotes::install_github("tanaylab/tgutil")'
RUN Rscript -e 'remotes::install_github("tanaylab/tgconfig")'
RUN Rscript -e 'remotes::install_github("tanaylab/misha")'
RUN Rscript -e 'remotes::install_github("tanaylab/misha.ext")'
RUN Rscript -e 'remotes::install_github("tanaylab/metacell")'
RUN Rscript -e 'remotes::install_github("tanaylab/MCView")'

# Create and configure user
RUN groupadd -g $MCVIEW_USER_GID mcview || true
RUN useradd -u $MCVIEW_USER_UID -g $MCVIEW_USER_GID -m -s /bin/bash mcview || true

# Update shiny user to match configured UID/GID
RUN usermod -u $MCVIEW_USER_UID shiny 2>/dev/null || true
RUN groupmod -g $MCVIEW_USER_GID shiny 2>/dev/null || true

# Create necessary directories and set permissions
RUN mkdir -p /home/shiny /home/.R /var/log/shiny-server /srv/shiny-server/apps
# RUN chown -R shiny:shiny /home/shiny /var/log/shiny-server /srv/shiny-server
RUN chmod 755 /home/shiny

# Configure R environment
RUN touch /home/.R/Makevars

# Copy startup script
COPY run_server.sh /home/
RUN chmod +x /home/run_server.sh

# Expose port
EXPOSE 3838

# Set working directory
WORKDIR /home

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:3838/ || exit 1

# Run server
CMD ["/home/run_server.sh"]
