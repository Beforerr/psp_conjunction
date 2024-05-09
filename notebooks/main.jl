using AlgebraOfGraphics,
    CairoMakie
using AlgebraOfGraphics: density
using DataFrames,
    DataFramesMeta,
    CategoricalArrays
using Arrow
using PartialFunctions
using LaTeXStrings
using beforerr

include("utils/io.jl")
include("utils/plot.jl")

set_aog_theme!()
