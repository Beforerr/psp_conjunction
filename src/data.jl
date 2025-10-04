using CDAWeb
using DimensionalData
using DimensionalData: TimeDim, Ti

struct CDADimArray{N}
    dataset::String
    variable::String
    kwargs::N
end

CDADimArray(dataset, variable; kw...) = CDADimArray(dataset, variable, (; kw...))

function (cdadim::CDADimArray)(tmin, tmax; kw...)
    A = DimArray(CDAWeb.get_data(cdadim.dataset, cdadim.variable, tmin, tmax; cdadim.kwargs..., kw...); replace_invalid = true)
    dim = dims(A, TimeDim)
    T = eltype(dim)
    A_sorted = tsort(A)
    return @view A_sorted[Ti(T(tmin) .. T(tmax))]
end

function (cdadim::CDADimArray)(trange; kw...)
    return cdadim(trange[1], trange[2]; kw...)
end
