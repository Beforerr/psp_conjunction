from astropy.constants import mu0
import astropy.units as u
import polars as pl
from loguru import logger


def calc_pressure_anisotropy(
    df: pl.DataFrame,
    density_col: str = "n",
    ion_temp_para_col: str = "ion_temp_para",
    ion_temp_perp_col: str = "ion_temp_perp",
    e_temp_para_col: str = "e_temp_para",
    e_temp_perp_col: str = "e_temp_perp",
    temp_unit: u.Unit = u.eV,
):
    if density_col not in df.columns:
        logger.warning(f"{density_col} not in dataframe")
        logger.info("Need plasma density to calculate pressure anisotropy")
        return df

    B = (df["B.before"].to_numpy() + df["B.after"].to_numpy()) / 2 * u.nT
    n = df[density_col].to_numpy() * u.cm**-3

    if ion_temp_para_col in df.columns and ion_temp_perp_col in df.columns:
        ion_temp_para = df[ion_temp_para_col].to_numpy() * temp_unit
        ion_temp_perp = df[ion_temp_perp_col].to_numpy() * temp_unit
        Λ_ion = (mu0 * n * (ion_temp_para - ion_temp_perp) / B**2).to(
            u.dimensionless_unscaled
        )
        df = df.with_columns(Λ_ion=Λ_ion)
    else:
        Λ_ion = False
        logger.info("Ion temperature columns not found")

    if e_temp_para_col in df.columns and e_temp_perp_col in df.columns:
        e_temp_para = df[e_temp_para_col].to_numpy() * temp_unit
        e_temp_perp = df[e_temp_perp_col].to_numpy() * temp_unit
        Λ_e = (mu0 * n * (e_temp_para - e_temp_perp) / B**2).to(
            u.dimensionless_unscaled
        )
        df = df.with_columns(Λ_e=Λ_e)
    else:
        Λ_e = False
        logger.info("Electron temperature columns not found")

    if Λ_e and Λ_ion:
        Λ = Λ_ion + Λ_e
        df = df.with_columns(Λ=Λ)

    return df
