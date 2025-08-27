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

using Intervals: Interval

function tTemp(x; dims = Ti)
    return mean.(eachslice(x; dims))
end

B_GSE = SpeasyProduct("THB_L2_FGM/thb_fgs_gseQ")
B_FGL_GSE = SpeasyProduct("THB_L2_FGM/thb_fgl_gseQ")

n_ion = SpeasyProduct("THB_L2_MOM/thb_peim_densityQ"; labels = ["Ion"], yscale = identity)
n_elec = SpeasyProduct("THB_L2_MOM/thb_peem_densityQ"; labels = ["Electron"], yscale = identity)
n = DataSet("Density", [n_ion, n_elec]; yscale = identity)

V_GSE = SpeasyProduct("THB_L2_MOM/thb_peim_velocity_gseQ") # 4.25 s time resolution

pTemp = SpeasyProduct("THB_L2_ESA/thb_peif_avgtempQ"; labels = ["Proton"])
eTemp = tTemp ∘ SpeasyProduct("THB_L2_MOM/thb_peem_t3_magQ"; labels = ["Electron"])
T = DataSet("Temperature", (pTemp, eTemp))

pTemp_ani = SpeasyProduct("THB_L2_MOM/thb_peim_t3_magQ"; yscale = identity)
eTemp_ani = SpeasyProduct("THB_L2_MOM/thb_peem_t3_magQ"; yscale = identity)

T_ani = DataSet("Temperature anisotropy", [pTemp_ani, eTemp_ani]; yscale = identity)


function get_themis_tmask(t0, t1)
    thx_v_gse = THEMIS.V_GSE(t0, t1)
    _times = @views SPEDAS.times(thx_v_gse)[(thx_v_gse[:, 1].>-200u"km/s").|(thx_v_gse[:, 2].<-50u"km/s")]
    dt = Minute(10)
    its = union([Interval(t - dt, t + dt) for t in _times])
    return tmask!(its)
end

end
