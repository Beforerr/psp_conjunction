# %%
from psp.config import WindConfig, THEMISConfig, SoloConfig
from psp.config.psp import PSPConfig
from speasy.core.requests_scheduling.request_dispatch import init_cdaweb
from loguru import logger
from psp.io.psp import load_psp_data
from psp.io import save_tnames

# %%
init_cdaweb()

encs = [7, 8, 9, 11]
configs = [PSPConfig, THEMISConfig, WindConfig, SoloConfig]

# %%
for enc in encs:
    for cls in configs:
        try:
            cls(enc=enc).produce_or_load()
        except KeyError as e:
            logger.warning(
                f"Failed to produce {cls.__name__} for enc={enc} due to {e} not found in timerange"
            )

# %%
for enc in encs:
    # convert .tplot file to hdf5
    tnames = load_psp_data(enc)
    save_tnames(["Tp_spani_b", "Tp_spanib_b"], f"../data/psp_e{enc:02}")

# %%
