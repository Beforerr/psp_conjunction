from psp.io import time_stamp
from datetime import timedelta
import pytplot
from pytplot import tplot

from discontinuitypy.utils.plot import ts_mva
from discontinuitypy.naming import start_col, end_col
from space_analysis.ds.tplot.formulary import ts_Alfven_speed
from space_analysis.ds.ts.plot import tsplot
from xarray import DataArray

from psp.io.psp import PSP_MAG_TNAME, PSP_DEN_TNAME, PSP_VEL_TNAME, PSP_TEMP_TNAME

psp_tnames2plot = [
    PSP_MAG_TNAME,
    PSP_DEN_TNAME,
    PSP_VEL_TNAME,
    PSP_TEMP_TNAME,
]


def tlimit(arg, **kwargs):
    if isinstance(arg, list):
        arg = [time_stamp(t) for t in arg]
    pytplot.tlimit(arg, **kwargs)


def timebar(time, **kwargs):
    pytplot.timebar(time_stamp(time), **kwargs)


def tslice(tname, start, end, newname=None, suffix="_tslice"):
    da = pytplot.data_quants[tname].sel(time=slice(start, end))
    name = newname or tname + suffix
    pytplot.store_data(name, data={"x": da.time, "y": da.values})
    return name


def plot_event(
    event,
    tnames2plot=psp_tnames2plot,
    td_stop_c="t.d_end",
    add_timebars=True,
    offset=timedelta(seconds=60),
):
    tstart = event["tstart"] - offset
    tstop = event["tstop"] + offset
    td_start = event["t.d_start"]
    td_stop = event[td_stop_c]

    tlimit([tstart, tstop])

    if add_timebars:
        timebar(td_start)
        timebar(td_stop)

    return tplot(tnames2plot, return_plot_objects=True)

def set_mva_ts_option(
    da: DataArray,
    type="B",
):
    options_dict = {
        "B": {
            "title": "$B$",
            "units": "nT",
            "subtitle": "[nT LMN]",
            "legend_names": [r"$B_l$", r"$B_m$", r"$B_n$", r"$B_{total}$"],
        },
        "V": {
            "title": "$V$",
            "subtitle": "[km/s LMN]",
            "units": "km/s",
            "legend_names": [r"$V_l$", r"$V_m$", r"$V_n$", r"$V_{total}$"],
        },
    }

    da.attrs["long_name"] = options_dict[type]["title"]
    da.attrs["units"] = options_dict[type]["units"]
    if "v_dim" in da.dims:
        da["v_dim"] = options_dict[type]["legend_names"]
    return da


def plot_candidate_tplot(
    event,
    mag_tname: str = PSP_MAG_TNAME,
    vec_tname: str = PSP_VEL_TNAME,
    den_tname: str = PSP_DEN_TNAME,
    offset=timedelta(seconds=0),
):
    """Plot the candidate event with velocity profiles"""

    tstart = event[start_col]
    tend = event[end_col]
    trange = slice(tstart - offset, tend + offset)

    mag_da = pytplot.data_quants[mag_tname].sel(time=trange)
    vec_da = pytplot.data_quants[vec_tname].sel(time=trange)
    den_da = pytplot.data_quants[den_tname].sel(time=trange)

    mva_kwargs = dict(mva_data=mag_da, mva_tstart=tstart, mva_tstop=tend)
    mag_mva_da = ts_mva(mag_da, **mva_kwargs)
    vec_mva_da = ts_mva(vec_da, **mva_kwargs)

    Bl_da = mag_mva_da.isel(v_dim=0)
    Alfven_l_da = ts_Alfven_speed(Bl_da, den_da)

    Vl_da = vec_mva_da.isel(v_dim=0).interp_like(Alfven_l_da)
    dVl_da = Vl_da - Vl_da.isel(time=abs(Alfven_l_da).argmin("time"))

    mag_mva_da = set_mva_ts_option(mag_mva_da, type="B")
    vec_mva_da = set_mva_ts_option(vec_mva_da, type="V")
    Alfven_l_da.attrs["long_name"] = r"$V_{A,l}$"
    dVl_da.attrs["long_name"] = r"$dV_{i,l}$"
    
    layout = tsplot([mag_mva_da, vec_mva_da, [Alfven_l_da, dVl_da], den_da])
    layout[2].opts(ylabel=r"$V_l$ (km/s)")
    return layout
