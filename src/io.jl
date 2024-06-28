using CategoricalArrays
import Discontinuity

function load(enc, name; dataset=missing,suffix="", data_dir= "../data", fmt = "arrow")
    path = "$data_dir/$enc/events.$name$suffix.$fmt"
    df = Discontinuity.load(path)

    # add dataset column with the name of the dataset
    if !ismissing(dataset)
        df.dataset .= dataset
        df.dataset = categorical(df.dataset)
    end
    return df
end