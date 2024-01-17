module Models

using Random
using StatsBase
using DataFrames

# Functions this module provides
export SIR, SEIR


# Thread safe random number generator
const ThreadRNG = Vector{Random.MersenneTwister}(undef, Threads.nthreads())
@Threads.threads    for i in  1:Threads.nthreads()
                        ThreadRNG[Threads.threadid()] = Random.MersenneTwister()
                    end


# Infect agents by removing their susceptibility and setting their first timer (e.g. incubation or infectious)                    
function infectAgents(ids, susceptibility, timer, timer_mean, timer_std, ThreadRNG)
    for id in ids
        susceptibility[id] = 0
        # timer[id] = timer_mean + 1   # +1 because we decrement the timer at the end of each timestep
        timer[id] = round(timer_std*randn(ThreadRNG[Threads.threadid()]) + timer_mean + 1)   # +1 because we decrement the timer at the end of each timestep
    end
end

# function infectAgents(ids, susceptibility, timer, timer_mean, timer_std, ThreadRNG)
#     for id in ids
#         susceptibility[id] = 0
#         timer[id] = timer_mean
#     end
# end

# Update a timer by decrementing it by 1
function updateTimer(timer)
    Threads.@threads    for i in eachindex(timer)
                            if timer[i] > 0
                                timer[i] -= 1
                            end
                        end
end

# Check if timer_a is start_timer (default=1), and if so, start timer_b
function checkChainedTimer(timer_a, timer_b, timer_b_mean, timer_b_std, start_timer::Int=1)
    Threads.@threads    for i in eachindex(timer_a)
                            if timer_a[i] == start_timer
                                # timer_b[i] = timer_b_mean
                                timer_b[i] = round(timer_b_std*randn(ThreadRNG[Threads.threadid()]) + timer_b_mean)
                            end
                        end
end


"""
    SIR(num_agents, R0)

SIR model with infectious periods following a gaussian distribution. Transmission uses a force of infection approach.
"""
function SIR(num_agents::Int=10000, r0::Float64=2.5, num_timesteps=365)

    ######################################
    # Hard-coded parameters
    ######################################

    inf_mean = 5
    inf_std = 0.8
    init_infections = 10

    # derived values
    beta = r0 / inf_mean

    ######################################
    # Initialization
    ######################################

    # initialize agent property arrays (susceptibility, itimer)
    agent_susceptibility = ones(Int8, num_agents, 1)
    agent_itimer = zeros(Int8, num_agents, 1)

    # initialize seed infections
    seed_infections = StatsBase.sample(1:num_agents, init_infections, replace=false)
    infectAgents(seed_infections, agent_susceptibility, agent_itimer, inf_mean, inf_std, ThreadRNG)

    ######################################
    # Main execution loop
    ######################################
    records = Array{Int64}(undef, (num_timesteps, 3)) # S, I, R
    for t = 1:num_timesteps

        # record
        records[t,1] = count(x -> x == 1, agent_susceptibility) # S
        records[t,2] = count(x -> x > 0, agent_itimer) # I
        records[t,3] = count(x -> x == 0, agent_susceptibility) - records[t,2] # R

        # transmission
        contagion = count(x -> x > 0, agent_itimer) 
        force_of_infection = beta * contagion / num_agents
        Threads.@threads    for i in eachindex(agent_susceptibility)
                                if rand(ThreadRNG[Threads.threadid()]) < (force_of_infection * agent_susceptibility[i])
                                    infectAgents(i, agent_susceptibility, agent_itimer, inf_mean, inf_std, ThreadRNG)
                                end
                            end
        
        # update timers
        updateTimer(agent_itimer)

    end

    # Package and return results
    df = DataFrame(records, [:S, :I, :R])
    return df
end


"""
    SEIR(num_agents, R0)
    
SEIR model with infectious and exposure (i.e., incubation) periods following a gaussian distribution. Transmission uses a force of infection approach.
"""
function SEIR(num_agents::Int=10000, r0::Float64=2.5, num_timesteps=365)

    ######################################
    # Hard-coded parameters
    ######################################

    inf_mean = 5
    inf_std = 1
    exp_mean = 3
    exp_std = 0.8    
    init_infections = 10

    # derived values
    beta = r0 / inf_mean

    ######################################
    # Initialization
    ######################################

    # initialize agent property arrays (susceptibility, itimer)
    agent_susceptibility = ones(Int8, num_agents, 1)
    agent_itimer = zeros(Int8, num_agents, 1) # infectious timer
    agent_etimer = zeros(Int8, num_agents, 1) # exposure timer

    # initialize seed infections
    seed_infections = StatsBase.sample(1:num_agents, init_infections, replace=false)
    infectAgents(seed_infections, agent_susceptibility, agent_etimer, exp_mean, exp_std, ThreadRNG)

    ######################################
    # Main execution loop
    ######################################
    records = Array{Int64}(undef, (num_timesteps, 4)) # S, E, I, R
    for t = 1:num_timesteps

        # record
        records[t,1] = count(x -> x == 1, agent_susceptibility) # S
        records[t,2] = count(x -> x > 0, agent_etimer) # E
        records[t,3] = count(x -> x > 0, agent_itimer) # I
        records[t,4] = count(x -> x == 0, agent_susceptibility) - records[t,2] - records[t,3] # R

        # transmission
        contagion = count(x -> x > 0, agent_itimer) 
        force_of_infection = beta * contagion / num_agents
        Threads.@threads    for i in eachindex(agent_susceptibility)
                                if rand(ThreadRNG[Threads.threadid()]) < (force_of_infection * agent_susceptibility[i])
                                    infectAgents(i, agent_susceptibility, agent_etimer, exp_mean, exp_std, ThreadRNG)
                                end
                            end
                            
        # For chained timers we have to update the one on the top of the stack and then check it. Could this break if there is a loop of timer dependence? Alternatively, could we always start the timer with a +1 and then decrement everything at the end?
        updateTimer(agent_itimer)
        checkChainedTimer(agent_etimer, agent_itimer, inf_mean, inf_std)
        updateTimer(agent_etimer)
    end

    # Package and return results
    df = DataFrame(records, [:S, :E, :I, :R])
    return df
end

end

