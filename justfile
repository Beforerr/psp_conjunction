set allow-duplicate-recipes := true

import 'files/quarto.just'
import 'files/overleaf.just'

default:
    just --list

ensure-env: install-julia-deps clone-overleaf
    pixi install
    pre-commit install --allow-missing-config
    quarto add quarto-journals/agu --no-prompt

install-julia-deps:
    julia --project -e 'using Pkg; Pkg.update();'

install-julia-deps-dev:
    #!/usr/bin/env -S julia --project
    using Pkg;
    Pkg.rm("Discontinuity")
    Discontinuity = PackageSpec(url="https://github.com/Beforerr/Discontinuity.jl");
    Pkg.develop([Discontinuity]);

format:
    just --fmt --unstable

sync-overleaf: tex-render tex-clean

exec-scripts:
    python scripts/data.py

update:
    git add .
    -git commit -am "update"
    git push

download:
    wget -P images/enlil/ http://helioweather.net/missions/psp/per02/anim/tuz-a7b1-d4t05x1-d200t1-donki_den1-psp-x15wifs3z1fo_med_201903-201904.mp4
    wget -P images/enlil/ http://helioweather.net/missions/psp/per02/anim/tuz-a7b1-d4t05x1-d200t1-donki_vel2e1-psp-x15ifs3z1fr_med_201903-201904.mp4
    wget -P images/enlil/ http://helioweather.net/missions/psp/per04/anim/tuz-a7b1-d4t05x1-d200t1-donki_den1-psp-x15wifs3z1fo_med_202001-202002.mp4
