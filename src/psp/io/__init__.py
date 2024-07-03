from pytplot import get_data
import polars as pl


def time_stamp(ts):
    "Return POSIX timestamp as float."
    import pandas as pd

    return pd.Timestamp(ts, tz="UTC").timestamp()


def get_data_lf(name):
    da = get_data(name, xarray=True)
    df = da.to_pandas().reset_index()
    return pl.LazyFrame(df).with_columns(
        pl.col("time").dt.cast_time_unit("us"),
    )
