using PlasmaFormulary
using Discontinuity: anisotropy
using DataFramesMeta

function alfven_velocity_ts(B, n)
    n_mean = mean(parent(n))
    return alfven_velocity.(B, n_mean)
end

function anisotropy_ts(B, n, T3; kw...)
    n_mean = mean(parent(n))
    T3_mean = mean(parent(T3); dims = 1)
    return anisotropy.(eachrow(B), n_mean, Ref(T3_mean); kw...)
end

function alfven_velocity_ani_ts(B, n, T3; kw...)
    Va = alfven_velocity_ts(B, n)
    Λ = anisotropy_ts(B, n, T3; kw...)
    return @. Va * sqrt(1 - Λ)
end

for f in (:alfven_velocity_ts, :anisotropy_ts, :alfven_velocity_ani_ts)
    @eval $f(args::Tuple, tmin, tmax) = $f(map(p -> p(tmin, tmax), args)...)
end


DEFAULT_B_UNIT = u"nT"
DEFAULT_DENSITY_UNIT = u"cm^-3"
DEFAULT_TEMP_UNIT = u"eV"

"""
Calculate the pressure anisotropy
"""
function calc_pressure_anisotropy!(
        df;
        B = "B.mean",
        density = "n.mean",
        ion_temp_para = "ion_temp_para",
        ion_temp_perp = "ion_temp_perp",
        e_temp_para = "e_temp_para",
        e_temp_perp = "e_temp_perp",
        B_unit = DEFAULT_B_UNIT,
        density_unit = DEFAULT_DENSITY_UNIT,
        temp_unit = DEFAULT_TEMP_UNIT,
    )

    B = df[:, B] .* B_unit
    n = df[:, density] .* density_unit

    if ion_temp_para in names(df) && ion_temp_perp in names(df)
        ion_temp_para_u = df[:, ion_temp_para] .* temp_unit
        ion_temp_perp_u = df[:, ion_temp_perp] .* temp_unit
        df[:, :Λ_ion] = anisotropy(B, n, ion_temp_para_u, ion_temp_perp_u)
    else
        @info "Ion temperature columns not found"
    end

    if e_temp_para in names(df) && e_temp_perp in names(df)
        e_temp_para_u = df[:, e_temp_para] .* temp_unit
        e_temp_perp_u = df[:, e_temp_perp] .* temp_unit
        df[:, :Λ_e] = anisotropy(B, n, e_temp_para_u, e_temp_perp_u)
    else
        @info "Electron temperature columns not found"
    end

    if "Λ_ion" in names(df) && "Λ_e" in names(df)
        df[:, :Λ] = df[:, :Λ_ion] .+ df[:, :Λ_e]
    end

    return df
end

function calc_vl_ratio!(df)
    if "Λ_ion" in names(df)
        @chain df begin
            @transform!(
                :"v.Alfven.change.l.fit.Λ_ion" =
                    @. ifelse(:Λ_ion > 1, missing, sqrt(max(0, 1 - :Λ_ion)) * :"v.Alfven.change.l.fit")
            )
            @transform!(
                :"v_l_ratio.fit.Λ_ion" = :"v.ion.change.l" ./ :"v.Alfven.change.l.fit.Λ_ion"
            )
        end
    end

    return df
end
