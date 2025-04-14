using PlasmaFormulary
using Discontinuity: anisotropy

function alfven_velocity_ts(B, n)
    n_mean = mean(parent(n))
    mass_number = 1
    return uconvert.(u"km/s", alfven_velocity.(B, n_mean, Ref(mass_number)))
end

function anisotropy_ts(B, n, T3; kw...)
    n_mean = mean(parent(n))
    T3_mean = mean(parent(T3); dims=1)
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

function tmaterialize(p::AbstractProduct, tmin, tmax)
    # @set p(tmin, tmax)
end