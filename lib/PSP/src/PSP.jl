module PSP
using Unitful
using Speasy: SpeasyProduct, @spz_str
using SpaceDataModel: DataSet

import CSV
using YAXArrays, NetCDF
using DataFrames, DimensionalData
using LaTeXStrings

const psp_events = CSV.read("data/psp_events.csv", DataFrame; dateformat="yyyy-mm-dd HH:MM")

B = spz"PSP_FLD_L2_MAG_RTN_4_SA_PER_CYC/psp_fld_l2_mag_RTN_4_Sa_per_Cyc"
const B_SC = spz"cda/PSP_FLD_L2_MAG_SC/psp_fld_l2_mag_SC"
B_1MIN = spz"PSP_FLD_L2_MAG_RTN_1MIN/psp_fld_l2_mag_RTN_1min"

n_spi = SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/DENS"; labels = ["SPI Proton"])
n_alpha = SpeasyProduct("PSP_SWP_SPI_SF0A_L3_MOM/DENS"; labels = ["SPI Alpha"])
n_spc = Base.Fix2(*, u"cm^-3") ∘ SpeasyProduct("PSP_SWP_SPC_L3I/np_moment"; labels = ["SPC Proton"])
n_sqtn = SpeasyProduct("PSP_FLD_L3_SQTN_RFS_V1V2/electron_density"; labels = ["SQTN Electron"])
n_rfs = SpeasyProduct("PSP_FLD_L3_RFS_LFR_QTN/N_elec"; labels = ["RFS Electron"])
n = DataSet("Density", [n_spi, n_spc, n_sqtn])
n_spi_sqtn = DataSet("Density", [n_spi, n_sqtn])

V = spz"cda/PSP_SWP_SPI_SF00_L3_MOM/VEL_RTN_SUN"
const V_SC = spz"cda/PSP_SWP_SPI_SF00_L3_MOM/VEL_SC"

pTemp = SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/TEMP"; labels = ["SPI Proton"])
eTemp = SpeasyProduct("PSP_FLD_L3_SQTN_RFS_V1V2/electron_core_temperature"; labels = ["SQTN Electron core"])
T = DataSet("Temperature", [pTemp, eTemp])


"""
    read_electron_temperature(filename; data_dir=datadir())

Read electron temperature data from CSV file into a DimensionalData structure.
Returns a DimArray with dimensions of time and temperature components (parallel and perpendicular).s
"""
function read_electron_temperature(filename; data_dir = datadir("electron_fit_Halekas"))
    # Construct full path to the file
    filepath = joinpath(data_dir, filename)

    # Read CSV file
    df = CSV.File(filepath; dateformat = "yyyy-mm-dd/HH:MM:SS.sss", drop = [3])

    para = DimArray(df.coretpar_data, Ti(df.coretpar_time);
        metadata = Dict(:ylabel => "T (eV)", :units => "eV", :label => L"T_{e,\parallel}")
    )
    perp = DimArray(df.coretperp_data, Ti(df.coretpar_time);
        metadata = Dict(:ylabel => "T (eV)", :units => "eV", :label => L"T_{e,\perp}")
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
    ds = YAXArrays.open_dataset(path; driver = :netcdf)
    Tp_spani = readcubedata(only(values(ds.cubes)))
    Tpara = DimArray(Tp_spani[1, :]; metadata = merge(Tp_spani.properties, Dict(:label => L"T_{p,\parallel}")))
    Tperp = DimArray(Tp_spani[2, :]; metadata = merge(Tp_spani.properties, Dict(:label => L"T_{p,\perp}")))

    # replace value larger than 1000 with missing
    MAX = 1500
    Tpara[Tpara .> MAX] .= NaN
    Tperp[Tperp .> MAX] .= NaN

    ds = DimStack((; para = Tpara, perp = Tperp); metadata = Dict(:ylabel => "T (eV)"))
    return set(ds, Dim{:time} => Ti)
end

function read_proton_temperature(enc::Integer; burst = false, kws...)
    filename = burst ? "Tp_spanib_b.nc" : "Tp_spani_b.nc"
    return read_proton_temperature("data/psp_e0$enc/$filename"; kws...)
end

function read_proton_temperature(ranges; kws...)
    return cat(read_proton_temperature.(ranges)...; dims = Ti)
end


end
