README
======

# Results

|   Model/Framework    | numpy-numba | numpy-c | sqlLite | julia-ABM |
|----------------------|-------------|---------|---------|-----------|
| SIRSingleNode-small  |    2.04     |  3.19   |  172.6  |    1.0    |
| SIRSingleNode-medium |    0.44     |    .    |    .    |    1.0    |

# Setup
From the root of the repository, run the following commands:

```
# install julia
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# install python
sudo apt install python3-pip
pip install -r requirements.txt
```

Based off of [ABMFrameworksComparison](https://github.com/JuliaDynamics/ABMFrameworksComparison/)