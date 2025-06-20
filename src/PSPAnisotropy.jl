module PSPAnisotropy
using Speasy
using CSV
using Dates
using DataFrames, DataFramesMeta
using CategoricalArrays
using DrWatson
using Discontinuity: ids_finder
using SPEDAS

export get_timerange, workload

include("meta.jl")
include("mva.jl")
include("calc.jl")


include("PSP.jl")
include("Wind.jl")
include("THEMIS.jl")
include("dataset.jl")

const psp_events = CSV.read("data/psp_events.csv", DataFrame; dateformat = "yyyy-mm-dd HH:MM")

function get_timerange(enc)
    Δt_min = Day(2)
    Δt_max = Day(6)
    time = psp_events[enc, :Time]
    t0_psp = floor(time - Day(3), Day(1))
    t1_psp = ceil(time + Day(3), Day(1))
    t0_earth = t0_psp + Δt_min
    t1_earth = t1_psp + Δt_max
    return (t0_psp, t1_psp), (t0_earth, t1_earth)
end

function produce(c)
    ids_finder(c["B"], c["t0"], c["t1"], Second(c["tau"]), c["V"], c["n"])
end

function workload()
    psp_config = @strdict(id = "PSP", B = PSP.B, V = PSP.V, n = PSP.n_spi, tau = 30)
    wind_config = @strdict(id = "Wind", B = Wind.B_GSE, V = Wind.V_GSE_3DP, n = Wind.n_p_3DP, tau = 30)
    thm_config = @strdict(id = "THEMIS", B = THEMIS.B_FGL_GSE, n = THEMIS.n_ion, V = THEMIS.V_GSE, tau = 30)
    configs = [psp_config, wind_config, thm_config]

    df = mapreduce(vcat, 7:9) do enc
        tpsp, tearth = get_timerange(enc)
        mapreduce(vcat, configs) do c
            id = c["id"]
            timerange = id == "PSP" ? tpsp : tearth
            c["t0"] = Date(timerange[1])
            c["t1"] = Date(timerange[2])
            res, = produce_or_load(c, datadir(); tag = false) do c
                c["events"] = ids_finder(c["B"], c["t0"], c["t1"], Second(c["tau"]), c["V"], c["n"])
                c
            end
            @rtransform!(res["events"], :enc = enc, :id = id)
        end
    end
    df.id = categorical(df.id; compress = true)
    return df, configs
end

end
