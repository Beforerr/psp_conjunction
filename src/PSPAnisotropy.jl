module PSPAnisotropy
using Speasy
using SpacePhysicsMakie: tplot, tlines!
using Dates
using DataFrames, DataFramesMeta
using CategoricalArrays
using DrWatson
using Discontinuity: ids_finder
using SPEDAS

export get_timerange, workload, get_vl_ratio_ts

include("meta.jl")
include("mva.jl")
include("calc.jl")

using PSP
using PSP: psp_events
include("Wind.jl")
include("THEMIS.jl")

include("plot.jl")

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

function produce(c, t0 = nothing, t1 = nothing)
    t0 = something(t0, c["t0"])
    t1 = something(t1, c["t1"])
    ids_finder(c["B"], t0, t1, c["V"], c["n"]; tau = Second(c["tau"]))
end

function workload()
    timeranges = get_timerange.(7:9)
    psp_timeranges = getindex.(timeranges, 1)
    earth_timeranges = getindex.(timeranges, 2)
    configs = (;
        PSP=@strdict(id = "PSP", B = PSP.B, V = PSP.V, n = PSP.n_spi, tau = 30, timeranges = psp_timeranges),
        Wind=@strdict(id = "Wind", B = Wind.B_GSE, V = Wind.V_GSE_3DP, n = Wind.n_p_3DP, tau = 30, timeranges = earth_timeranges),
        THM=@strdict(id = "THEMIS", B = THEMIS.B_FGL_GSE, n = THEMIS.n_ion, V = THEMIS.V_GSE, tau = 30, timeranges = earth_timeranges),
    )

    df = mapreduce(vcat, 7:9) do enc
        tpsp, tearth = get_timerange(enc)
        mapreduce(vcat, configs) do c
            id = c["id"]
            timerange = id == "PSP" ? tpsp : tearth
            c["t0"] = Date(timerange[1])
            c["t1"] = Date(timerange[2])
            res, = produce_or_load(c, datadir(); tag=false) do c
                c["events"] = ids_finder(c["B"], c["t0"], c["t1"], c["V"], c["n"]; tau=Second(c["tau"]))
                c
            end
            @rtransform!(res["events"], :enc = enc, :id = id)
        end
    end
    df.id = categorical(df.id; compress=true)
    return df, configs
end

end
