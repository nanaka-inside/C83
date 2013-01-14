#!/bin/bash 

make clean
make latex
TEXFILE=_build/latex/Nanaka-inside-c83.tex
#sed -i -e 's/commandchars/frame=single,commandchars/' $TEXFILE

cd _build/latex/
platex Nanaka-inside-c83.tex && dvipdfmx -p b5 -r 600 -v -V 5 -o index-b5.pdf Nanaka-inside-c83.dvi
# platex Nanaka-inside-c83.tex && dvipdfmx -p b5 -c -r 600 -v -V 3 -o index-b5.pdf Nanaka-inside-c83.dvi
