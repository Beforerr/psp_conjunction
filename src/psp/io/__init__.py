from pytplot import get_data
import polars as pl
from numbers import Number
import xarray
import numpy as np
import os


def time_stamp(ts):
    "Return POSIX timestamp as float."
    import pandas as pd

    return pd.Timestamp(ts, tz="UTC").timestamp()


def get_data_lf(name):
    da = get_data(name, xarray=True)
    df = da.to_pandas().reset_index()
    return pl.LazyFrame(df).with_columns(
        pl.col("time").dt.cast_time_unit("ns"),
    )


def clean_attributes(da):
    da.attrs = {
        k: v
        for k, v in da.attrs.items()
        if isinstance(v, (str, Number, bool, list, tuple))
    }
    return da


def save_tnames(tnames, path, format="netcdf"):
    os.makedirs(path, exist_ok=True)

    for tname in tnames:
        da = get_data(tname, xarray=True)
        da = convert_time(clean_attributes(da)).drop_duplicates(dim="time").to_dataset()
        if format == "netcdf":
            da.to_netcdf(path + "/" + tname + ".nc", group=tname)
        elif format == "zarr":
            da.to_zarr(path + "/" + tname + ".zarr", mode="w-")


def convert_time(da: xarray.DataArray, type="ms"):
    if np.issubdtype(da.time.dtype, np.datetime64):
        da = da.assign_coords(time=da.time.values.astype(f"datetime64[{type}]"))
    return da
