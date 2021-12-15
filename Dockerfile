FROM mambaorg/micromamba:0.19.1
USER root
COPY --chown=micromamba:micromamba environment.yml /tmp/env.yaml
RUN apt-get update
RUN apt-get install -y git curl python3-pip
RUN micromamba env create -y -f /tmp/env.yaml && \
    micromamba clean --all --yes
RUN ln -s /bin/micromamba /bin/conda

ARG MAMBA_DOCKERFILE_ACTIVATE=1 

RUN echo "micromamba activate nextstrain_nf" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]
