using LaTeXStrings

# %%
# Anisotry related plots
Λ_lab = L"\Lambda"
Λ_i_lab = L"\Lambda_i"
Λ_e_lab = L"\Lambda_e"

Λ_t_map = :Λ_t => L"\Lambda_{theory}"
Λ_ion_map = :Λ_ion => Λ_i_lab
Λ_e_map = :Λ_e => Λ_e_lab
Λ_map = :Λ => Λ_lab

Λs = ["Λ_t", "Λ_ion", "Λ_e", "Λ"]

"""
Compare theoretical anisotropy with the observed anisotropy
"""
function plot_anistropy_comparison_2d(df; kwargs...)
    fname = "anisotropy_comparison_2d"
    r = renamer(["Λ_ion" => "ion", "Λ_e" => "electron", "Λ" => "total"])

    variables = intersect(names(df), ["Λ_ion", "Λ_e", "Λ"])
    temp_df = @chain begin
        stack(df, variables, [:time, :dataset, :Λ_t])
    end

    mapping_layer = mapping(Λ_t_map, :value => Λ_lab)
    plt1 = data(temp_df) * mapping(row=:variable => r, col=:dataset)

    # draw a dashed line with slope 1
    df2 = (Λ_t=[0, 1], value=[0, 1])
    plt2 = data(df2) * visual(Lines)

    plt = (plt1 + plt2) * mapping_layer
    draw(plt, facet=(; linkxaxes=:minimal, linkyaxes=:none); kwargs...)
    easy_save(fname; dir="$fig_dir/$enc")
end

"""
Plot the theoretical anisotropy
"""
function plot_anistropy_theory(df)
    fname = "anisotropy_theory"

    data_layer_a = data(df) * mapping(color=ds_mapping, marker=ds_mapping)

    plt = data_layer_a * mapping(Λ_t_map)

    fig = Figure(size=(1000, 500))
    grid1 = plt * density() |> draw!$fig[1, 1]
    grid2 = plt * mapping(dodge=ds_mapping) * histogram() |> draw!$fig[1, 2]

    add_labels!([fig[1, 1], fig[1, 2]])
    pretty_legend!(fig, grid1)
    easy_save(fname; dir="$fig_dir/$enc")

    fig
end

function plot_anistropy(df)
    fname = "anisotropy"

    variables = intersect(names(df), Λs)

    plt = data(stack(df, variables, [:time, :dataset]))

    plt *= mapping(:value, row=:variable => latexstring, color=ds_mapping)

    fig = Figure(size=(1000, 500))
    facet = (; linkxaxes=:minimal, linkyaxes=:minimal)

    grid1 = draw!(fig[1, 1], plt * density(), facet=facet)
    grid2 = draw!(fig[1, 2], plt * histogram(), facet=facet)

    add_labels!([fig[1, 1], fig[1, 2]])
    pretty_legend!(fig, grid1)
    easy_save("$(fname)$psp_p_instr", fig)

    fig
end