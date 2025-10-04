using Discontinuity: compute_anisotropy_params!
export compute_PSP_anisotropy_params!, compute_Wind_anisotropy_params!, compute_THM_anisotropy_params!

function add_temp_anisotropy!(df, Tp_para, Tp_perp, Te_para, Te_perp, dt = Minute(1))
    return @rtransform! df begin
        :Tp_para = tselect(Tp_para, :time, dt)
        :Tp_perp = tselect(Tp_perp, :time, dt)
        :Te_para = tselect(Te_para, :time, dt)
        :Te_perp = tselect(Te_perp, :time, dt)
    end
end

add_temp_anisotropy!(df, Tp, Te, args...) =
    add_temp_anisotropy!(df, Tp.para, Tp.perp, Te.para, Te.perp, args...)


function compute_PSP_anisotropy_params!(psp_df)
    Tp = PSP.read_proton_temperature(7:8)
    Te = PSP.read_electron_temperature(; dir = datadir("electron_fit_Halekas"))
    add_temp_anisotropy!(psp_df, Tp, Te)
    return compute_anisotropy_params!(psp_df, :ion => (:Tp_para, :Tp_perp), :electron => (:Te_para, :Te_perp))
end

function compute_Wind_anisotropy_params!(df, tmin, tmax)
    Wind_Tp2 = Wind.pTemp_T2(tmin, tmax)
    Wind_Te2 = Wind.eTemp_T2(tmin, tmax)
    add_temp_anisotropy!(df, Wind_Tp2, Wind_Te2, Minute(2))
    return compute_anisotropy_params!(df, :ion => (:Tp_para, :Tp_perp), :electron => (:Te_para, :Te_perp))
end

# ignore proton temperature anisotropy as it is not reliable
function compute_THM_anisotropy_params!(df, tmin, tmax; dt = Second(10))
    Te2 = THEMIS.eTemp_T2(tmin, tmax)
    @rtransform! df begin
        :Te_para = tselect(Te2.para, :time, dt)
        :Te_perp = tselect(Te2.perp, :time, dt)
    end
    return compute_anisotropy_params!(df, :electron => (:Te_para, :Te_perp))
end
