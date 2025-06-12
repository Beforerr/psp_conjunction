module PSP
using Unitful
using SPEDAS
using Speasy: SpeasyProduct
using SPEDAS: DataSet

B = SpeasyProduct("PSP_FLD_L2_MAG_RTN_4_SA_PER_CYC/psp_fld_l2_mag_RTN_4_Sa_per_Cyc")
B_1MIN = SpeasyProduct("PSP_FLD_L2_MAG_RTN_1MIN/psp_fld_l2_mag_RTN_1min")

n_spi = SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/DENS"; labels = ["SPI Proton"])
n_spc = Base.Fix2(*, u"cm^-3") ∘ SpeasyProduct("PSP_SWP_SPC_L3I/np_moment"; labels = ["SPC Proton"])
n_sqtn = SpeasyProduct("PSP_FLD_L3_SQTN_RFS_V1V2/electron_density"; labels = ["SQTN Electron"])
n_rfs = SpeasyProduct("PSP_FLD_L3_RFS_LFR_QTN/N_elec"; labels = ["RFS Electron"])
n = DataSet("Density", [n_spi, n_spc, n_sqtn])
n_spi_sqtn = DataSet("Density", [n_spi, n_sqtn])

V = SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/VEL_RTN_SUN")

pTemp = SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/TEMP"; labels = ["SPI Proton"])
eTemp = SpeasyProduct("PSP_FLD_L3_SQTN_RFS_V1V2/electron_core_temperature"; labels = ["SQTN Electron core"])
T = DataSet("Temperature", [pTemp, eTemp])


end
