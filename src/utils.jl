using Dates

# select the time range of interest "2021-04-29T00:45" to "2021-04-29T01:15"
function subset_timerange(df, start)
    return subset(df, :time => t -> t .> DateTime(start))
end

function subset_timerange(df, start, stop)
    return subset(
        subset_timerange(df, start),
        :time => t -> t .< DateTime(stop)
    )
end

subset_timerange(df, timerange::Tuple) = subset_timerange(df, timerange...)

import SPEDAS: Event

SPEDAS.Event(df::DataFrame) = (i = rand(1:size(df, 1)); @info i; Event(df, i))
SPEDAS.Event(df::DataFrame, i) = Event(df.tstart[i], df.tstop[i], Dict(:t_us_ds => df.t_us_ds[i]))
(P::AbstractProduct)(e::Event) = P(e.start, e.stop)
t_us_ds(e::Event) = e.metadata[:t_us_ds]