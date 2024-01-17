using BenchmarkTools
using Random

include("ToyModels.jl")
import .Models

function run_model(num_agents, r0, num_timesteps)
    m = Models.SIR(num_agents, r0, num_timesteps)
end

n_run = 10
a = @benchmark run_model(100_000, 2.5, 720) evals=1 samples=n_run seconds=1e6
median_time = sort(a.times)[n_run ÷ 2 + n_run % 2]
println("julia-vector SIRSingleNode-small (ms): ", median_time * 1e-6)

n_run = 10
a = @benchmark run_model(1_000_000, 2.5, 720) evals=1 samples=n_run seconds=1e6
median_time = sort(a.times)[n_run ÷ 2 + n_run % 2]
println("julia-vector SIRSingleNode-medium (ms): ", median_time * 1e-6)