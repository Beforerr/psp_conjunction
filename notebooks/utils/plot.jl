include("anisotry.jl")

fig_dir = "../figures"

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

jA_map = :j_Alfven => jA_lab
jA_log_map = :j_Alfven => log10 => L"Log %$jA_lab"

l_map = :L_k => l_lab
l_norm_map = :L_k_norm => l_norm_lab
l_log_map = :L_k => log10 => L"Log %$l_lab"
l_norm_log_map = :L_k_norm => log10 => L"Log %$l_norm_lab"

current_map = :j0_k => j_lab
current_norm_map = :j0_k_norm => j_norm_lab

j_map = :j0_k => j_lab
j_norm_map = :j0_k_norm => j_norm_lab
j_log_map = :j0_k => log10 => L"Log %$j_lab"
j_norm_log_map = :j0_k_norm => log10 => L"Log %$j_norm_lab"

v_Alfven_map = "v.Alfven.change.l" => L"\Delta V_{A,l}"
v_ion_map = "v.ion.change.l" => L"\Delta V_{i,l}"

# %%

function plot_dvl(; legend=(position=:top, titleposition=:left))
    fname = "dvl"

    # plt = data_layer_a * mapping(v_Alfven_map, v_ion_map) * (linear(interval=nothing) + mapping())
    plt = data_layer_a * mapping(v_Alfven_map, v_ion_map)

    limit_axis = (; limits=((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    fg = draw(plt, axis=axis, legend=legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    lns = [lines!(1 .. 1000, (*) $ s, linestyle=:dash, label = "$s") for s in slopes]
    axislegend("slope", position = :ct)

    easy_save(fname)
    fg
end



function plot_dvl_c()
    fname = "dvl"

    # plt = data_layer_a * mapping(v_Alfven_map, v_ion_map) * (linear(interval=nothing) + mapping())
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
        lines!(1 .. 1000, (*) $ s, linestyle=:dash, label = "$s")
    end
    axislegend("slope", position = :ct)

    # add labels
    add_labels!([fig[1, 1], fig[1, 2]]; )
    pretty_legend!(fig, grid2)

    easy_save(fname)

    fig
end


