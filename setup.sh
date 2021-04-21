#/bin/bash

wget -q https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.0-linux-x86_64.tar.gz
tar -xzf julia-1.6.0-linux-x86_64.tar.gz
sudo mv julia-1.6.0/ /opt/
sudo ln -s /opt/julia-1.6.0/bin/julia /usr/local/bin/julia
cd /vagrant/code/julia
#julia -e 'using Pkg; Pkg.activate("env"); Pkg.instantiate()'



