import AlgebraOfGraphics: draw!
import Discontinuity
using SPEDAS: tvec, set_meta, set_meta!
using Statistics

include("anisotry.jl")

export plot_candidate, plot_var_info!, plot_PSP, plot_Wind

import .Labels as 𝑳


# %%
legend_kwargs = (position=:top, titleposition=:left)

begin
    enc_m = :enc => x -> "Enc $x"
end

log_axis = (yscale=log10, xscale=log10)

function draw!(grid; axis=NamedTuple(), palettes=NamedTuple())
    return plt -> draw!(grid, plt; axis=axis, palettes=palettes)
end

function plot_var_info!(f, event)
    tlines!(f, [event.tstart, event.tstop])
end

# ---
# Example plot
function plot_candidate(f, event, config, toffset=Second(0); add_J=false, kwargs...)
    tmin, tmax = event.t_us, event.t_ds
    t0 = tmin - toffset
    t1 = tmax + toffset

    B_product = config["B"]
    V_product = config["V"]

    B = B_product(t0, t1) |> set_meta!(; ylabel="B", labels=𝑳.B_RTN)
    V = V_product(t0, t1) |> set_meta!(; ylabel="V", labels=𝑳.V_RTN)
    n = config["n"](t0, t1)

    B_subset = tview(B, tmin, tmax)

    B_mva = mva(B, B_subset) |> set_meta(; labels=𝑳.B_LMN)
    Va = Alfven_velocity_ts(B_mva, n) .|> u"km/s" |> set_meta(; labels=𝑳.Va_LMN, ylabel="V")
    V_mva = mva(V, B_subset) |> set_meta(; labels=𝑳.V_LMN)

    result = [tnorm_combine(B_mva), tsubtract(V_mva), tsubtract(Va)]

    if add_J
        J = hcat(current_density(B_mva, V_mva)...) |> set_meta(; labels=𝑳.J, ylabel="J")
        push!(result, J)
    end

    fax = tplot(f, result; kwargs...)
    tlines!(fax, [tmin, tmax])
    fax, result
end

# ---
# Overview plot

_plasma_beta(T, n, B_mag) = set_meta(
    Discontinuity.plasma_beta.(tsync(T, n, B_mag)...); label="β", units=""
)

function plot_PSP(f, tmin, tmax, extra_tvars...; kw...)
    B = set_meta!(PSP.B_1MIN(tmin, tmax); labels=𝑳.B_RTN)
    V = PSP.V(tmin, tmax)
    n_p = PSP.n_spi(tmin, tmax) |> tvec
    n_α = PSP.n_alpha(tmin, tmax) |> tvec
    T = PSP.pTemp(tmin, tmax; add_unit=false) |> tvec

    A_He = set_meta(n_α ./ n_p .* 100; ylabel="A_He", scale=identity)

    B_mag = tnorm(B)
    β = _plasma_beta(T, n_p, B_mag)

    T = set_meta!(T; labels=[L"T_p"])

    # tmean.((T, Tp, Te)
    tvars = (B_mag, n_p, tnorm(V), tmean(T, Minute(8)), β, A_He, extra_tvars...)
    faxs = tplot(f, tvars, tmin, tmax; kw...)
end

function plot_Wind(f, tmin, tmax, extra_tvars...; kw...)
    B = Wind.B_GSE_1MIN(tmin, tmax)
    V = Wind.V_GSE_K0(tmin, tmax)
    n = Wind.n_p_nonlin(tmin, tmax) |> tsort
    n_α = Wind.n_α_nonlin(tmin, tmax) |> tsort
    A_He = set_meta(n_α ./ n .* 100; ylabel="A_He", scale=identity)

    T = set_meta(Wind.T_p_PLSP(tmin, tmax; add_unit=false) |> tsort; labels=[L"T_p"])
    B_mag = tnorm(B)
    β = _plasma_beta(T, n, B_mag)

    # [T, Wind_Tp2, Wind_Te2]
    tvars = (B_mag, n, tnorm(tsort(V)), T, β, A_He, extra_tvars...)
    faxs = tplot(f, tvars, tmin, tmax; kw...)
end


function plot_vl_ratio(
    df;
    datalimits=x -> quantile(x, [0.01, 0.99]),
    legend=legend_kwargs,
    fname="vl_ratio",
    mapping_args=(v_l_ratio_map,),
    mapping_kwargs=(; color=ds_mapping)
)
    plt = data(df) * mapping(mapping_args...; mapping_kwargs...) * density(datalimits=datalimits)
    draw(plt, legend=legend)
    return easy_save(fname; dir="$fig_dir/$enc")
end

function plot_dvl(
    df;
    legend=legend_kwargs,
    fname="dvl",
    mapping_args=(v_Alfven_map, v_ion_map),
    mapping_kwargs=(; color=ds_mapping)
)
    plt = data(df) * mapping(mapping_args...; mapping_kwargs...)

    limit_axis = (; limits=((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    draw(plt, axis=axis, legend=legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    map(slopes) do s
        lines!(1 .. 1000, (*)$s, linestyle=:dash, label="$s")
    end
    axislegend("slope", position=:ct)

    return easy_save(fname)
end


function plot_dvl(; legend=legend_kwargs)
    fname = "dvl"

    plt = data_layer_a * mapping(v_Alfven_map, v_ion_map)

    limit_axis = (; limits=((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    draw(plt, axis=axis, legend=legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    map(slopes) do s
        lines!(1 .. 1000, (*)$s, linestyle=:dash, label="$s")
    end
    axislegend("slope", position=:ct)

    return easy_save(fname)
end
