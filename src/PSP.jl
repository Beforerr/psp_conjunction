module PSP
using Unitful
using SPEDAS
using Speasy: SpeasyProduct
using SPEDAS: DataSet, ulabel


B = SpeasyProduct("PSP_FLD_L2_MAG_RTN_4_SA_PER_CYC/psp_fld_l2_mag_RTN_4_Sa_per_Cyc")
n = DataSet("Density",
    [
        SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/DENS"; labels=["SPI Proton"]),
        Base.Fix2(*, u"cm^-3") ∘ SpeasyProduct("PSP_SWP_SPC_L3I/np_moment"; labels=["SPC Proton"]),
        SpeasyProduct("PSP_FLD_L3_RFS_LFR_QTN/N_elec"; labels=["RFS Electron"]),
        SpeasyProduct("PSP_FLD_L3_SQTN_RFS_V1V2/electron_density"; labels=["SQTN Electron"])
    ]
)

V = SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/VEL_RTN_SUN")

T = DataSet("Temperature",
    [
        SpeasyProduct("PSP_SWP_SPI_SF00_L3_MOM/TEMP"; labels=["SPI Proton"]),
        smooth(30u"s") ∘ SpeasyProduct("PSP_FLD_L3_SQTN_RFS_V1V2/electron_core_temperature"; labels=["SQTN Electron core"]),
    ]
)


end
