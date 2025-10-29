import AlgebraOfGraphics as AoG
import AlgebraOfGraphics: draw!
import Discontinuity
using SPEDAS: tvec, setmeta, setmeta!, Product
using Statistics
using CairoMakie
using TimeseriesUtilities: times
using SpacePhysicsMakie: tplot, tlines!

export plot_candidate, plot_var_info!, plot_PSP, plot_Wind


include("meta.jl")

import .Labels as 𝑳
import .YLabel as 𝒀

export set_Z_theme!

set_Z_theme!() = begin
    AoG.set_aog_theme!()
    update_theme!(;
        figure_padding = 2,
        fonts = (; regular = AoG.firasans("Regular"), bold = AoG.firasans("Medium")),
        Legend = (; framevisible = false, padding = (0, 0, 0, -15)),
        Axis = (; xlabelfont = :bold, ylabelfont = :bold),
    )
end

const legend_kwargs = (position = :top, titleposition = :left)
const log_axis = (yscale = log10, xscale = log10)

function draw!(grid; axis = NamedTuple(), palettes = NamedTuple())
    return plt -> draw!(grid, plt; axis = axis, palettes = palettes)
end

function plot_var_info!(f, event)
    return tlines!(f, [event.tstart, event.tstop])
end

# ---
# Example plot
function plot_candidate(f, event, ts::AbstractArray, toffset = nothing; kwargs...)
    tmin, tmax = event.t_us, event.t_ds
    tstart, tstop = event.tstart, event.tstop
    toffset = something(toffset, tstop - tstart)
    fax = tplot(f, ts, tmin - toffset, tmax + toffset; kwargs...)
    tlines!(fax, [tmin, tmax])
    tlines!(fax, [tstart, tstop])
    return fax
end

get_data(B::AbstractArray, tmin, tmax) = tview(B, tmin, tmax)
get_data(B::Product, tmin, tmax) = B(tmin, tmax)

function plot_candidate(f, event, B::Union{AbstractArray, Product}, toffset = nothing; add_B_mva = false, add_fit = false, kwargs...)
    tmin, tmax = event.t_us, event.t_ds
    tstart, tstop = event.tstart, event.tstop
    toffset = something(toffset, tstop - tstart)
    B_subset = get_data(B, tmin - toffset, tmax + toffset)
    ts = times(B_subset)
    tvars2plot = Any[tnorm_combine(B_subset)]
    if add_B_mva
        B_mva = mva(B_subset, tview(B_subset, tmin, tmax))
        push!(tvars2plot, B_mva)
    end
    if add_fit
        model = event.model
        Bl_model = DimArray(model.(ts), Ti(ts))
        push!(tvars2plot, Bl_model)
    end

    fax = tplot(f, tvars2plot; kwargs...)
    tlines!(fax, [tmin, tmax])
    tlines!(fax, [tstart, tstop])
    return fax
end

using NaNStatistics

subtract_func(x; dims) = mean.(nanextrema(x; dims))

function plot_candidate(f, event, config::AbstractDict, toffset = Second(0); add_Va = false, add_J = false, add_fit = false, kwargs...)
    tmin, tmax = event.t_us, event.t_ds
    t0 = tmin - toffset
    t1 = tmax + toffset
    B = setmeta(config["B"](t0, t1); ylabel = "(nT)")
    V = setmeta(config["V"](t0, t1); ylabel = "(km/s)")

    B_subset = tview(B, tmin, tmax)
    B_mva = setmeta(mva(B, B_subset); labels = 𝑳.B_LMN)
    V_mva = setmeta(mva(V, B_subset); labels = 𝑳.V_LMN, plottype = :ScatterLines)
    result = (tnorm_combine(B_mva), tsubtract(V_mva))

    if add_Va
        n = config["n"](t0, t1)
        Va = setmeta(Alfven_velocity_ts(B_mva, n) ./ u"km/s"; labels = 𝑳.Va_LMN, ylabel = "(km/s)")
        result = (result..., tsubtract(Va, subtract_func))
    end

    if add_J
        J = hcat(current_density(B_mva, V_mva)...)
        J = setmeta(J; labels = 𝑳.J, ylabel = "J")
        result = (result..., J)
    end

    fax = tplot(f, result; kwargs...)

    if add_fit
        model = event.model
        ts = DateTime.(times(B_subset))
        lines!(fax.axes[1], ts, model.(ts); color = :red, linestyle = :dash, linewidth = 3, label = "fit")
    end

    tlines!(fax, [tmin, tmax]; color = :gray, linestyle = :dash)
    return fax, result
end

# ---
# Overview plot

_plasma_beta(T, n, B_mag) = setmeta(
    Discontinuity.plasma_beta.(tsync(T, n, B_mag)...); label = "β", units = ""
)

_tmean(x::AbstractArray{<:Number}) = isempty(x) ? x : tmean(x, Minute(8))
_tmean(x::AbstractArray) = map(_tmean, x)
_tmean(x::DimStack) = tmean(x, Minute(8))
_tmean(tuple) = map(_tmean, tuple)
# _tmean(x::AbstractArray) = _tmean.(x)

function plot_PSP(f, tmin, tmax, extra_tvars...; kw...)
    B_1MIN = PSP.B_1MIN(tmin, tmax)
    n_p = PSP.n_spi(tmin, tmax)

    B_SC = PSP.B_SC(tmin, tmax)
    V_SC = PSP.V_SC(tmin, tmax)
    _V_SC, _B_SC, _n = tsync(V_SC, B_SC, n_p)
    σs = Discontinuity.cross_helicity_residual_energy(_B_SC', _V_SC', _n, Minute(8))

    V = PSP.V(tmin, tmax)
    Tp = PSP.pTemp(tmin, tmax)
    B_mag = tnorm(B_1MIN)
    β = _plasma_beta(Tp, n_p, B_mag)
    A_He = PSP.A_He(tmin, tmax; n_p)
    # tmean.((T, Tp, Te)
    _extra_tvars = map(extra_tvars) do tv
        tview(tv, tmin, tmax)
    end

    Tp2 = tview(PSP.read_proton_temperature(), tmin, tmax)
    Te2 = tview(PSP.read_electron_temperature(), tmin, tmax)
    Tp = setmeta(Tp, labels = [L"T_p"])

    tvars = map(_tmean, (B_mag, n_p, tnorm(V), [Tp, Tp2.para, Tp2.perp, Te2.para, Te2.perp], _extra_tvars..., σs, A_He, β))
    return tplot(f, tvars; kw...)
end

function plot_Wind(f, tmin, tmax, extra_tvars...; kw...)
    B = Wind.B_GSE(tmin, tmax)
    V = Wind.V_GSE_3DP(tmin, tmax)
    n = Wind.n_p_3DP(tmin, tmax)

    _V, _B, _n = tsync(V, B, n)
    σs = Discontinuity.cross_helicity_residual_energy(_B', _V', _n, Minute(8))
    T = Wind.T_p_PLSP(tmin, tmax)

    B_mag = tnorm(B)
    β = _plasma_beta(T, n, B_mag)
    n2 = Wind.n_p_nonlin(tmin, tmax)
    n_α = Wind.n_α_nonlin(tmin, tmax)
    A_He = n_α ./ n2 .* 100

    Tp2 = Wind.pTemp_T2(tmin, tmax)
    Te2 = Wind.eTemp_T2(tmin, tmax)
    _extra_tvars = map(extra_tvars) do tv
        tview(tv, tmin, tmax)
    end
    V_mag = tnorm(tsort(V))
    V_mag[V_mag .< 200] .= NaN
    tvars = map(_tmean, (B_mag, n, V_mag, [Tp2.para, Tp2.perp, Te2.para, Te2.perp], _extra_tvars..., σs, A_He, β))
    return tplot(f, tvars; kw...)
end

modify_N_ax!(ax, nmin = 50, nmax = 310) = begin
    ylims!(ax, nmin, nmax)
end

modify_β_ax!(ax) = begin
    ax.ylabel[] = "β"
    ax.yscale[] = log10
    ylims!(ax, 8.0e-2, 4.0e1)
end

modify_A_He_ax!(ax) = begin
    ax.yscale[] = identity
    ax.ylabel[] = L"A_{\text{He}} (%)"
    ylims!(ax, 0, 8)
end

function modify_faxs_base!(faxs)
    B_ax = faxs.axes[1]
    B_ax.ylabel[] = 𝒀.B
    n_ax = faxs.axes[2]
    n_ax.yscale[] = identity
    n_ax.ylabel[] = 𝒀.n
    V_ax = faxs.axes[3]
    V_ax.ylabel[] = 𝒀.V

    T_ax = faxs.axes[4]
    T_ax.ylabel[] = "T (eV)"

    modify_A_He_ax!(faxs.axes[end - 1])
    modify_β_ax!(faxs.axes[end])

    R_ax = faxs.axes[5]
    ylims!(R_ax, 0.09, 0.85)

    modify_N_ax!(faxs.axes[6])
    return
end

# function modify_faxs_vl!(faxs)
#     i = 1
#     T_ax = faxs.axes[end-3-i]
#     T_ax.ylabel[] = "T (eV)"

#     R_ax = faxs.axes[end-2-i]
#     ylims!(R_ax, 0.09, 0.85)
# end


function plot_vl_ratio(
        df;
        datalimits = x -> quantile(x, [0.01, 0.99]),
        legend = legend_kwargs,
        fname = "vl_ratio",
        mapping_args = (v_l_ratio_map,),
        mapping_kwargs = (; color = ds_mapping)
    )
    plt = data(df) * mapping(mapping_args...; mapping_kwargs...) * density(datalimits = datalimits)
    draw(plt, legend = legend)
    return easy_save(fname; dir = "$fig_dir/$enc")
end

function plot_dvl(
        df;
        legend = legend_kwargs,
        fname = "dvl",
        mapping_args = (v_Alfven_map, v_ion_map),
        mapping_kwargs = (; color = ds_mapping)
    )
    plt = data(df) * mapping(mapping_args...; mapping_kwargs...)

    limit_axis = (; limits = ((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    draw(plt, axis = axis, legend = legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    map(slopes) do s
        lines!(1 .. 1000, (*) $ s, linestyle = :dash, label = "$s")
    end
    axislegend("slope", position = :ct)

    return easy_save(fname)
end


function plot_dvl(; legend = legend_kwargs)
    fname = "dvl"

    plt = data_layer_a * mapping(v_Alfven_map, v_ion_map)

    limit_axis = (; limits = ((2, 400), (2, 400)))
    axis = merge(log_axis, limit_axis)

    draw(plt, axis = axis, legend = legend)

    slopes = [1.0, 0.7, 0.4, 0.1]
    map(slopes) do s
        lines!(1 .. 1000, (*) $ s, linestyle = :dash, label = "$s")
    end
    axislegend("slope", position = :ct)

    return easy_save(fname)
end

export plot_spectras!

function plot_spectras!(ax, specs...; labels = nothing, step = 10, kw...)
    return map(enumerate(specs)) do (i, spec)
        label = get(labels, i, nothing)
        lines!(ax, freq(spec)[2:step:end], power(spec)[2:step:end]; label = label, kw...)
    end
end
