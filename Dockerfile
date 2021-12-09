FROM mambaorg/micromamba

# === Update installers
RUN apt-get update && apt-get install -y git
RUN apt-get install -y curl && apt-get install -y python3-pip

# === Pull repo
RUN git clone https://github.com/j23414/mini_nf

# === install any conda packages
RUN cd mini_nf; mamba env create -f environment.yml