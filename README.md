ななかInside Press vol.2
===
このリポジトリは[サークルMagicMirror](http://nanaka-inside.net/)が[コミックマーケット](http://www.comiket.co.jp/) C83 (2012年12月29,30,31日)
で発行した同人誌「ななかInside Press vol.2」の原稿です。

原稿の生成には[Sphinx](http://sphinx-doc.org/)を使っています。

## QRコードからいらっしゃった方へ
私たちの同人誌をお買い上げいただきありがとうございます。
素人の拙い文章ですが手にとって頂いた皆様の暇潰しに貢献できれば幸いです。

ここには皆様が手にされている冊子の製本用に、印刷所に入稿したPDFを生成する方法も記載しています。
電子書籍で読みたい方はぜひPDF生成にチャレンジしてみてください。

## それ以外からいらっしゃった方へ
とらのあなに委託予定ですのでそちらもよろしくお願い致します。

# ビルド手順
1. Sphinxのセットアップ
2. Texのセットアップ
3. PDFの生成

## 1. Sphinxのセットアップ
easy_installやpipでインストールすればおｋ。
ブロック図の作成のためにsphinxcontrib-blockdiagもインストールしてください。

## 2. Texのセットアップ
platexをインストールすればおｋ。著者はTex Liveを使ってインストールしました。

## 3. PDFの生成
まず、今までSphinxでPDFを生成したことがない方は、[日本語PDFパッチ](http://sphinx-users.jp/cookbook/pdf/latex.html#sphinxpdf)を当てましょう。
これを当てないとlatex実行時にエラーが発生します。

ここまでインストールができていれば次のコマンドでPDFが生成されます。

```shell
./latex-build.sh
```

PDFは`_build/latex/Nanaka-inside-c83.pdf`に生成されます。
