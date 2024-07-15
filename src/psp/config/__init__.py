from pydantic import BaseModel
from beforerr.project import datadir
from discontinuitypy.config import SpeasyIDsConfig
from discontinuitypy.mission import WindConfigBase, ThemisConfigBase

from datetime import timedelta

from rich import print

from ..utils import standardize_ion_temp_df, standardize_e_temp_df
from .. import get_timerange


class Config(BaseModel):
    enc: int = 7
    tau: timedelta = timedelta(seconds=30)

    def model_post_init(self, __context):
        super().model_post_init(__context)
        self.timerange = get_timerange(self.enc)[1]
        self.file_path = datadir() / f"enc{self.enc}"


class WindConfig(Config, WindConfigBase, SpeasyIDsConfig):
    def model_post_init(self, __context):
        super().model_post_init(__context)
        self.ts = self.ts or self.mag_meta.ts


class THEMISConfig(Config, ThemisConfigBase, SpeasyIDsConfig):
    ts: timedelta = timedelta(seconds=1)


class IDsConfig(Config, SpeasyIDsConfig):
    @property
    def ion_temp_df(self):
        return self.get_vars_df("ion_temp").pipe(
            standardize_ion_temp_df, self.ion_temp_meta
        )

    @property
    def e_temp_df(self):
        return self.get_vars_df("e_temp").pipe(standardize_e_temp_df, self.e_temp_meta)
