using CSV
using DataFrames
using Dates
using DimensionalData
using DrWatson
using Unitful
using NetCDF
using YAXArrays

"""
    read_electron_temperature(filename; data_dir=datadir())

Read electron temperature data from CSV file into a DimensionalData structure.
Returns a DimArray with dimensions of time and temperature components (parallel and perpendicular).

# Arguments
- `filename`: Name of the CSV file in the electron_fit_Halekas directory
- `data_dir`: Base directory for data, defaults to DrWatson's datadir()

# Returns
- DimArray with electron temperature data
"""
function read_electron_temperature(filename; data_dir=datadir(), unit=u"eV")
    # Construct full path to the file
    filepath = joinpath(data_dir, filename)

    # Read CSV file
    df = CSV.File(filepath; dateformat="yyyy-mm-dd/HH:MM:SS.sss", drop=[3])

    temp_data = hcat(df.coretpar_data, df.coretperp_data) * unit

    # Create DimArray with appropriate dimensions
    return DimArray(
        temp_data,
        (
            Ti(df.coretpar_time),
            Dim{:component}([:parallel, :perpendicular])
        ),
        name=:electron_temperature
    )
end

"""
    read_all_electron_temperature(; data_dir=datadir())

Read all electron temperature data files.
"""
function read_electron_temperature(; data_dir=datadir("electron_fit_Halekas"))
    # Define the files to read
    files = [
        "e7e8_coretemp.csv" => [7, 8],       # Encounters 7-8 (higher resolution)
        "e9_coretemp.csv" => [9]             # Encounter 9
    ]
    mapreduce(vcat, files) do (file, _)
        read_electron_temperature(file; data_dir=data_dir)
    end
end

function read_proton_temperature(; path="data/psp_e07/Tp_spanib_b.nc", unit=u"eV")
    ds = YAXArrays.open_dataset(path; driver=:netcdf)
    Tp_spani = readcubedata(ds.Tp_spanib_b)
    return DimArray(transpose(Tp_spani) * unit)
end