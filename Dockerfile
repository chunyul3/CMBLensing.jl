FROM ubuntu:16.04

RUN apt-get update \
    && apt-get install -y \
        curl \
        cython3 \
        gfortran \
        hdf5-tools \
        libcfitsio2 \
        libgsl-dev \
        python3-matplotlib \
        python3-numpy \
        python3-pip \
        python3-scipy \
        python3-zmq \
    && pip3 install --no-cache-dir notebook==5.* jupyter_contrib_nbextensions==0.3.1 \
    && jupyter contrib nbextension install \
    && jupyter nbextension enable toc2/main --system \
    && rm -rf /var/lib/apt/lists/*
    
# install julia 0.6.1
RUN mkdir /opt/julia \
    && curl -L https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-0.6.1-linux-x86_64.tar.gz | tar zxf - -C /opt/julia --strip=1 \
    && ln -s /opt/julia/bin/julia /usr/local/bin

# install CAMB
RUN mkdir /opt/camb \
    && curl -L https://github.com/cmbant/camb/tarball/0.1.6.1 | tar zxf - -C /opt/camb --strip=1 \
    && cd /opt/camb/pycamb \
    && python3 setup.py install

# setup unprivileged user needed for mybinder.org
ENV NB_USER bayes
ENV NB_UID 1000
ENV HOME /home/${NB_USER}
RUN adduser -Du ${NB_UID} ${NB_USER}

# install CMBLensing dependencies and precompile
COPY REQUIRE $HOME/.julia/v0.6/CMBLensing/REQUIRE
RUN chown -R $NB_USER $HOME && chgrp -R $NB_USER $HOME
USER ${NB_USER}
RUN julia -e 'ENV["PYTHON"]="python3"; Pkg.add("IJulia"); for p in Pkg.available() try @eval using $(Symbol(p)); println(p); end; end'

# install CMBLensing itself (do so separately here to improve Docker caching)
COPY . $HOME/.julia/v0.6/CMBLensing
RUN julia -e "using CMBLensing, Optim"

# launch notebook
WORKDIR $HOME/.julia/v0.6/CMBLensing
CMD jupyter-notebook --ip=* --no-browser