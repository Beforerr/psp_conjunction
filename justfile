preview:
   quarto preview --no-render

publish: update
   quarto publish gh-pages --no-render --no-prompt

update:
   git add .
   -git commit -am "update"
   git push