import AlgebraOfGraphics: draw!
using Logging

function easy_save(name, fig; dir="$fig_dir/$enc")
    path = "$dir/$name"

    save("$path.png", fig, px_per_unit=4)
    save("$path.pdf", fig)
    
    # log the path saved
    @info "Saved $path"
end

function load(path::String)
    df = path |> Arrow.Table |> DataFrame |> dropmissing

    # Iterate through each column in the DataFrame
    filter(row -> all(x -> !(x isa Number && isnan(x)), row), df)
end

function load(enc, name; suffix="", data_dir= "../data", fmt = "arrow")
    path = "$data_dir/$enc/events.$name$suffix.$fmt"
    load(path)
end

function process(df)
    df = @chain df begin
        @transform(
            :"B.mean" = (:"B.before" .+ :"B.after") ./ 2,
            :"n.mean" = (:"n.before" .+ :"n.after") ./ 2,   
        )
        @transform(
            :j0_k = abs.(:j0_k),
            :j0_k_norm = abs.(:j0_k_norm),
            :"v.Alfven.change.l" = abs.(:"v.Alfven.change.l"),
            :"v.ion.change.l" = abs.(:"v.ion.change.l")
        )
        @transform :Λ_t = 1 .- (:"v.ion.change.l" ./ :"v.Alfven.change.l") .^ 2
    end

    if "T.before" in names(df)
        df = @chain df begin
            @transform :"T.mean" = (:"T.before" .+ :"T.after") ./ 2
        end
    end

    return df
end

function keep_good_fit(df)
    df = @chain df begin
        filter(:"fit.stat.rsquared" => >(0.9), _)
    end
end



log_axis = (yscale=log10, xscale=log10)

function draw!(grid; axis=NamedTuple(), palettes=NamedTuple())
    plt -> draw!(grid, plt; axis=axis, palettes=palettes)
end


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