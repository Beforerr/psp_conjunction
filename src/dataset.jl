module Dataset
using CategoricalArrays
import Discontinuity
using Unitful
using Unitful: μ0
using Logging

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
