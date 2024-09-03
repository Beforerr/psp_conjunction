using DrWatson
@quickactivate
include("../src/main.jl")
import Beforerr: easy_save
using AlgebraOfGraphics: linear
using Dates
import CairoMakie: Figure
import Base.copy

Base.copy(x::Figure) = x

function load_all(enc)
    dfs = [
        load(enc, "PSP"; dataset="Parker Solar Probe"),
        load(enc, "THEMIS"; dataset="ARTEMIS"),
        load(enc, "Wind"),
        # load(enc, "Solo"; dataset="Solar Orbiter")
    ]
    df = reduce(vcat, dfs, cols=:intersect)
    levels!(df.dataset, ds_order)
    return df
end

# plot the density distribution of the thickness and current density
function plot_l_j_dist(config)
    @unpack df = config

    data_layer = data(df) * mapping(color=ds_mapping, marker=ds_mapping)
    maps = [l_log_map j_log_map
        l_norm_log_map j_norm_log_map]
    figure_kwargs = (size=(800, 600),)

    plot_dist(data_layer; maps, axis=(), visual=mapping(), figure_kwargs=figure_kwargs)
end

safe_produce(f, c, path; kwargs...) = produce_or_load(f, c, path; filename=hash, suffix="svg", loadfile=false, kwargs...)

function main(enc)
    path = "$fig_dir/$enc"
    df = load_all(enc)
    config = @dict df
    safe_produce(plot_l_j_dist, config, path; prefix="properties_distribution")
end

encs = ["enc7", "enc8", "enc9"]
main.(encs)