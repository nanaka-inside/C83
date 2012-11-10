==============
Coreutils 大全
==============

どうも@tboffice [#twitter-tboffice]_ です。前回はasteriskでオレオレコールセンターの作り方を書いていましたが、今回は話題をガラッと変えてCoreutils大全と称してCoreutilsの便利さというか、マニュアル読むといいことあるよという話をしたいと思います。たとえば、

* cdのオプションはいくつあるでしょう
* catを単独で打ったときの挙動は？
* factorコマンドは何をするでしょう

などなど。一部だけなら知っているけど全部知らない人のためにCoreutilsの中身を一通り説明します。
また、筆者が使っていて便利だなと思うTipsも載っけました。Coreutilsから往々に脱線していますが、そのあたりは目をつぶってやってください。
それでは、深遠なるCoreutilsの世界へようこそ。


Coreutilsとは
-------------
lsやcatなど、linuxでは欠かせないコマンドをまとめたパッケージです。Coreutilsは、それ以前にあったFileutils, Shellutils, Textutilsを統合したものです。
CoreutilsのChangeLogをみたところ、一番古い日付は2002-07-01でした。おそらくそのころに統合されたのでしょう。
ほかにUtils系ってないの？という話をすると、binutils(stringsコマンドとか), findutils(findとかxargsとか), inetutils(pingとか)があります。そのほかについてはよくわからね。
メジャーバージョンとしては2003年4月にバージョン5として登場。

共通のオプション
-----------------
コマンドの話に入る前にCoreutils共通のオプションの話を TODO

help version --
----------------

ファイルまるまる出力系
----------------------


cat
---


tac
---

nl
---

od
---

base64
------

体裁を整える系
--------------

fmt
---

pr
---

fold
----

.. toctree::

ファイルの一部を出力
====================
a

head
-----


共通のオプションその2
----------------

.. note::
   注釈ですnote

.. warning::
   警告です。warning

.. rubric:: 脚注
.. [#twitter-tboffice] http://twitter.com/tboffice
.. [#utils-combine] "The last separate versions were fileutils-4.1.11, textutils-2.1, and sh-utils-2.0.15. The first major release of coreutils-5.0 was announced on Fri, 4 April 2003." (http://www.gnu.org/software/fileutils/fileutils.html)
