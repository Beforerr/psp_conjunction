using PartialFunctions

mva_transform((V, B), tmin, tmax; tb_min=tmin, tb_max=tmax) = mva(V(tmin, tmax), B(tb_min, tb_max))


function make_mva_product(event, V, B=V; kwargs...)
    tb_min, tb_max = t_us_ds(event)
    return Product((V, B), mva_transform$(; tb_min, tb_max); kwargs...)
end

function make_mva_products(event, B, V, n=nothing, T3=nothing)
    B_mva = make_mva_product(event, B, B; labels=B_mva_labels, ylabel=𝒀.B)
    V_mva = make_mva_product(event, V, B; labels=V_mva_labels, ylabel=𝒀.V)
    J = Product((V_mva, B_mva), j_transform)
    result = [tnorm_combine ∘ B, V, tnorm_combine ∘ B_mva, set(tsubtract ∘ V_mva; ylabel=𝒀.ΔV), J]
    isnothing(n) || push!(result, set(
        tsubtract ∘ Product((B_mva, n), alfven_velocity_ts);
        ylabel=𝒀.ΔV, labels=["Va_L", "Va_M", "Va_N"]
    ))
    isnothing(T3) || begin
        Λ = Product((B_mva, n, T3), anisotropy_ts; ylabel="Λ")
        Va_Λ = set(
            tsubtract ∘ Product((B_mva, n, T3), alfven_velocity_ani_ts);
            ylabel=𝒀.ΔV, labels=["Va*_L", "Va*_M", "Va*_N"]
        )
        push!(result, Λ, Va_Λ)
    end
    return result
end