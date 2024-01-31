env-install:
   micromamba env create --file environment.yml

   # micromamba activate psp_conjunction
   # pip install ../space_analysis

env-update:
   micromamba install --file environment.yml

preview:
   quarto preview --no-render

publish: update
   quarto publish gh-pages --no-render --no-prompt

update:
   git add .
   -git commit -am "update"
   git push