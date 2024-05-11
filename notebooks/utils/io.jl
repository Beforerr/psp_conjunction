using Logging

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
    end
    df |> process
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