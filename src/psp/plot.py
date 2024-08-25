from psp.io import time_stamp
from datetime import timedelta
import pytplot
from pytplot import tplot

from discontinuitypy.naming import start_col, end_col
from discontinuitypy.plot import tplot_Alvenicity

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

def plot_candidate_tplot(
    event,
    mag_tname: str = PSP_MAG_TNAME,
    vec_tname: str = PSP_VEL_TNAME,
    den_tname: str = PSP_DEN_TNAME,
    offset=timedelta(seconds=0),
):
    """Plot the candidate event with velocity profiles"""

    start = event[start_col]
    end = event[end_col]
    
    return tplot_Alvenicity(start, end, mag_tname, vec_tname, den_tname, offset)
