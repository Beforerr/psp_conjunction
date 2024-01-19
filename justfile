preview:
   quarto preview --no-render

publish:
   git commit -am "update" & git push
   quarto publish gh-pages --no-render --no-prompt