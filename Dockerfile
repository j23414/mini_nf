FROM mambaorg/micromamba:0.23.3
USER root
COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/env.yaml
RUN sed -i 's/nextstrain_nf/base/g' /tmp/env.yaml
RUN apt-get update
RUN apt-get install -y git curl python3-pip
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes
