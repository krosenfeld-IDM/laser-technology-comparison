"""
Models investigating multiple dispatch specifically
"""

module JuliaABM

export SEIRParameters

# define an abstract type parameters
abstract type AbstractParameters end

""" 
Define the parmeter structures
"""

struct SIRParameters <: AbstractParameters
    num_agents::Int
    num_spatial_units::Int
    r0::Float64
    infectious_period::Int
    num_timesteps::Int
end
SIRParameters(num_agents, r0; num_timesteps=365) = SIRParameters(num_agents, 1, r0, 5, num_timesteps)

struct SEIRParameters <: AbstractParameters
    num_agents::Int
    num_spatial_units::Int
    r0::Float64
    infectious_period::Int
    exposure_period::Int
    num_timesteps::Int
end
SEIRParameters(num_agents, r0; num_timesteps=365) = SEIRParameters(num_agents, 1, r0, 5, 5, num_timesteps)

"""
Define our agents
"""

# define an abstract type Agent
abstract type AbstractAgent end

# SIR Agent
mutable struct SIRAgent <: AbstractAgent
    state::Symbol
    timer1::Int
end
SIRAgent() = SIRAgent(:S, 0)

# SIR Agent
mutable struct SEIRAgent <: AbstractAgent
    state::Symbol    
    timer1::Int
    timer2::Int
end
SEIRAgent() = SEIRAgent(:S, 0, 0)

"""
Infect the agent by setting the clock on their initial state
"""
function infect!(agent::AbstractAgent, initial_state::Symbol, timer::Int)
    agent.state = initial_state
    agent.timer1 = timer + 1 # +1 for initial state
end
# hard code the length of the initial state for this example
infect!(agent::SIRAgent, parameters::AbstractParameters) = infect!(agent, :I, parameters.:infectious_period)
infect!(agent::SEIRAgent, parameters::AbstractParameters) = infect!(agent, :E, parameters.:exposure_period)

function recover!(agent::AbstractAgent)
    agent.state = :R
end

"""
The force of infection is the same whether you are using a SIR or SEIR model
"""
function force_of_infection(agents::Matrix{T}, parameters::AbstractParameters) where T <: AbstractAgent
    return count(x -> x.state == :I, agents) * (parameters.:r0 / length(agents) / parameters.:infectious_period)
end

"""
Define a Julia function transmit which is a function of a matrix of SIR agents
"""
function transmit!(agents::Matrix{T}, parameters::AbstractParameters) where T <: AbstractAgent

    # the force of infection is the number of infectious agents divided by the total number of agents
    foi = force_of_infection(agents, parameters)

    # loop over agents and set their state to I with probability foi
    for i in eachindex(agents)
        if agents[i].state == :S && rand() < foi
            infect!(agents[i], parameters)
        end
    end
end

"""
Step functions update the timers and the aget state
"""
function step!(agents::Matrix{SIRAgent})
    for i in eachindex(agents)
        if agents[i].timer1 > 0
            agents[i].timer1 -= 1
            # check recovery
            if (agents[i].timer1 == 0)
                recover!(agents[i])
            end                    
        end
    end
end
step!(agents::Matrix{SIRAgent}, parameters::AbstractParameters) = step!(agents)

function step!(agents::Matrix{SEIRAgent}, parameters::AbstractParameters)
    for i in eachindex(agents)
        if agents[i].timer1 > 0
            agents[i].timer1 -= 1
            # start infectious period
            if (agents[i].timer1 == 0)
                agents[i].state = :I
                agents[i].timer2 = parameters.:infectious_period
            end
        elseif agents[i].timer2 > 0
            agents[i].timer2 -= 1
            # check recovery
            if (agents[i].timer2 == 0)
                recover!(agents[i])
            end
        end
    end
end

"""
Initialize the model. I feel like this could be done better.
"""
function init_model(parameters::SIRParameters, num_initial_infections::Int=10)
    agents = Matrix{SIRAgent}(undef, parameters.:num_agents, parameters.:num_spatial_units)
    for i in eachindex(agents)
        agents[i] = SIRAgent()
    end
    for i = 1:num_initial_infections
        infect!(agents[i], parameters)
    end
    return agents
end

function init_model(parameters::SEIRParameters, num_initial_infections::Int=10)
    agents = Matrix{SEIRAgent}(undef, parameters.:num_agents, parameters.:num_spatial_units)
    for i in eachindex(agents)
        agents[i] = SEIRAgent()
    end
    for i = 1:num_initial_infections
        infect!(agents[i], parameters)
    end

    return agents
end

"""
Run the model.
"""
function run_model!(agents::Matrix{T}, parameters::AbstractParameters) where T <: AbstractAgent

    # basic time loop
    for t = 1:parameters.:num_timesteps
        transmit!(agents, parameters)
        step!(agents, parameters)
    end

    # return number of susceptibles at the end for now
    return count(x -> x.state == :S, agents) 
end

end