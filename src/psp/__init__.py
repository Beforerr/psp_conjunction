from datetime import datetime
from pathlib import Path

td_start_c = "t.d_start"
td_stop_c = "t.d_end"


def get_timerange(enc: int):
    encounter_map = {
        2: {
            "psp": ["2019-04-07T01:00", "2019-04-07T12:00"],
            "earth": ["2019-04-09", "2019-04-12"],
        },
        4: {"psp": ["2020-01-27", "2020-01-29"], "earth": ["2020-01-29", "2020-01-31"]},
        7: {"psp": ["2021-01-14", "2021-01-21"], "earth": ["2021-01-15", "2021-01-23"]},
        8: {
            "psp": ["2021-04-28", "2021-04-30"],
            "solo": ["2021-05-03", "2021-05-06"],
            "earth": ["2021-05-03", "2021-05-06"],  # TODO: Check
        },
        9: {
            "psp": ["2021-08-09", "2021-08-11"],
            "earth": ["2021-08-11", "2021-08-13"],
        },
        11: {
            "psp": ["2022-02-25", "2022-02-27"],  # TODO: Check
        },
    }

    if enc not in encounter_map:
        raise ValueError("Invalid encounter")

    timerange = encounter_map[enc]

    # Convert string times to datetime objects
    for key, times in timerange.items():
        timerange[key] = [datetime.fromisoformat(t) for t in times]

    return timerange

def datadir():
    return Path(__file__).parents[2] / "data"
