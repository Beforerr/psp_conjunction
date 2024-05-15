from space_analysis.ds.meta import Meta, PlasmaMeta, TempMeta
from discontinuitypy.config import SpeasyIDsConfig
from discontinuitypy.missions import WindMeta
from pathlib import Path

from datetime import timedelta
from sunpy.time import TimeRange
from typing import Literal

from space_analysis.utils.speasy import Variables
from beforerr.polars import pl_norm
import polars as pl

from speasy import SpeasyVariable
from rich import print

from loguru import logger

import astropy.units as u
from astropy.constants import m_p, mu0


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
    if isinstance(timerange, TimeRange):
        return [timerange.start.to_string(), timerange.end.to_string()]


def _standardize_plasma_temperature(data: pl.LazyFrame, s_var: SpeasyVariable):
    temperature_col = s_var.columns[0]

    if s_var.unit == "km/s":
        return data.pipe(df_thermal_spd2temp, temperature_col)
    elif s_var.unit == "eV/cm^3":
        return data.pipe(df_p2temp, temperature_col, "plasma_density")
    else:
        return data.rename({temperature_col: "plasma_temperature"})


def standardize_plasma_data(data: pl.LazyFrame, p_vars: Variables, meta: Meta = None):

    density_col = p_vars.data[0].columns[0]
    vec_cols = p_vars.data[1].columns

    data = data.with_columns(plasma_speed=pl_norm(vec_cols)).rename(
        {density_col: "plasma_density"}
    )

    if len(p_vars.data) > 2:
        return data.pipe(_standardize_plasma_temperature, p_vars.data[2])
    else:
        return data

def get_timerange(enc: int) -> list[str]:
    match enc:
        case 2: # Encounter 2
            start = "2019-04-07T01:00"
            end = "2019-04-07T12:00" 

            earth_start = "2019-04-09"
            earth_end = "2019-04-12"
        case 4: # Encounter 4
            start = '2020-01-27'
            end = '2020-01-29'

            earth_start = '2020-01-29'
            earth_end = '2020-01-31'

    psp_timerange = [start, end]
    earth_timerange = [earth_start, earth_end]
    return psp_timerange, earth_timerange


# e_temp = conf.e_temp_var.to_polars().collect()


def standardize_e_temp_df(df: pl.LazyFrame, meta: TempMeta):
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


def standardize_ion_temp_df(df: pl.LazyFrame, meta: TempMeta):
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


class IDsConfig(SpeasyIDsConfig):

    enc: int = 2

    def model_post_init(self, __context):
        super().model_post_init(__context)
        self._data_dir = Path(f"../data/enc{self.enc}")
        # self.data = self.get_vars_df("mag")
        # self.plasma_data = self.get_vars_df("plasma")
        
    @property
    def fname(self):
        return f"events.{self.name}.{self.fmt}"

    @property
    def ion_temp_df(self):
        return self.get_vars_df("ion_temp").pipe(
            standardize_ion_temp_df, self.ion_temp_meta
        )

    @property
    def e_temp_df(self):
        return self.get_vars_df("e_temp").pipe(standardize_e_temp_df, self.e_temp_meta)

    def check_temp(self):
        _vars = [self.e_temp_var, self.ion_temp_var]
        for var in _vars:
            for data in var.data:
                data: SpeasyVariable
                print(data.name, data.columns, data.unit)

    # # TODO
    # def get_and_process_data(self, **kwargs):
    #     mag_vars = self.mag_vars.retrieve_data()
    #     p_vars = self.plasma_vars.retrieve_data()

    #     bcols = mag_vars.data[0].columns
    #     vec_cols = p_vars.data[1].columns

    #     mag_data = self.mag_df.unique("time")

    #     plasma_data = (
    #         p_vars.to_polars().unique("time").pipe(standardize_plasma_data, p_vars)
    #     )

    #     return IDsDataset(
    #         mag_data=mag_data,
    #         plasma_data=plasma_data,
    #         tau=self.tau,
    #         ts=self.ts,
    #         bcols=bcols,
    #         vec_cols=vec_cols,
    #         density_col="plasma_density",
    #         speed_col="plasma_speed",
    #         temperature_col="plasma_temperature",
    #     )


AvailableInstrs = Literal["spi", "spc", "sqtn", "qtn"]

def get_psp_plasma_meta(instr_p: AvailableInstrs, instr_p_den: AvailableInstrs):
    match instr_p:
        case "spi":
            dataset = "PSP_SWP_SPI_SF00_L3_MOM"
            parameters = ["VEL_RTN_SUN", "TEMP", "SUN_DIST"]
        case "spc":
            dataset = "PSP_SWP_SPC_L3I"
            parameters = ["vp_moment_RTN_gd", "wp_moment_gd"]
    
    products = [ f"cda/{dataset}/{p}" for p in parameters]

    match instr_p_den:
        case "sqtn":
            den_product = "cda/PSP_FLD_L3_SQTN_RFS_V1V2/electron_density"
        case "qtn":
            den_product = "cda/PSP_FLD_L3_RFS_LFR_QTN/N_elec"
        case "spc":
            den_product = "cda/PSP_SWP_SPC_L3I/np_moment_gd"
        case "spi":
            den_product = "cda/PSP_SWP_SPI_SF00_L3_MOM/DENS"
    
    products.insert(0, den_product)
    
    return PlasmaMeta(
        products=products,
    )

class PSPConfig(IDsConfig):
    name: str = "PSP"

    mag_meta: Meta = Meta(
        dataset="PSP_FLD_L2_MAG_RTN",
        parameters=["psp_fld_l2_mag_RTN"],
    )
    
    tau: timedelta = timedelta(seconds=16)
    ts: timedelta = timedelta(seconds=1 / 180)
    
    instr_p: AvailableInstrs = "spi"
    instr_p_den: AvailableInstrs = "spi"
    
    def model_post_init(self, __context):
        super().model_post_init(__context)
        self.plasma_meta = get_psp_plasma_meta(self.instr_p, self.instr_p_den)
        
    # @property
    # def fname(self):
        # return f"events.{self.name}.{self.instr_p}_n_{self.instr_p_den}.{self.fmt}"


class WindConfig(WindMeta, IDsConfig):
    pass

class THEMISConfig(IDsConfig):
    name: str = "THM"
    ts: timedelta = timedelta(seconds=1)

    plasma_meta: PlasmaMeta = PlasmaMeta(
        dataset="THB_L2_MOM",
        parameters=[
            "thb_peim_densityQ",
            "thb_peim_velocity_gseQ",
            "thb_peim_ptotQ",
        ],
    )

    mag_meta: Meta = Meta(
        dataset="THB_L2_FGM",
        parameters=["thb_fgl_gse"],
    )

    ion_temp_meta: TempMeta = TempMeta(
        dataset="THB_L2_MOM",
        parameters=[
            "thb_peim_t3_magQ",  # (TprpFA1, TprpFA2, TparFA)
            # "thb_peim_ptens_magQ"
        ],
        para_col="Tz_ion FA MOM ESA-B",
        perp_cols=["Tx_ion FA MOM ESA-B", "Ty_ion FA MOM ESA-B"],
    )

    e_temp_meta: TempMeta = TempMeta(
        dataset="THB_L2_MOM",
        parameters=[
            "thb_peem_t3_magQ",
            # "thb_peem_ptens_magQ",
        ],
        para_col="Tz_elec FA MOM ESA-B",
        perp_cols=["Tx_elec FA MOM ESA-B", "Ty_elec FA MOM ESA-B"],
    )
