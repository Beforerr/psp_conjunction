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