using DrWatson
@quickactivate
using AlgebraOfGraphics,
    CairoMakie
using DataFrames, DataFramesMeta
using AlgebraOfGraphics: density
using Arrow
using PartialFunctions
using LaTeXStrings
using Beforerr
using Discontinuity

include("io.jl")
include("plot.jl")

set_aog_theme!()


dn_over_n = ("n.change", "n.mean") => (/) => L"\Delta n/n"
dB_over_B = ("B.change", "b_mag") => (/) => L"\Delta B/B"
dT_over_T = ("T.change", "T.mean") => (/) => L"\Delta T/T"

fig_dir = projectdir("figures")