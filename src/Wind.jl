module Wind
using Speasy: SpeasyProduct, getdimarray
using DimensionalData: Y, DimStack, rebuild
using PartialFunctions
using Unitful
using SPEDAS: DataSet, ulabel, Product, replace_outliers!
using LaTeXStrings

unitify(u) = (*) $ u
# WI_K0_SWE_RTN : Wind Solar Wind Experiment, Key Parameters in RTN [PRELIM]
# WI_PM_3DP : Ion moments (computed on-board) @ 3 second (spin) resolution, PESA LOW, Wind 3DP (PRIMARY SCIENCE DATA)
# WI_PLSP_3DP : Ion omnidirectional fluxes 0.4-3 keV and moments, often at ~24 second resolution, PESA Low, Wind 3DP
# WI_H0_SWE : 6 - 12 sec Solar Wind Electron Moments
# WI_H1_SWE : 92-sec Solar Wind Alpha and Proton Anisotropy Analysis (PRIMARY SCIENCE DATA)
# WI_H1_SWE_RTN : Solar wind proton and alpha parameters, including anisotropic temperatures, derived by non-linear fitting of the measurements and with moment techniques
# WI_H5_SWE : 9 sec solar wind electron moments at 12 sec cadence

WI_PM_3DP_labels = ["Proton"] # "Proton (3DP, PESA Low)"
WI_ELM2_3DP_labels = ["Electron"] # "Electron (3DP, EESA Low)"

B = SpeasyProduct("WI_H4-RTN_MFI/BRTN")
B_RTN_1MIN = SpeasyProduct("WI_H3-RTN_MFI/BRTN")

V_RTN = SpeasyProduct("WI_K0_SWE_RTN/V_RTN") # Note: it contains some weird spikes

function combine_getdimarrays(ps, args...)
    das = getdimarray.(ps, args...)
    return cat(das...; dims = Y())
end

V_RTN_nonlin = Product(
    [
        "cda/WI_H1_SWE_RTN/Proton_VR_nonlin",
        "cda/WI_H1_SWE_RTN/Proton_VT_nonlin",
        "cda/WI_H1_SWE_RTN/Proton_VN_nonlin",
        "cda/WI_H1_SWE_RTN/Proton_V_nonlin",
    ],
    combine_getdimarrays
)

B_GSE = SpeasyProduct("WI_H2_MFI/BGSE")
B_GSE_1MIN = SpeasyProduct("WI_H0_MFI/BGSE")
V_GSE_3DP = SpeasyProduct("WI_PM_3DP/P_VELS")
V_GSE_K0 = SpeasyProduct("WI_K0_SWE/V_GSE")  # Note: it contains some weird spikes


n_p_K0 = replace_outliers! ∘ SpeasyProduct("WI_K0_SWE/Np"; labels = ["Proton"]) # Time resolution is 110 seconds
n_p_3DP = SpeasyProduct("WI_PM_3DP/P_DENS"; labels = WI_PM_3DP_labels)
# SpeasyProduct("WI_PLSP_3DP/MOM.P.DENSITY"), # Quite similar to "WI_PM_3DP/P_DENS"
n_e = SpeasyProduct("WI_ELM2_3DP/DENSITY"; labels = WI_ELM2_3DP_labels)
# SpeasyProduct("WI_H5_SWE/N_elec") # No data available
n_p_nonlin = SpeasyProduct("WI_H1_SWE/Proton_Np_nonlin", labels = ["Proton (non-linear fitting)"])

n = DataSet("Density", [n_p_K0, n_p_3DP, n_p_nonlin, n_e])
n_p_e = DataSet("Density", (n_p_K0, n_e))

# SpeasyProduct("WI_H0_SWE/Te"), Definition range <DateTimeRange: 1994-12-29T00:00:02+00:00 -> 2001-05-31T23:59:57+00:00>

T_p_PLSP = SpeasyProduct("WI_PLSP_3DP/MOM.P.AVGTEMP"; labels = [L"T_p"])

T = DataSet(
    "Temperature",
    [
        SpeasyProduct("WI_PM_3DP/P_TEMP"; labels = ["Proton (WI_PM_3DP)"]),
        T_p_PLSP,
        SpeasyProduct("WI_ELM2_3DP/AVGTEMP"; labels = WI_ELM2_3DP_labels),
    ]
)

pTemp_T3 = SpeasyProduct("WI_PLSP_3DP/MOM.P.MAGT3"; )
alphaTemp_T3 = SpeasyProduct("WI_PLSP_3DP/MOM.A.MAGT3"; labels = ["Alpha_MagT3_Perp1", "Alpha_MagT3_Perp2", "Alpha_MagT3_Para"]) # original labels ["BX_GSE", "BY_GSE", "BZ_GSE"] is not right
eTemp_T3 = SpeasyProduct("WI_ELM2_3DP/MAGT3")
# eTemp_ani = SpeasyProduct("WI_H0_SWE/Te_anisotropy"; CATDESC = "Temperature anisotropy = Te_para / Te_perp")


pW_ani = DataSet("Thermal speed", ["WI_H1_SWE/Proton_Wperp_nonlin", "WI_H1_SWE/Proton_Wpar_nonlin", "WI_H1_SWE/Proton_Wperp_moment", "WI_H1_SWE/Proton_Wpar_moment"])


function para_perp_avg(T3, s)
    para = rebuild(T3[Y(3)]; metadata = merge(T3.metadata, Dict(:label => L"T_{%$s,\parallel}")))
    perp = rebuild((T3[Y(1)] .+ T3[Y(2)]) / 2; metadata = merge(T3.metadata, Dict(:label => L"T_{%$s,\perp}")))
    return DimStack((; para, perp); metadata = Dict(:ylabel => "T (eV)"))
end

para_perp_avg(s) = T3 -> para_perp_avg(T3, s)

pTemp_T2 = para_perp_avg("p") ∘ pTemp_T3
alphaTemp_T2 = para_perp_avg("\alpha") ∘ alphaTemp_T3
eTemp_T2 = para_perp_avg("e") ∘ eTemp_T3

Temp_ani = [pTemp_T2, eTemp_T2]
end
