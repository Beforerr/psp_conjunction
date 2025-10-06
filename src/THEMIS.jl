## THB_L2_MOM
# `thb_peem_t3_magQ`: Electron Temperature, Field Aligned (TprpFA1, TprpFA2, TparFA)
# `thb_peim_t3_magQ`: Ion Temperature, Field Aligned (TprpFA1, TprpFA2, TparFA)
# `thb_peem_ptens_magQ`: Electron Pressure Tensor, Field Aligned
# `thb_peim_ptens_magQ`: Ion Pressure Tensor, Field Aligned

module THEMIS
using StatsBase
using DimensionalData
using Speasy: SpeasyProduct, getdimarray
using SPEDAS: DataSet, tsort, times, tmask!
using Dates
using Unitful
using LaTeXStrings
using ..PSPAnisotropy: CDADimArray

using Intervals: Interval

function tTemp(x; dims = Ti)
    return mean.(eachslice(x; dims))
end

const B_GSE = SpeasyProduct("cda/THB_L2_FGM/thb_fgs_gseQ")
const B_FGL_GSE = DimArray ∘ SpeasyProduct("cda/THB_L2_FGM/thb_fgl_gseQ")

const n_ion = SpeasyProduct("cda/THB_L2_MOM/thb_peim_densityQ"; labels = ["Ion"], yscale = identity)
const n_elec = SpeasyProduct("cda/THB_L2_MOM/thb_peem_densityQ"; labels = ["Electron"], yscale = identity)
const n = DataSet("Density", [n_ion, n_elec]; yscale = identity)

const V_GSE = CDADimArray("THB_L2_MOM", "thb_peim_velocity_gseQ") # 4.25 s time resolution

const pTemp = SpeasyProduct("cda/THB_L2_ESA/thb_peif_avgtempQ"; labels = ["Proton"])
const eTemp = tTemp ∘ SpeasyProduct("cda/THB_L2_MOM/thb_peem_t3_magQ"; labels = ["Electron"])
const T = DataSet("Temperature", (pTemp, eTemp))

const pTemp_ani = SpeasyProduct("cda/THB_L2_MOM/thb_peim_t3_magQ"; yscale = identity)
const eTemp_ani = CDADimArray("THB_L2_MOM", "thb_peem_t3_magQ")

const T_ani = DataSet("Temperature anisotropy", [pTemp_ani, eTemp_ani]; yscale = identity)

function para_perp_avg(T3, s)
    para = rebuild(T3[X(3)]; metadata = merge(T3.metadata, Dict(:labels => L"T_{%$s,\parallel}")))
    perp = rebuild((T3[X(1)] .+ T3[X(2)]) / 2; metadata = merge(T3.metadata, Dict(:labels => L"T_{%$s,\perp}")))
    return DimStack((; para, perp); metadata = Dict(:ylabel => "T (eV)"))
end
para_perp_avg(s) = T3 -> para_perp_avg(T3, s)

const eTemp_T2 = para_perp_avg("e") ∘ eTemp_ani


function get_themis_tmask(t0, t1)
    thx_v_gse = THEMIS.V_GSE(t0, t1)
    _times = @views SPEDAS.times(thx_v_gse)[(thx_v_gse[:, 1] .> -200u"km/s") .| (thx_v_gse[:, 2] .< -50u"km/s")]
    dt = Minute(10)
    its = union([Interval(t - dt, t + dt) for t in _times])
    return tmask!(its)
end

end
