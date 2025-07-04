import AlgebraOfGraphics: draw!
using Statistics

include("anisotry.jl")

# %%
legend_kwargs = (position = :top, titleposition = :left)

begin
    ds_mapping = :dataset => sorter(ds_order)
    enc_m = :enc => x -> "Enc $x"
end

log_axis = (yscale = log10, xscale = log10)

function draw!(grid; axis = NamedTuple(), palettes = NamedTuple())
    return plt -> draw!(grid, plt; axis = axis, palettes = palettes)
end

function plot_vl_ratio(
        df;
        datalimits = x -> quantile(x, [0.01, 0.99]),
        legend = legend_kwargs,
        fname = "vl_ratio",
        mapping_args = (v_l_ratio_map,),
        mapping_kwargs = (; color = ds_mapping)
    )
    plt = data(df) * mapping(mapping_args...; mapping_kwargs...) * density(datalimits = datalimits)
    draw(plt, legend = legend)
    return easy_save(fname; dir = "$fig_dir/$enc")
end

function plot_dvl(
        df;
        legend = legend_kwargs,
        fname = "dvl",
        mapping_args = (v_Alfven_map, v_ion_map),
        mapping_kwargs = (; color = ds_mapping)
    )
    plt = data(df) * mapping(mapping_args...; mapping_kwargs...)

    limit_axis = (; limits = ((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    draw(plt, axis = axis, legend = legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    map(slopes) do s
        lines!(1 .. 1000, (*) $ s, linestyle = :dash, label = "$s")
    end
    axislegend("slope", position = :ct)

    return easy_save(fname)
end


function plot_dvl(; legend = legend_kwargs)
    fname = "dvl"

    plt = data_layer_a * mapping(v_Alfven_map, v_ion_map)

    limit_axis = (; limits = ((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    draw(plt, axis = axis, legend = legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    map(slopes) do s
        lines!(1 .. 1000, (*) $ s, linestyle = :dash, label = "$s")
    end
    axislegend("slope", position = :ct)

    return easy_save(fname)
end
