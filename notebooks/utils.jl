import AlgebraOfGraphics: draw!

function easy_save(name, dir="$fig_dir/$enc")
    path = "$dir/$name"

    save("$path.png", fig, px_per_unit=4)
    save("$path.pdf", fig)
end
function pretty_legend!(fig, grid)
    legend!(fig[1, 1:2], grid, titleposition=:left, orientation=:horizontal)
end

log_axis = (yscale=log10, xscale=log10)

function draw!(grid; axis=NamedTuple(), palettes=NamedTuple())
    plt -> draw!(grid, plt; axis=axis, palettes=palettes)
end