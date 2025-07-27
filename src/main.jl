using DrWatson
@quickactivate
using AlgebraOfGraphics,
    CairoMakie
using DataFrames, DataFramesMeta
using AlgebraOfGraphics: density
using PartialFunctions
using LaTeXStrings
using Beforerr
using Discontinuity


include("plot.jl")
include("utils.jl")

set_aog_theme!()

dn_over_n = ("n.change", "n.mean") => (/) => L"\Delta n/n"
dB_over_B = ("B.change", "b_mag") => (/) => L"\Delta B/B"
dT_over_T = ("T.change", "T.mean") => (/) => L"\Delta T/T"

fig_dir = projectdir("figures")

datalimits_f = x -> quantile(x, [0.02, 0.98])

M = var_mapping()
