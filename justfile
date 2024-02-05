env-install:
   micromamba env create --file environment.yml

env-update:
   micromamba install --file environment.yml

preview:
   quarto preview --no-render

publish: update
   quarto publish gh-pages --no-render --no-prompt

render:
   quarto render presentations --to revealjs --profile dev
   cp _site/presentations/*revealjs.html _manuscript/presentations/
   cp -r _site/site_libs/revealjs _manuscript/site_libs/

update:
   git add .
   -git commit -am "update"
   git push