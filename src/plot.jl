import AlgebraOfGraphics: draw!

include("anisotry.jl")

# %%
# Define the labels for the plots
j_lab = L"Current Density ($nA/m^2$)"
l_lab = L"Thickness ($km$)"

l_norm_lab = L"Normalized Thickness ($d_i$)"
j_norm_lab = L"Normalized Current Density ($J_A$)"

di_lab = L"Ion Inertial Length ($km$)"
jA_lab = L"Alfvénic Current Density ($nA/m^2$)"

# %%
# Define the mappings
di_map = :ion_inertial_length => di_lab
di_log_map = :ion_inertial_length => log10 => L"Log %$di_lab"
l_map = :L_k => l_lab
l_norm_map = :L_k_norm => l_norm_lab
l_log_map = :L_k => log10 => L"Log %$l_lab"
l_norm_log_map = :L_k_norm => log10 => L"Log %$l_norm_lab"

jA_map = :j_Alfven => jA_lab
jA_log_map = :j_Alfven => log10 => L"Log %$jA_lab"

j_map = :j0_k => j_lab
j_log_map = :j0_k => log10 => L"Log %$j_lab"
j_norm_map = :j0_k_norm => j_norm_lab
j_norm_log_map = :j0_k_norm => log10 => L"Log %$j_norm_lab"

ds_order = ["Parker Solar Probe", "ARTEMIS", "Wind"]
ds_mapping = :dataset => sorter(ds_order)

log_axis = (yscale=log10, xscale=log10)

function draw!(grid; axis=NamedTuple(), palettes=NamedTuple())
    plt -> draw!(grid, plt; axis=axis, palettes=palettes)
end

# %%

legend_kwargs = (position=:top, titleposition=:left)

function plot_vl_ratio(
    df;
    datalimits=x -> quantile(x, [0.01, 0.99]),
    legend=legend_kwargs,
    fname="vl_ratio",
)
    plt = data(df) * mapping(v_l_ratio_map) * density(datalimits=datalimits) * mapping(color=ds_mapping)
    fg = draw(plt, legend=legend)
    easy_save(fname; dir="$fig_dir/$enc")
    fg
end

function plot_dvl(
    df;
    legend=legend_kwargs,
    fname="dvl"
)
    plt = data(df) * mapping(v_Alfven_map, v_ion_map, color=ds_mapping)

    limit_axis = (; limits=((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    fg = draw(plt, axis=axis, legend=legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    map(slopes) do s
        lines!(1 .. 1000, (*)$s, linestyle=:dash, label="$s")
    end
    axislegend("slope", position=:ct)

    easy_save(fname; dir="$fig_dir/$enc")
    fg
end


function plot_dvl(; legend=legend_kwargs)
    fname = "dvl"

    plt = data_layer_a * mapping(v_Alfven_map, v_ion_map)

    limit_axis = (; limits=((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    fg = draw(plt, axis=axis, legend=legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    map(slopes) do s
        lines!(1 .. 1000, (*)$s, linestyle=:dash, label="$s")
    end
    axislegend("slope", position=:ct)

    easy_save(fname; dir="$fig_dir/$enc")
    fg
end

function plot_dvl_c()
    fname = "dvl"

    plt = data_layer_a * mapping(v_Alfven_map, v_ion_map)

    fig = Figure(size=(1000, 500))

    limit_axis = (; limits=((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    grid1 = plt |> draw!(fig[1, 1])

    slopes = [1.0, 0.7, 0.4, 0.1]
    for s in slopes
        ablines!(0, s, linestyle=:dash)
    end

    grid2 = plt |> draw!(fig[1, 2]; axis=axis)
    # ax2 = Axis(fig[1, 2]; axis...)
    # grid2 = draw!(ax2, plt)

    for s in slopes
        lines!(1 .. 1000, (*)$s, linestyle=:dash, label="$s")
    end
    axislegend("slope", position=:ct)

    # add labels
    add_labels!([fig[1, 1], fig[1, 2]];)
    pretty_legend!(fig, grid2)

    easy_save(fname)

    fig
end


