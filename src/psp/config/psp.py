from datetime import timedelta
from space_analysis.missions.psp import psp_fld_l2_mag_rtn, psp_swp_spi_sf00_l3_mom
from space_analysis.meta import MagDataset, PlasmaDataset
from . import IDsConfig
from .. import get_timerange

from psp.io.psp import load_psp_data, get_psp_data
import numpy as np

from typing import Literal

TPLOT_ENCS = [7, 8, 11]
AvailableInstrs = Literal["spi", "spc", "sqtn", "qtn"]


def remove(list: list, item):
    temp_list = list.copy()
    temp_list.remove(item)
    return temp_list


def get_psp_plasma_meta(instr_p: AvailableInstrs, instr_p_den: AvailableInstrs):
    match instr_p:
        case "spi":
            dataset = psp_swp_spi_sf00_l3_mom.dataset
            parameters = psp_swp_spi_sf00_l3_mom.parameters[1:]
        case "spc":
            dataset = "PSP_SWP_SPC_L3I"
            parameters = ["vp_moment_RTN_gd", "wp_moment_gd"]

    products = [f"cda/{dataset}/{p}" for p in parameters]

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

    return PlasmaDataset(
        products=products,
    )


class PSPConfig(IDsConfig):
    name: str = "PSP"

    tau: timedelta = timedelta(seconds=16)
    ts: timedelta = timedelta(seconds=1 / 180)  # TODO: improve this

    instr_p: AvailableInstrs = "spi"
    instr_p_den: AvailableInstrs = "spi"

    def model_post_init(self, __context):
        super().model_post_init(__context)

        self.timerange = get_timerange(self.enc)["psp"]

        if self.enc not in TPLOT_ENCS:
            self.plasma_meta = get_psp_plasma_meta(self.instr_p, self.instr_p_den)
            self.mag_meta = psp_fld_l2_mag_rtn
            self.ts: timedelta = timedelta(seconds=1 / 180)  # TODO: improve this
        else:
            load_psp_data(enc=self.enc)

            density_col = "n"
            velocity_cols = ["v_R", "v_T", "v_N"]

            mag_data = get_psp_data("mag").collect()
            density_data = get_psp_data("den").rename({"0": density_col})
            velocity_data = get_psp_data("vel").rename(
                dict(zip(["0", "1", "2"], velocity_cols))
            )
            ion_temp_data = get_psp_data("temp")

            time = mag_data.get_column("time").to_numpy()
            self.ts = timedelta(
                microseconds=np.median(np.diff(time)).item() / 1000
            )  # Related: https://github.com/python/cpython/issues/59648

            self.data = mag_data
            self.plasma_data = density_data.join(velocity_data, on="time")
            self.ion_temp_data = ion_temp_data

            self.plasma_meta = PlasmaDataset(
                density_col=density_col,
                velocity_cols=velocity_cols,
            )
            self.mag_meta = MagDataset(B_cols=remove(mag_data.columns, "time"))
