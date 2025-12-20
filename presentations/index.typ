#import "@preview/touying:0.6.1": *
#import "@preview/unify:0.7.1": unit
#import themes.university: *

#show: university-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Evolution of solar wind current sheets in the inner heliosphere],
    author: [Zijin Zhang (UCLA)],
    date: datetime.today(),
    institution: [UCLA],
  ),
)
// #show: simple-theme.with(aspect-ratio: "16-9")

#set align(center)

#text(size: 24pt)[
  == Motivation: Evolution of solar wind current sheets

  How does the current sheet change with the radial distance from the Sun?

  Synergistic observations of PSP with ARTEMIS and Wind.

  #pause
  Encounters (7–9) selected for their differing geometric alignments

  #grid(
    columns: (1fr, 1fr, 1fr),
    image("/images/PSP_E7.png"), image("/images/PSP_E8.png"), image("/images/PSP_E9.png"),
  )
]

#text(size: 18pt)[
  == Current sheet thickness $𝛿$, current density $J$, and magnetic field jump $Δ 𝐁$

  #slide(composer: (2fr, 2fr))[
    #set text(18pt)

    #figure(
      image("../figures/event-example.png", width: 105%),
      caption: [examples of current sheets observed by the Parker Solar Probe (PSP; panels a.1–a.3) and ARTEMIS (panels b.1–b.3)],
    )

    #pause
    #set math.frac(style: "skewed")
    #set text(24pt)

    $δ / d_i = (V_n Delta t) / (c / omega_"pi")$, $J / J_A = (frac(d B_l, d t, style: "vertical") frac(1, mu_0 V_n, style: "vertical") )/ (e N V_A)$
  ][
    #pause

    #set text(16pt)
    #figure(
      image("../figures/properties_hist-mva.png"),
      // caption: [Parallel and perpendicular displacements for 1-MeV particles interacting with near-Earth current sheets. Gray lines: individual particle trajectories; Blue line: standard deviation of the ensemble; Black line: a representative trajectory.],
    )
  ]
]

== Scale-dependence and Alfvénicity

#slide(composer: (3fr, 4fr))[

  #show figure.caption: set text(20pt)

  #figure(
    image("../figures/joint_properties-mva_2.png"),
    caption: [Similar inverse correlation: smaller-scale current sheets tend to be more intense.],
  )
][
  #pause

  #show figure.caption: set text(20pt)

  #figure(
    image("../figures/Alfvenicities.png"),
    caption: [ARTEMIS (1AU) show a broader angular spread, $cos θ = (Δ 𝐕 dot Δ 𝐕_A)/(|Δ 𝐕| |Δ 𝐕_A|)$, and larger fractional change in magnetic field magnitude.],
    // caption: [Statistical distributions of parameters used to characterize the Alfvénicity of current sheets: (a) ratio of velocity-jump magnitude to Alfvén velocity-jump magnitude, (b) cosine of the angle between the two vectors, (c) the variation in magnetic field magnitude between the leading and trailing edges of each current sheet; and (d) the maximum variation in magnetic field magnitude observed within each current sheet.],
  )
]

== Alfvénicity, in-plane rotation angle $omega_"in"$ and $B_n$

#slide(composer: (3fr, 4fr))[

  #set text(18pt)

  #figure(
    image("../figures/Q_sonnerup_joint_dist_den_2.png", width: 96%),
    // caption: [Joint distribution of the velocity-jump ratio ($|\Delta 𝐕| / |\Delta 𝐕_A|$) and the cosine of the alignment angle ($\cos \theta$), used in computing the Sonnerup ($Q^{\pm}$) parameter. (b) Joint distribution of cross helicity ($\sigma_c$) and ($Q^{\pm}$). (c) Joint distribution of residual energy ($\sigma_r$) and ($Q^{\pm}$). (d) Joint distribution of temporal duration and ($Q^{\pm}$).],
  )

  $Q^± = ± (1 - (| Delta 𝐕 ∓ Delta 𝐕_A|)/(| Delta 𝐕| + | Delta 𝐕_A|))$
][
  #set text(20pt)

  #figure(
    image("../figures/B_n_ω_-mva-subset=true.png"),
    // caption: [Joint distribution of the velocity-jump ratio ($|\Delta 𝐕| / |\Delta 𝐕_A|$) and the cosine of the alignment angle ($\cos \theta$), used in computing the Sonnerup ($Q^{\pm}$) parameter. (b) Joint distribution of cross helicity ($\sigma_c$) and ($Q^{\pm}$). (c) Joint distribution of residual energy ($\sigma_r$) and ($Q^{\pm}$). (d) Joint distribution of temporal duration and ($Q^{\pm}$).],
    caption: [In-plane rotation angle, $omega_"in"$, evolves significantly. Bimodal $B_N / B$ likely reflect the coexistence of several populations.],
  )
]
