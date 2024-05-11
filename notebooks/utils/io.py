from pytplot import tplot_restore, tplot_names, get_data, options
import polars as pl

def set_psp_options():
    options('psp_swp_spi_sf00_L3_DENS', 'ytitle', 'Ion density')
    options('psp_swp_spi_af00_L3_VEL_RTN_SUN', 'ytitle', 'Velocity RTN')

    options('Tp_spani_b', 'legend_names', ['Para', 'Perp'])
    options('Tp_spani_b', 'ytitle', "Temperature")  

def load_psp_data(enc: int = 7):
    file_name = f"../data/psp_e{enc:02}.tplot"
    tplot_restore(file_name)
    tnames = tplot_names()
    set_psp_options()
    return tnames

def get_data_lf(name):
    da = get_data(name, xarray=True)
    df = da.to_pandas().reset_index()
    return pl.LazyFrame(df).with_columns(
        pl.col("time").dt.cast_time_unit('us'),
    )
    
