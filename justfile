env-install:
   micromamba env create --file environment.yml

env-update:
   micromamba install --file environment.yml

preview:
   quarto preview --no-render

publish: update render
   quarto publish gh-pages --no-render --no-prompt

render:
   quarto render --profile man
   quarto render
   cp -r _manuscript _site/

update:
   git add .
   -git commit -am "update"
   git push

download:
   wget -P images/enlil/ http://helioweather.net/missions/psp/per02/anim/tuz-a7b1-d4t05x1-d200t1-donki_den1-psp-x15wifs3z1fo_med_201903-201904.mp4
   wget -P images/enlil/ http://helioweather.net/missions/psp/per02/anim/tuz-a7b1-d4t05x1-d200t1-donki_vel2e1-psp-x15ifs3z1fr_med_201903-201904.mp4