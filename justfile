set allow-duplicate-recipes := true

import 'files/quarto.just'
import 'files/overleaf.just'

default:
    just --list

ensure-env: install-deps clone-overleaf
    pre-commit install --allow-missing-config
    quarto add quarto-journals/agu --no-prompt

install-deps: 
    pixi install --frozen
    julia --project -e 'using Pkg; Pkg.develop([(;name="Beforerr"), (;name="Speasy"), (;name="SpaceTools"), (;name="PlasmaFormulary"), (;name="Discontinuity")]); Pkg.update();'

format:
    just --fmt --unstable

render:
    quarto render presentations/index.qmd --to pptx

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
