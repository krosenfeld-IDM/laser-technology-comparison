README
======

# Results

|   Model/Framework    | numpy-numba | numpy-c | sqlLite | julia-ABM | julia-vector |
|----------------------|-------------|---------|---------|-----------|--------------|
| SIRSingleNode-small  |    2.28     |  7.63   | 193.33  |    1.0    |     0.76     |
| SIRSingleNode-medium |    0.46     |    .    |    .    |    1.0    |     0.47     |

# Models/Frameworks
- **SIRSingleNode-small:** *Fixed:* single node, 100k agents, 720 steps. *Variable:* R0, I/O, and recovery rate.
- **SIRSingleNode-medium:** *Fixed:* single node, 1M agents, 720 steps. *Variable:* R0, I/O, and recovery rate.

# Setup
From the root of the repository, run the following commands:

```
# install julia
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# install python
sudo apt install python3-pip
pip install -r requirements.txt
```

Run benchmarks:

```
bash runall.sh
```

Based off of [ABMFrameworksComparison](https://github.com/JuliaDynamics/ABMFrameworksComparison/)