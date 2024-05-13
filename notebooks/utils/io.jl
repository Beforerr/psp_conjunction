using Logging

function extract_columns_of_type(df::DataFrame, T::Type)
    return select(df, [name for col in pairs(eachcol(df)) if eltype(col) === T])
end

function load(path::String)
    df = path |> Arrow.Table |> DataFrame |> dropmissing

    # Iterate through each column in the DataFrame
    filter(row -> all(x -> !(x isa Number && isnan(x)), row), df)
end

function load(enc, name; dataset=missing,suffix="", data_dir= "../data", fmt = "arrow")
    path = "$data_dir/$enc/events.$name$suffix.$fmt"
    df = load(path)

    # add dataset column with the name of the dataset
    if !ismissing(dataset)
        df.dataset .= dataset
        df.dataset = categorical(df.dataset)
    end
    df |> process
end

function keep_good_fit(df)
    df = @chain df begin
        filter(:"fit.stat.rsquared" => >(0.9), _)
    end
end

# dn_over_n = ("n.change", "n.mean") => (/) => L"\Delta n/n"
# dB_over_B = ("B.change", "b_mag") => (/) => L"\Delta B/B"
# dT_over_T = ("T.change", "T.mean") => (/) => L"\Delta T/T"

function process(df)
    # Convert all columns of Float32 to Float64
    for col in names(df, Float32)
        df[!, col] = Float64.(df[!, col])
    end


    df = @chain df begin
        @transform(
            :"B.mean" = (:"B.before" .+ :"B.after") ./ 2,
            :"n.mean" = (:"n.before" .+ :"n.after") ./ 2,   
        )
        @transform(
            :dB_over_B = (:"B.change" ./ :"B.mean"),
            :dn_over_n = (:"n.change" ./ :"n.mean"),
        )
        @transform(
            :j0_k = abs.(:j0_k),
            :j0_k_norm = abs.(:j0_k_norm),
            :"v.Alfven.change.l" = abs.(:"v.Alfven.change.l"),
            :"v.ion.change.l" = abs.(:"v.ion.change.l")
        )
        @transform :Λ_t = 1 .- (:"v.ion.change.l" ./ :"v.Alfven.change.l") .^ 2
        unique!(["t.d_start", "t.d_end"])
    end

    if "T.before" in names(df)
        df = @chain df begin
            @transform :"T.mean" = (:"T.before" .+ :"T.after") ./ 2
        end
    end

    df |> keep_good_fit
end