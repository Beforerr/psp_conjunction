from space_analysis.meta import TempDataset
from space_analysis.utils.speasy import Variables

from beforerr.polars import pl_norm
import polars as pl

import astropy.units as u
from astropy.constants import m_p

from loguru import logger


def thermal_spd2temp(speed, speed_unit=u.km / u.s):
    return (m_p * (speed * speed_unit) ** 2 / 2).to("eV").value


def df_thermal_spd2temp(ldf: pl.LazyFrame, speed_col, speed_unit=u.km / u.s):
    df = ldf.collect()
    return df.with_columns(
        plasma_temperature=thermal_spd2temp(df[speed_col].to_numpy(), speed_unit)
    ).lazy()


def df_p2temp(ldf: pl.LazyFrame, p_col, density_col):
    """converts the pressure to temperature"""
    return ldf.with_columns(plasma_temperature=pl.col(p_col) * pl.col(density_col))


def validate(timerange):
    from sunpy.time import TimeRange

    if isinstance(timerange, TimeRange):
        return [timerange.start.to_string(), timerange.end.to_string()]


def _standardize_plasma_temperature(data: pl.LazyFrame, s_var):
    temperature_col = s_var.columns[0]

    if s_var.unit == "km/s":
        return data.pipe(df_thermal_spd2temp, temperature_col)
    elif s_var.unit == "eV/cm^3":
        return data.pipe(df_p2temp, temperature_col, "n")
    else:
        return data.rename({temperature_col: "plasma_temperature"})


def standardize_plasma_data(data: pl.LazyFrame, p_vars: Variables, meta=None):
    density_col = p_vars.data[0].columns[0]
    vec_cols = p_vars.data[1].columns

    data = data.with_columns(plasma_speed=pl_norm(vec_cols)).rename({density_col: "n"})

    if len(p_vars.data) > 2:
        return data.pipe(_standardize_plasma_temperature, p_vars.data[2])
    else:
        return data


def get_timerange(enc: int) -> list[str]:
    match enc:
        case 2:  # Encounter 2
            start = "2019-04-07T01:00"
            end = "2019-04-07T12:00"

            earth_start = "2019-04-09"
            earth_end = "2019-04-12"
        case 4:  # Encounter 4
            start = "2020-01-27"
            end = "2020-01-29"

            earth_start = "2020-01-29"
            earth_end = "2020-01-31"

    psp_timerange = [start, end]
    earth_timerange = [earth_start, earth_end]
    return psp_timerange, earth_timerange


# e_temp = conf.e_temp_var.to_polars().collect()


def standardize_e_temp_df(df: pl.LazyFrame, meta: TempDataset):
    para_col = meta.para_col
    perp_cols = meta.perp_cols
    if para_col is None or perp_cols is None:
        logger.warning(
            "No para_col or perp_cols specified for e_temp_meta. Skipping standardization."
        )
        logger.info(f"Possible columns: {df.columns}")
        return df
    else:
        return df.with_columns(
            e_temp_para=pl.col(para_col),
            e_temp_perp=(pl.col(perp_cols[0]) + pl.col(perp_cols[1])) / 2,
        ).drop([para_col, perp_cols[0], perp_cols[1]])


def standardize_ion_temp_df(df: pl.LazyFrame, meta: TempDataset):
    para_col = meta.para_col
    perp_cols = meta.perp_cols
    if para_col is None or perp_cols is None:
        logger.warning(
            "No para_col or perp_cols specified for ion_temp_meta. Skipping standardization."
        )
        logger.info(f"Possible columns: {df.columns}")
        return df
    else:
        return df.with_columns(
            ion_temp_para=pl.col(para_col),
            ion_temp_perp=(pl.col(perp_cols[0]) + pl.col(perp_cols[1])) / 2,
        ).drop([para_col, perp_cols[0], perp_cols[1]])
