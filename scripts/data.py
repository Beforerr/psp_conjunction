from psp.config import WindConfig, THEMISConfig, SoloConfig
from psp.config.psp import PSPConfig
from speasy.core.requests_scheduling.request_dispatch import init_cdaweb
from loguru import logger

init_cdaweb()

encs = [7, 8, 9, 11]
configs = [PSPConfig, THEMISConfig, WindConfig, SoloConfig]

for enc in encs:
    for cls in configs:
        try:
            cls(enc=enc).produce_or_load()
        except KeyError as e:
            logger.warning(
                f"Failed to produce {cls.__name__} for enc={enc} due to {e} not found in timerange"
            )
