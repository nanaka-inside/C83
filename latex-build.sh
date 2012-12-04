#!/bin/bash 

make clean
make latexpdfja
TEXFILE=_build/latex/Nanaka-inside-c83.tex
sed -i -e 's/sphinxhowto/jsarticle/' $TEXFILE
sed -i -e 's/commandchars/frame=single,commandchars/' $TEXFILE
sed -i -e '/\maketitle/d' $TEXFILE
sed -i -e '/tableofcontents/d' $TEXFILE
sed -i -e '/\phantomsection\label{index::doc}/d' $TEXFILE
sed -i -e '/Contents:/d' $TEXFILE
sed -i -e '/\section{Indices and tables}/d' $TEXFILE
sed -i -e '/\label{index:indices-and-tables}\begin{itemize}/d' $TEXFILE
#sed -i -e '/\item {} /d' $TEXFILE
sed -i -e '/\emph{genindex}/d' $TEXFILE
sed -i -e '/\emph{modindex}/d' $TEXFILE
sed -i -e '/\emph{search}/d' $TEXFILE
#sed -i -e '/\end{itemize}/d' $TEXFILE
sed -i -e '/\renewcommand{\indexname}{索引}/d' $TEXFILE
sed -i -e '/\printindex/d' $TEXFILE

cd _build/latex/
platex Nanaka-inside-c83.tex && dvipdfmx -p b5 -r 600 -v -V 3 -o index-b5.pdf Nanaka-inside-c83.dvi
# platex Nanaka-inside-c83.tex && dvipdfmx -p b5 -c -r 600 -v -V 3 -o index-b5.pdf Nanaka-inside-c83.dvi
