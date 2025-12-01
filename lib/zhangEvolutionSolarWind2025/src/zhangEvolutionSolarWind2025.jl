# Accompanying package to load the results of the paper "Zhang et al. (2025) - Evolution of solar wind discontinuities in the inner heliosphere"
module zhangEvolutionSolarWind2025
using JLD2

# Packges for reconstruction
using DataFrames
using StaticArrays
using Unitful
using CommonDataFormat: Epoch
using Discontinuity: compute_Alfvenicity_params!, compute_params!

const DATADIR = joinpath(@__DIR__, "../../../data")

"""
Load the events for a given id (available ids: "PSP", "Wind", "THEMIS").
"""
function load(id)
    # Find all files matching the pattern for the given id
    # Example: id=Wind_t0=2021-01-17_t1=2021-01-18_tau=2.0.jld2
    pattern = Regex("id=$(id)_.*\\.jld2\$")
    files = filter(f -> occursin(pattern, f), readdir(DATADIR; join = true))

    isempty(files) && error("No files found for id: $id")
    # Load and combine all matching files
    return mapreduce(vcat, files) do file
        jldopen(file)["events"] |> compute_params! |> compute_Alfvenicity_params!
    end
end

end
