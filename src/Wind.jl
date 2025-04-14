module Wind
using Base: Fix2
using Speasy: SpeasyProduct
using PartialFunctions
using Unitful
using SPEDAS: DataSet, ulabel

unitify(u) = (*)$u
# WI_K0_SWE_RTN : Wind Solar Wind Experiment, Key Parameters in RTN [PRELIM] 
# WI_PM_3DP : Ion moments (computed on-board) @ 3 second (spin) resolution, PESA LOW, Wind 3DP
# WI_PLSP_3DP : Ion omnidirectional fluxes 0.4-3 keV and moments, often at ~24 second resolution, PESA Low, Wind 3DP

WI_PM_3DP_labels = ["Proton"] # "Proton (3DP, PESA Low)"
WI_ELM2_3DP_labels = ["Electron"] # "Electron (3DP, EESA Low)"

B = SpeasyProduct("WI_H4-RTN_MFI/BRTN")

V = SpeasyProduct("WI_K0_SWE_RTN/V_RTN")

V_RTN = SpeasyProduct("WI_H1_SWE_RTN/Proton_V_nonlin")
# Proton_V_moment

B_GSE = SpeasyProduct("WI_H2_MFI/BGSE")
V_GSE = SpeasyProduct("WI_PM_3DP/P_VELS")

n_p = SpeasyProduct("WI_PM_3DP/P_DENS"; labels=WI_PM_3DP_labels)

n = DataSet(
    "Density",
    [
        n_p,
        SpeasyProduct("WI_PLSP_3DP/MOM.P.DENSITY"),
        SpeasyProduct("WI_ELM2_3DP/DENSITY"; labels=WI_ELM2_3DP_labels)
    ]
)

Temp = DataSet(
    "Temperature",
    [
        SpeasyProduct("WI_PM_3DP/P_TEMP"; labels=WI_PM_3DP_labels),
        SpeasyProduct("WI_PLSP_3DP/MOM.P.AVGTEMP"),
        # SpeasyProduct("WI_H0_SWE/Te"), Definition range <DateTimeRange: 1994-12-29T00:00:02+00:00 -> 2001-05-31T23:59:57+00:00>
        SpeasyProduct("WI_ELM2_3DP/AVGTEMP"; labels=WI_ELM2_3DP_labels),
    ];
)

pTemp_ani = unitify(u"eV") ∘ SpeasyProduct("WI_PLSP_3DP/MOM.P.MAGT3")
alphaTemp_ani = unitify(u"eV") ∘ SpeasyProduct("WI_PLSP_3DP/MOM.A.MAGT3"; labels=["Alpha_MagT3_Perp1", "Alpha_MagT3_Perp2", "Alpha_MagT3_Para"]) # original labels ["BX_GSE", "BY_GSE", "BZ_GSE"] is not right
eTemp_T3 = SpeasyProduct("WI_ELM2_3DP/MAGT3")
eTemp_ani = SpeasyProduct("WI_H0_SWE/Te_anisotropy"; CATDESC="Temperature anisotropy = Te_para / Te_perp")
pW_ani = DataSet("Thermal speed", ["WI_H1_SWE/Proton_Wperp_nonlin", "WI_H1_SWE/Proton_Wpar_nonlin", "WI_H1_SWE/Proton_Wperp_moment", "WI_H1_SWE/Proton_Wpar_moment"])

Temp_ani = [pTemp_ani, alphaTemp_ani, eTemp_T3]
end