# image for the REPORT process
FROM python:3.9-slim

# Nextflow expecting ps to generate metrics files inside docker
RUN apt-get update && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
# To generate plots
RUN pip install --no-cache-dir \
    pandas==2.2.2 \
    matplotlib==3.9.0 \
    numpy==1.26.4

WORKDIR /data
