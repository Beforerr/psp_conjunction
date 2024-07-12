from beforerr.project import datadir
from space_analysis.meta import PlasmaDataset, TempDataset, MagDataset
from discontinuitypy.config import SpeasyIDsConfig

from datetime import timedelta
from typing import Literal

from rich import print

from .utils import standardize_ion_temp_df, standardize_e_temp_df

class IDsConfig(SpeasyIDsConfig):

    enc: int = 2

    def model_post_init(self, __context):
        super().model_post_init(__context)
        self.data_dir = datadir() / f"enc{self.enc}"

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
                data
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
    
    return PlasmaDataset(
        products=products,
    )

class PSPConfig(IDsConfig):
    name: str = "PSP"

    mag_meta: MagDataset = MagDataset(
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

class THEMISConfig(IDsConfig):
    name: str = "THM"
    ts: timedelta = timedelta(seconds=1)

    plasma_meta: PlasmaDataset = PlasmaDataset(
        dataset="THB_L2_MOM",
        parameters=[
            "thb_peim_densityQ",
            "thb_peim_velocity_gseQ",
            "thb_peim_ptotQ",
        ],
    )

    mag_meta: MagDataset = MagDataset(
        dataset="THB_L2_FGM",
        parameters=["thb_fgl_gse"],
    )

    ion_temp_meta: TempDataset = TempDataset(
        dataset="THB_L2_MOM",
        parameters=[
            "thb_peim_t3_magQ",  # (TprpFA1, TprpFA2, TparFA)
            # "thb_peim_ptens_magQ"
        ],
        para_col="Tz_ion FA MOM ESA-B",
        perp_cols=["Tx_ion FA MOM ESA-B", "Ty_ion FA MOM ESA-B"],
    )

    e_temp_meta: TempDataset = TempDataset(
        dataset="THB_L2_MOM",
        parameters=[
            "thb_peem_t3_magQ",
            # "thb_peem_ptens_magQ",
        ],
        para_col="Tz_elec FA MOM ESA-B",
        perp_cols=["Tx_elec FA MOM ESA-B", "Ty_elec FA MOM ESA-B"],
    )
