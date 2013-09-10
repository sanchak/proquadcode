#!/bin/csh 

set nm=XX
pdflatex $nm.tex
acr $nm.pdf &
