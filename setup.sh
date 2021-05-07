#/bin/bash


function install_julia() {
    echo "Installing Julia"
    wget -q 'https://julialang-s3.julialang.org/bin/linux/x64/1.6/julia-1.6.0-linux-x86_64.tar.gz'
    tar -xzf julia-1.6.0-linux-x86_64.tar.gz 
    sudo mv julia-1.6.0/ /opt/ 
    sudo ln -s /opt/julia-1.6.0/bin/julia /usr/local/bin/julia
}




julia -e '"found" |> println' || install_julia

mkdir ~/code
cp -r /vagrant/code/julia ~/code
cd ~/code
#julia -e 'using Pkg; Pkg.activate("env"); Pkg.instantiate()'



