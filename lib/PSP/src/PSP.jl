module PSP
using Unitful
import CDAWeb
using Speasy: SpeasyProduct, @spz_str
using SpaceDataModel: DataSet

import CSV
using NCDatasets
using DataFrames, DimensionalData
using DimensionalData: TimeDim, Ti
using LaTeXStrings

struct CDADimArray{N}
    dataset::String
    variable::String
    kwargs::N
end

CDADimArray(dataset, variable) = CDADimArray(dataset, variable, (;))

function (cdadim::CDADimArray)(tmin, tmax; kw...)
    A = DimArray(CDAWeb.get_data(cdadim.dataset, cdadim.variable, tmin, tmax; orig = true, cdadim.kwargs..., kw...))
    dim = dims(A, TimeDim)
    T = eltype(dim)
    return @view A[Ti(T(tmin) .. T(tmax))]
end

function (cdadim::CDADimArray)(trange; kw...)
    return cdadim(trange[1], trange[2]; kw...)
end

function cda_DimArray(dataset, variable)
    return (t0, t1; kw...) -> begin
        A = DimArray(CDAWeb.get_data(dataset, variable, t0, t1; orig = true, kw...))
        dim = dims(A, TimeDim)
        T = eltype(dim)
        return @view A[Ti(T(t0) .. T(t1))]
    end
end

const psp_events = CSV.read("data/psp_events.csv", DataFrame; dateformat = "yyyy-mm-dd HH:MM")

const B = spz"cda/PSP_FLD_L2_MAG_RTN_4_SA_PER_CYC/psp_fld_l2_mag_RTN_4_Sa_per_Cyc"
# const B_SC = spz"cda/PSP_FLD_L2_MAG_SC/psp_fld_l2_mag_SC"
const B_SC = CDADimArray("PSP_FLD_L2_MAG_SC", "psp_fld_l2_mag_SC")
# const B_1MIN = spz"cda/PSP_FLD_L2_MAG_RTN_1MIN/psp_fld_l2_mag_RTN_1min"
const B_1MIN = CDADimArray("PSP_FLD_L2_MAG_RTN_1MIN", "psp_fld_l2_mag_RTN_1min")

# julia> @b DimArray(CDAWeb.get_data("PSP_FLD_L2_MAG_SC", "psp_fld_l2_mag_SC", tmin_psp, tmin_psp+Hour(5); orig=true))
# 39.605 ms (1579 allocs: 120.921 MiB, 5.74% gc time)
# 43.896 ms (1608 allocations: 193.39 MiB)
# julia> @b PSP.B_SC(tmin_psp, tmin_psp+Hour(5))
# 93.862 ms (277 allocs: 9.891 KiB)

const n_spi = CDADimArray("PSP_SWP_SPI_SF00_L3_MOM", "DENS")
# const n_spi = SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/DENS"; labels = ["SPI Proton"])
const n_alpha = CDADimArray("PSP_SWP_SPI_SF0A_L3_MOM", "DENS")
const n_spc = Base.Fix2(*, u"cm^-3") ∘ SpeasyProduct("cda/PSP_SWP_SPC_L3I/np_moment"; labels = ["SPC Proton"])
const n_sqtn = SpeasyProduct("cda/PSP_FLD_L3_SQTN_RFS_V1V2/electron_density"; labels = ["SQTN Electron"])
const n_rfs = SpeasyProduct("cda/PSP_FLD_L3_RFS_LFR_QTN/N_elec"; labels = ["RFS Electron"])
const n = DataSet("Density", [n_spi, n_spc, n_sqtn])
const n_spi_sqtn = DataSet("Density", [n_spi, n_sqtn])

function A_He(tmin, tmax; n_p = nothing)
    n_p = @something n_p n_spi(tmin, tmax)
    n_α = n_alpha(tmin, tmax)
    return n_α ./ n_p .* 100
end

const V = CDADimArray("PSP_SWP_SPI_SF00_L3_MOM", "VEL_RTN_SUN")
# const V_SC = spz"cda/PSP_SWP_SPI_SF00_L3_MOM/VEL_SC"
const V_SC = CDADimArray("PSP_SWP_SPI_SF00_L3_MOM", "VEL_SC")

# const pTemp = SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/TEMP"; labels = ["SPI Proton"])
const pTemp = CDADimArray("PSP_SWP_SPI_SF00_L3_MOM", "TEMP")
# const eTemp = SpeasyProduct("PSP_FLD_L3_SQTN_RFS_V1V2/electron_core_temperature"; labels = ["SQTN Electron core"])
const eTemp = CDADimArray("PSP_FLD_L3_SQTN_RFS_V1V2", "electron_core_temperature")
#  @b DimArray(CDAWeb.get_data("PSP_FLD_L3_SQTN_RFS_V1V2", "electron_core_temperature", tmin,tmax; orig=true))
# 1.089 ms (750 allocs: 1.477 MiB)
const T = DataSet("Temperature", [pTemp, eTemp])


"""
    read_electron_temperature(filename; dir)

Read electron temperature data from CSV file into a DimensionalData structure.
Returns a DimArray with dimensions of time and temperature components (parallel and perpendicular).s
"""
function read_electron_temperature(filename; dir = joinpath(pwd(), "data", "electron_fit_Halekas"))
    # Construct full path to the file
    filepath = joinpath(dir, filename)

    # Read CSV file
    df = CSV.File(filepath; dateformat = "yyyy-mm-dd/HH:MM:SS.sss", drop = [3])

    para = DimArray(
        df.coretpar_data, Ti(df.coretpar_time);
        metadata = Dict(:ylabel => "T (eV)", :units => "eV", :labels => L"T_{e,\parallel}")
    )
    perp = DimArray(
        df.coretperp_data, Ti(df.coretpar_time);
        metadata = Dict(:ylabel => "T (eV)", :units => "eV", :labels => L"T_{e,\perp}")
    )
    # Create DimArray with appropriate dimensions
    return DimStack((; para, perp); metadata = Dict(:ylabel => "T (eV)"))
end


"""
    read_electron_temperature(; data_dir=datadir())

Read all electron temperature data files.
"""
function read_electron_temperature(; kw...)
    # Define the files to read
    files = [
        "e7e8_coretemp.csv" => [7, 8],       # Encounters 7-8 (higher resolution)
        "e9_coretemp.csv" => [9],             # Encounter 9
    ]
    return cat(read_electron_temperature.(first.(files); kw...)...; dims = Ti)
end


@views function read_proton_temperature(path::String)
    ds = NCDataset(path, "r"; maskingvalue = NaN)
    Tp_spani = collect(ds["Tp_spani_b"])
    time = Ti(ds["time"] |> collect)
    # ds = YAXArrays.open_dataset(path; driver = :netcdf)
    # Tp_spani = readcubedata(only(values(ds.cubes)))

    Tpara = DimArray(Tp_spani[1, :], time; metadata = Dict(:labels => L"T_{p,\parallel}"))
    Tperp = DimArray(Tp_spani[2, :][:], time; metadata = Dict(:labels => L"T_{p,\perp}"))
    # replace value larger than 1000 with missing
    MAX = 1500
    Tpara[Tpara .> MAX] .= NaN
    Tperp[Tperp .> MAX] .= NaN
    return DimStack((; para = Tpara, perp = Tperp); metadata = Dict(:ylabel => "T (eV)"))
end

function read_proton_temperature(enc::Integer; burst = false, kws...)
    filename = burst ? "Tp_spanib_b.nc" : "Tp_spani_b.nc"
    return read_proton_temperature("data/psp_e0$enc/$filename"; kws...)
end

function read_proton_temperature(ranges; kws...)
    return cat(read_proton_temperature.(ranges)...; dims = Ti)
end

read_proton_temperature(; kws...) = read_proton_temperature(7:8; kws...)


end
