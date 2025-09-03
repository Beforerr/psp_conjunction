
using Associations

export analyze_associations

# Association calculation function (much faster than independence tests)
function calculate_associations(x, y)
    # Remove missing values
    valid_idx = .!ismissing.(x) .& .!ismissing.(y) .& .!isnan.(x) .& .!isnan.(y)
    x_clean = x[valid_idx] .|> Float64
    y_clean = y[valid_idx] .|> Float64

    if length(x_clean) < 10
        return [(measure_name="Insufficient data", association=NaN, n=length(x_clean))]
    end

    # Multiple association measures
    measures = [
        # ("Distance Correlation", DistanceCorrelation()),
        ("Pearson Correlation", PearsonCorrelation()),
        ("Chatterjee Correlation", AzadkiaChatterjeeCoefficient()),
        ("Mutual Information", KSG1(MIShannon()))
    ]

    results = []
    for (name, measure) in measures
        try
            assoc_value = association(measure, x_clean, y_clean)
            push!(results, (
                measure_name=name,
                association=assoc_value,
                n=length(x_clean)
            ))
        catch e
            @warn "Failed to calculate association for $(name): $(e)"
            # Some measures might fail with certain data
            push!(results, (
                measure_name=name,
                association=NaN,
                n=length(x_clean)
            ))
        end
    end

    return results
end

function parse_column(df, col_spec::Pair)
    col, transform_func = col_spec.first, col_spec.second
    return transform_func.(df[!, col])
end

parse_column(df, col_spec) = df[!, col_spec]

"""
Analyze associations between variable pairs, optionally grouped by a column.

Args:
    data: DataFrame to analyze
    variable_pairs: Vector of tuples with flexible syntax:
        - (col1, col2, "Description")
        - (col1, col2 => transform_func, "Description") 
        - (col1 => transform_func, col2, "Description")
        - (col1 => transform_func, col2 => transform_func, "Description")
    group_by: Column name to group by (e.g., :id for missions), or nothing
    io: IOStream to write results to (default: stdout)
"""
function analyze_associations(data, variable_pairs; group_by=nothing, io = stdout)
    # Overall analysis (if not grouping)
    if group_by === nothing
        for (i, pair) in enumerate(variable_pairs)
            col1_spec, col2_spec = pair[1], pair[2]
            desc = length(pair) > 2 ? pair[3] : "$(col1_spec) vs $(col2_spec)"

            println(io, "\n$(i). $(uppercase(desc))")
            x = parse_column(data, col1_spec)
            y = parse_column(data, col2_spec)

            assoc_results = calculate_associations(x, y)
            for result in assoc_results
                if !isnan(result.association)
                    println(io, "  $(result.measure_name): $(round(result.association, digits=4)) (n = $(result.n))")
                end
            end
        end
    else

        for group_value in unique(data[!, group_by])
            group_data = filter(row -> row[group_by] == group_value, data)
            println(io, "\n$(group_value) (n = $(nrow(group_data))):")
            analyze_associations(group_data, variable_pairs; group_by=nothing, io=io)
        end
    end
end