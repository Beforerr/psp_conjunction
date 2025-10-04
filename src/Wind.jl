module Wind
using Speasy: SpeasyProduct, getdimarray, @spz_str
import Speasy
using DimensionalData
using DimensionalData: X, Y, DimStack, rebuild, DimArray, TimeDim, Ti
using PartialFunctions
using Unitful
using SPEDAS: DataSet, Product, replace_outliers!
using LaTeXStrings
import CDAWeb

struct CDADimArray{N}
    dataset::String
    variable::String
    kwargs::N
end

CDADimArray(dataset, variable; kw...) = CDADimArray(dataset, variable, (; kw...))

function (cdadim::CDADimArray)(tmin, tmax; kw...)
    A = DimArray(CDAWeb.get_data(cdadim.dataset, cdadim.variable, tmin, tmax; cdadim.kwargs..., kw...); replace_invalid = true)
    dim = dims(A, TimeDim)
    T = eltype(dim)
    return if isempty(A)
        A
    else
        @view A[Ti(T(tmin) .. T(tmax))]
    end
end

function (cdadim::CDADimArray)(trange; kw...)
    return cdadim(trange[1], trange[2]; kw...)
end

function spz_DimArray(dataset, variable; kw...)
    return (t0, t1; _kw...) -> DimArray(SpeasyProduct("cda/$dataset/$variable")(t0, t1); kw..., _kw...)
end

unitify(u) = (*) $ u
# WI_K0_SWE_RTN : Wind Solar Wind Experiment, Key Parameters in RTN [PRELIM]
# WI_PM_3DP : Ion moments (computed on-board) @ 3 second (spin) resolution, PESA LOW, Wind 3DP (PRIMARY SCIENCE DATA)
# WI_PLSP_3DP : Ion omnidirectional fluxes 0.4-3 keV and moments, often at ~24 second resolution, PESA Low, Wind 3DP
# WI_H0_SWE : 6 - 12 sec Solar Wind Electron Moments
# WI_H1_SWE : 92-sec Solar Wind Alpha and Proton Anisotropy Analysis (PRIMARY SCIENCE DATA)
# WI_H1_SWE_RTN : Solar wind proton and alpha parameters, including anisotropic temperatures, derived by non-linear fitting of the measurements and with moment techniques
# WI_H5_SWE : 9 sec solar wind electron moments at 12 sec cadence

WI_PM_3DP_labels = ["Proton"]
WI_ELM2_3DP_labels = ["Electron"] # "Electron (3DP, EESA Low)"

const B = spz"cda/WI_H4-RTN_MFI/BRTN"
const B_RTN_1MIN = spz"cda/WI_H3-RTN_MFI/BRTN"
const B_GSE = CDADimArray("WI_H2_MFI", "BGSE"; orig = true)
# const B_GSE_1MIN = spz"cda/WI_H0_MFI/BGSE"
const B_GSE_1MIN = CDADimArray("WI_H0_MFI", "BGSE")

function combine_getdimarrays(ps, args...)
    das = getdimarray.(ps, args...)
    return cat(das...; dims = Y())
end

V_RTN_nonlin = Product(spz"cda/WI_H1_SWE_RTN/Proton_VR_nonlin,Proton_VT_nonlin,Proton_VN_nonlin,Proton_V_nonlin"; transformation = combine_getdimarrays)

# const V_GSE_3DP = spz"cda/WI_PM_3DP/P_VELS" #about 3.1s/Sample
const V_GSE_3DP = CDADimArray("WI_PM_3DP", "P_VELS") #about 3.1s/Sample
const V_GSE_K0 = CDADimArray("WI_K0_SWE", "V_GSE") # Note: it contains some weird spikes, about 100s/Sample
const V_RTN = spz"cda/WI_K0_SWE_RTN/V_RTN" # Note: it contains some weird spikes

const n_p_K0 = replace_outliers! ∘ SpeasyProduct("cda/WI_K0_SWE/Np"; labels = ["Proton"]) # Time resolution is 110 seconds
const n_p_3DP = CDADimArray("WI_PM_3DP", "P_DENS") # "Proton (3DP, PESA Low)"
const n_p_nonlin = CDADimArray("WI_H1_SWE", "Proton_Np_nonlin") # "Proton (non-linear fitting)"

# SpeasyProduct("WI_PLSP_3DP/MOM.P.DENSITY"), # Quite similar to "WI_PM_3DP/P_DENS"
const n_e = SpeasyProduct("cda/WI_ELM2_3DP/DENSITY"; labels = WI_ELM2_3DP_labels)
# SpeasyProduct("WI_H5_SWE/N_elec") # No data available

const n_α_nonlin = CDADimArray("WI_H1_SWE", "Alpha_Na_nonlin") # "Alpha (non-linear fitting)"
const n = DataSet("Density", [n_p_K0, n_p_3DP, n_p_nonlin, n_e])
const n_p_e = DataSet("Density", (n_p_K0, n_e))

# SpeasyProduct("WI_H0_SWE/Te"), Definition range <DateTimeRange: 1994-12-29T00:00:02+00:00 -> 2001-05-31T23:59:57+00:00>

const T_p_PLSP = CDADimArray("WI_PLSP_3DP", "MOM.P.AVGTEMP")

function A_He(tmin, tmax; n_p = nothing)
    n_p = @something n_p n_p_nonlin(tmin, tmax)
    n_α = n_α_nonlin(tmin, tmax)
    return n_α ./ n_p .* 100
end

const T = DataSet(
    "Temperature",
    [
        SpeasyProduct("WI_PM_3DP/P_TEMP"; labels = ["Proton (WI_PM_3DP)"]),
        T_p_PLSP,
        SpeasyProduct("WI_ELM2_3DP/AVGTEMP"; labels = WI_ELM2_3DP_labels),
    ]
)

const pTemp_T3 = CDADimArray("WI_PLSP_3DP", "MOM.P.MAGT3")
const alphaTemp_T3 = SpeasyProduct("WI_PLSP_3DP/MOM.A.MAGT3"; labels = ["Alpha_MagT3_Perp1", "Alpha_MagT3_Perp2", "Alpha_MagT3_Para"]) # original labels ["BX_GSE", "BY_GSE", "BZ_GSE"] is not right
const eTemp_T3 = CDADimArray("WI_ELM2_3DP", "MAGT3")
# eTemp_ani = SpeasyProduct("WI_H0_SWE/Te_anisotropy"; CATDESC = "Temperature anisotropy = Te_para / Te_perp")


const pW_ani = DataSet("Thermal speed", ["WI_H1_SWE/Proton_Wperp_nonlin", "WI_H1_SWE/Proton_Wpar_nonlin", "WI_H1_SWE/Proton_Wperp_moment", "WI_H1_SWE/Proton_Wpar_moment"])


function para_perp_avg(T3, s)
    para = rebuild(T3[X(3)]; metadata = merge(T3.metadata, Dict(:labels => L"T_{%$s,\parallel}")))
    perp = rebuild((T3[X(1)] .+ T3[X(2)]) / 2; metadata = merge(T3.metadata, Dict(:labels => L"T_{%$s,\perp}")))
    return DimStack((; para, perp); metadata = Dict(:ylabel => "T (eV)"))
end

para_perp_avg(s) = T3 -> para_perp_avg(T3, s)

const pTemp_T2 = para_perp_avg("p ") ∘ pTemp_T3
const alphaTemp_T2 = para_perp_avg("\alpha") ∘ alphaTemp_T3
const eTemp_T2 = para_perp_avg("e ") ∘ eTemp_T3

const Temp_ani = [pTemp_T2, eTemp_T2]
end
