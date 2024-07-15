using CategoricalArrays
import Discontinuity

function load(enc, name; dataset=missing, data_dir=datadir())
    dir = "$data_dir/$enc"
    filename = filter(contains(Regex("updated_events_$name")), readdir(dir, join=true))[1]
    df = Discontinuity.load(filename)

    # add dataset column with the name of the dataset
    dataset = ismissing(dataset) ? name : dataset
    df.dataset .= dataset
    df.dataset = categorical(df.dataset)
    return df
end

