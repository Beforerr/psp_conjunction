import polars as pl
import astropy.units as u
from astropy.constants import mu0

td_start_c = "t.d_start"
td_stop_c = "t.d_end"

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
        
        case 7:
            start = '2021-01-14'
            end = '2021-01-21'

            earth_start = '2021-01-15'
            earth_end = '2021-01-23'

    psp_timerange = [start, end]
    earth_timerange = [earth_start, earth_end]
    return psp_timerange, earth_timerange
