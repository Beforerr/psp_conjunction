preview:
   quarto preview --no-render

publish:
   git add .
   git commit -am "update"
   git push
   quarto publish gh-pages --no-render --no-prompt