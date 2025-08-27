#
#
#
#
timeranges = get_timerange(7)
tmin, tmax = timeranges[1]
taus = Second.(2 .^ (1:6))
#
#
#
timeranges = get_timerange(7)
tmin, tmax = timeranges[1]
tmax = tmin + Day(1)
tau = taus[6]
df = ids_finder(tmin, tmax, PSP.B_SC; tau)
# df= produce(psp_conf, taus, timeranges[1])
```
#
#
#
#
#
    # B = PSP.B_SC(tmin, tmax) |> DimArray

time_interval = (DateTime("2021-01-14T11:41:42.440"), DateTime("2021-01-14T11:41:43.430"))
time_interval = (DateTime("2021-01-15T07:27:39.754"), DateTime("2021-01-15T07:28:22.667"))
time_interval = (DateTime("2021-01-14T09:34:44.300"), DateTime("2021-01-14T09:34:51.994"))
time_interval = (DateTime("2021-01-15T12:37:14.741"), DateTime("2021-01-15T12:37:18.008"))
time_interval = (DateTime("2021-01-15T17:19:52.777"), DateTime("2021-01-15T17:19:58.521"))
B_p = DimArray ∘ PSP.B_SC
B_mva_prod = Product(B_p, mva_transform)
tplot([tnorm_combine ∘ B_p, B_mva_prod], time_interval...)
#
#
#
#
#
using Random

f = Figure(size=(1800, 1000))

rows = rand(eachrow(df), min(5, nrow(df)))
for (plot_idx, i) in enumerate(rows)
    plot_candidate(f[1, plot_idx], i, B_p; add_B_mva=true, add_fit=true)
end
f
#
#
#
