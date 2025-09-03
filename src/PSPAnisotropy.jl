module PSPAnisotropy
using Speasy
using SpacePhysicsMakie: tplot, tlines!
using Dates
using DataFrames, DataFramesMeta
using CategoricalArrays
using DrWatson
using Discontinuity: ids_finder
using SPEDAS
using LaTeXStrings
using TimeseriesUtilities: tsplit

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
    t0_psp = floor(time - Day(2), Day)
    t1_psp = ceil(time + Day(2), Day)
    t0_earth = t0_psp + Δt_min
    t1_earth = t1_psp + Δt_max
    return (t0_psp, t1_psp), (t0_earth, t1_earth)
end

export produce

# Complete specification of the configuration
function produce(conf)
    conf["tau"] = Second(conf["tau"]) / Second(1) # convert to float to save in the file name
    conf, _ = produce_or_load(conf, datadir(); tag = false) do c
        @unpack t0, t1, B, V, n, tau, extra = c
        c["events"] = ids_finder(t0, t1, B, V, n, extra...; tau = Second(tau))
        c
    end
    return conf["events"]
end

"""
# Example
```julia
produce(psp_conf, timerange, taus)
```
"""
function produce(conf, timerange, taus; split = Day(1))
    tranges = tsplit(timerange..., split)
    return mapreduce(vcat, tranges) do trange
        new_conf = merge(conf, Dict("t0" => Date(trange[1]), "t1" => Date(trange[2])))
        df_taus = mapreduce(vcat, taus) do tau
            new_tau_conf = merge(new_conf, Dict("tau" => tau))
            df = produce(new_tau_conf)
            df.tau .= tau
            df
        end
        Discontinuity.remove_duplicates(df_taus; verbose = true)
    end
end

function produce(conf_tr_pairs, taus; kw...)
    df = mapreduce(vcat, conf_tr_pairs) do (conf, tr)
        @rtransform!(produce(conf, tr, taus; kw...), :id = conf["id"])
    end
    df.id = categorical(df.id; compress = true)
    return df
end

function workload(taus, encs = 7:9; kw...)
    df = mapreduce(vcat, encs) do enc
        timeranges = get_timerange(enc)
        pairs = [psp_conf, wind_conf] .=> timeranges
        @rtransform!(produce(pairs, taus; kw...), :enc = enc)
    end
    df.enc = categorical(df.enc; compress = true)
    return df
end

export psp_conf, wind_conf, thm_conf

psp_conf = @strdict(id = "PSP", B = PSP.B_SC, V = PSP.V_SC, n = PSP.n_spi, extra = (:A_He => PSP.A_He,))
wind_conf = @strdict(id = "Wind", B = Wind.B_GSE, V = Wind.V_GSE_3DP, n = Wind.n_p_3DP, extra = (:A_He => Wind.A_He,))
thm_conf = @strdict(id = "THEMIS", B = THEMIS.B_FGL_GSE, n = THEMIS.n_ion, V = THEMIS.V_GSE, extra = ())

function workload()
    df = mapreduce(vcat, 7:9) do enc
        tpsp, tearth = get_timerange(enc)
        mapreduce(vcat, configs) do c
            id = c["id"]
            timerange = id == "PSP" ? tpsp : tearth
            c["t0"] = Date(timerange[1])
            c["t1"] = Date(timerange[2])
            res, = produce_or_load(c, datadir(); tag = false) do c
                c["events"] = ids_finder(c["B"], c["t0"], c["t1"], c["V"], c["n"]; tau = Second(c["tau"]))
                c
            end
            @rtransform!(res["events"], :enc = enc, :id = id)
        end
    end
    df.id = categorical(df.id; compress = true)
    return df, configs
end

end
