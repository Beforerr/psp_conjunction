module PSPAnisotropy
using Speasy
include("PSP.jl")
include("Wind.jl")
include("THEMIS.jl")
include("dataset.jl")

using CSV
using Dates
using DataFrames, DataFramesMeta
using CategoricalArrays
using DrWatson

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


function workload()
    psp_config = Dict(:id => "PSP", :B => PSP.B, :V => PSP.V, :n => PSP.n_spi, :tau => 30)
    wind_config = Dict(:id => "Wind", :B => Wind.B_GSE, :V => Wind.V_GSE_K0, :n => Wind.n_p_K0, :tau => 30)
    thm_config = Dict(:id => "THEMIS", :B => THEMIS.B_FGL_GSE, :n => THEMIS.n_ion, :V => THEMIS.V_GSE, :tau => 30)
    configs = [psp_config, wind_config, thm_config]

    df = mapreduce(vcat, 7:9) do enc
        tpsp, tearth = get_timerange(enc)
        mapreduce(vcat, configs) do c
            id = c[:id]
            timerange = id == "PSP" ? tpsp : tearth
            c[:t0] = Date(timerange[1])
            c[:t1] = Date(timerange[2])
            res, = produce_or_load(c, datadir(); tag = false) do c
                c[:events] = ids_finder(c[:B], c[:t0], c[:t1], Second(c[:tau]), c[:V], c[:n])
                c
            end
            @rtransform!(res["events"], :enc = enc, :id = id)
        end
    end
    df.id = categorical(df.id; compress = true)
    return df
end

end
