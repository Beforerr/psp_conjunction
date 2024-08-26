from pytplot import options
from pytplot import tplot_restore, tplot_names
from beforerr.project import datadir
from psp.io import get_data_lf

PSP_MAG_TNAME = "psp_fld_l2_mag_RTN_4_Sa_per_Cyc"
PSP_DEN_TNAME = "psp_swp_spi_af00_L3_DENS"
PSP_VEL_TNAME = "psp_swp_spi_af00_L3_VEL_RTN"
PSP_TEMP_TNAME = "Tp_spanib_b"


def set_psp_options(tnames):
    options(PSP_DEN_TNAME, "ytitle", "Ion density")
    options(PSP_VEL_TNAME, "ytitle", "Velocity RTN")
    options(PSP_VEL_TNAME, "legend_names", ["v_R", "v_T", "v_N"])
    options(PSP_TEMP_TNAME, "legend_names", ["Para", "Perp"])
    options(PSP_TEMP_TNAME, "ytitle", "Temperature")

    for tname in tnames:
        options(tname, "thick", 2)


def load_psp_data(enc: int = 7):
    file_name = datadir() / f"psp_e{enc:02}.tplot"
    tplot_restore(str(file_name))
    tnames = tplot_names()
    set_psp_options(tnames)
    return tnames


def get_psp_data(kind):
    match kind:
        case "mag":
            data = get_data_lf(PSP_MAG_TNAME)
        case "den":
            data = get_data_lf(PSP_DEN_TNAME)
        case "vel":
            data = get_data_lf(PSP_VEL_TNAME)
        case "temp":
            data = get_data_lf(PSP_TEMP_TNAME).rename(
                {"0": "ion_temp_para", "1": "ion_temp_perp"}
            )

    return data
