module Dataset
using CategoricalArrays
import Discontinuity
using Unitful
using Unitful: μ0
using Logging

DEFAULT_ENC = 8

function load(enc, name; dataset = missing, dir = "./data")
    dir = "$dir/enc$enc"
    filename = filter(contains(Regex("updated_events_$name")), readdir(dir, join = true))[1]
    @info "Loading $filename"
    df = Discontinuity.load(filename)
    @info "Loaded $(size(df, 1)) data points"
    # add dataset column with the name of the dataset
    dataset = ismissing(dataset) ? name : dataset
    df.dataset .= dataset
    df.dataset = categorical(df.dataset)
    df.enc .= enc
    df.enc = categorical(df.enc)
    return df
end

load_psp(enc = DEFAULT_ENC) = load(enc, "PSP"; dataset = "Parker Solar Probe")

function load_all(enc)
    dfs = [
        load_psp(enc),
        load(enc, "THEMIS"; dataset = "ARTEMIS"),
        load(enc, "Wind"),
        # load(enc, "Solo"; dataset="Solar Orbiter")
    ]
    df = reduce(vcat, dfs, cols = :intersect)
    levels!(df.dataset, ["Parker Solar Probe", "ARTEMIS", "Wind"])
    return df
end

end
