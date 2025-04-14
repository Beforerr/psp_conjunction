module THEMIS
using StatsBase
using DimensionalData
using Speasy: SpeasyProduct
using SPEDAS: DataSet

function tTemp(x; dims=Ti)
    return mean.(eachslice(x; dims))
end

B_GSE = SpeasyProduct("THB_L2_FGM/thb_fgs_gseQ")
B_FGL_GSE = SpeasyProduct("THB_L2_FGM/thb_fgl_gseQ")

n = ["THB_L2_MOM/thb_peim_densityQ", "THB_L2_MOM/thb_peem_densityQ"]

V_GSE = SpeasyProduct("THB_L2_MOM/thb_peim_velocity_gseQ")

T = DataSet("Temperature", [
    "THB_L2_ESA/thb_peif_avgtempQ",
    tTemp ∘ SpeasyProduct("THB_L2_MOM/thb_peem_t3_magQ"; label="Electron")
])

pTemp_ani = SpeasyProduct("THB_L2_MOM/thb_peim_t3_magQ"; yscale=identity)
eTemp_ani = SpeasyProduct("THB_L2_MOM/thb_peem_t3_magQ"; yscale=identity)

T_ani = DataSet("Temperature anisotropy", [pTemp_ani, eTemp_ani]; yscale=identity)

end