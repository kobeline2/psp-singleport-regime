#!/bin/sh
# Build both PDFs from the shared section files.
#   ./build.sh          both
#   ./build.sh review   content-review PDF only (lualatex)
#   ./build.sh main     submission PDF only (pdflatex; needs tJHR2e.cls here)
# biber is not used: the JHR template is natbib + BibTeX.
set -e
cd "$(dirname "$0")"
what="${1:-both}"
python3 make_bib.py
run() { # engine, jobname
  "$1" -interaction=nonstopmode -halt-on-error "$2" >/dev/null || { tail -30 "$2.log"; exit 1; }
}
if [ "$what" = both ] || [ "$what" = review ]; then
  run lualatex review; bibtex review >/dev/null || true; run lualatex review; run lualatex review
  echo "review.pdf: $(grep -c 'Warning' review.log) warnings, undefined: $(grep -c 'undefined' review.log)"
fi
if [ "$what" = both ] || [ "$what" = main ]; then
  run pdflatex main; bibtex main >/dev/null || true; run pdflatex main; run pdflatex main
  echo "main.pdf: $(grep -c 'Warning' main.log) warnings, undefined: $(grep -c 'undefined' main.log)"
fi
