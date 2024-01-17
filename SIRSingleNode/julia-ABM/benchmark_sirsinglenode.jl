using BenchmarkTools
using Random

include("JuliaABMs.jl")
import .JuliaABM

function run_model(num_agents, r0, num_timesteps)
    p = JuliaABM.SIRParameters(num_agents, 1, r0, 5, num_timesteps)
    agents = JuliaABM.init_model(p, 10)
    JuliaABM.run_model!(agents, p)
end

n_run = 10
a = @benchmark run_model(100_000, 2.5, 720) evals=1 samples=n_run seconds=1e6
median_time = sort(a.times)[n_run ÷ 2 + n_run % 2]
println("julia-ABM SIRSingleNode-small (ms): ", median_time * 1e-6)

n_run = 10
a = @benchmark run_model(1_000_000, 2.5, 720) evals=1 samples=n_run seconds=1e6
median_time = sort(a.times)[n_run ÷ 2 + n_run % 2]
println("julia-ABM SIRSingleNode-medium (ms): ", median_time * 1e-6)