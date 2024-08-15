overleaf_repo := "https://git@git.overleaf.com/664f7b472768760cf7d6321c"

clone-overleaf:
  git clone {{overleaf_repo}} overleaf

update-overleaf: sync-overleaf
  cd overleaf; git add .; git commit -am "update"; git push

sync-overleaf:
  #!/usr/bin/env bash
  set -eo pipefail
  command -v bibexport >/dev/null || tlmgr install bibexport
  touch files/bibexport.bib
  quarto render --profile man --to agu-pdf
  bibexport -o files/bibexport.bib --nosave article.aux   
  rsync _manuscript/_tex/ overleaf/ -r
  rsync article_files overleaf -r
  just clean-man

ln-bib:
  mkdir -p files/bibliography
  ln -s ~/projects/share/bibliography/research.bib files/bibliography/research.bib

[private]
clean-man:
  -rm article.{aux,bbl,blg,log,tex}
  -rm -rf article_files
  -rm trackchanges.sty *.cls