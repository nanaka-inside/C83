*******************************************
Twitter IRC Gatewayでいこう！30分クッキング
*******************************************

おら ``@mtgto`` ! おっすおっす（挨拶）

==============================================
 IRC Gatewayってなんだよ！ってかIRCって（ｒｙ
==============================================
みんなIRCって使ってるかな？え、なにそれ知らないだって？じゃあぐぐれ！ぐぐればいいんや！

これで君も今日からIRC

*Q1. IRCって古臭くね？*

古いからこそたいていのプラットフォームにクライアントもあるし、
様々なサポートツール [#irc_jenkins_ci]_ も対応してたりします。

*Q2. 画像とか映像とかだめじゃね？*

.. figure:: images/gununu.eps
  :width: 300px
  :scale: 30%
  :alt: ぐぬぬ
  :align: center

  ぐぬぬ

ほ、ほらMacのLimeChatなら画像のURL貼られたらサムネ表示してくれるし…（震え声）

.. [#irc_jenkins_ci] Jenkinsからビルド結果をIRCに通知することもできます

=======================================
 インチキtwitter IRC Gatewayつくるよ！
=======================================
閑話休題。今記事ではTwitterへの投稿と自分のタイムラインの表示がIRCクライアントからできるIRCゲートウェイを作ります。
ちなみにTwitter用のIRCゲートウェイって人気があるのかすでにいくつかあって、そっちのほうが機能も充実しているので
使いたいだけでしたら以下のソフトウェアの方をおすすめしますー。なぜか日本人作者ばかりなので検索すれば情報も結構見つかるし。

* TwitterIrcGateway (.NET) [#irc_link_twitterircgateway]_
* tig.rb (net-ircのサンプル) (ruby) [#irc_link_tig]_
* Another Twitter Irc Gateway (ruby) [#irc_link_atig]_

.. [#irc_link_twitterircgateway] http://www.misuzilla.org/Distribution/TweetIrcGateway/
.. [#irc_link_tig] https://github.com/cho45/net-irc
.. [#irc_link_atig] http://mzp.github.com/atig/

今回はなるべく簡単に出来る方法をとってみたよ！
それは・・・

.. important::
  「コンソールからTwitter投稿できるソフトを呼び出すだけのゲートウェイサーバを作ろう！」

twitter接続周りは全部コンソール版アプリに、IRC接続周りはgemライブラリに任せちゃって、
残ったところだけのソースコードならこの短い紙面でも全部載せられるって、痛い、物投げないで、ごめんｎ（ｒｙ

.. figure:: images/irc-limechat.eps
  :width: 400px
  :alt: LimeChatで接続したオレオレTwitterIrcGatewayのスクリーンショット
  :align: center

  LimeChatで接続したオレオレTwitterIrcGatewayのスクリーンショット

==========
 使用環境
==========
* Mac OS X 10.8.2 on MacBook Air 11' (Mid 2011)
* Ruby 1.9.3p125 (2012-02-16 revision 34643) [#irc_install_ruby]_
* Bundler 1.1.1 [#irc_install_bundler]_
* Emacs 24.1 [#irc_emacs]_

.. [#irc_install_ruby] インストールは ``brew install ruby``
.. [#irc_install_bundler] ``gem install bundler``
.. [#irc_emacs] 必須じゃないです

============
 クッキング
============
まずTwitterクライアントを用意します。投稿とタイムラインの取得が出来ればなんでも良かったので、"twitter CLI"で検索して出てきた"t"というアプリを使います。

.. figure:: images/irc-t.eps
  :width: 300px
  :align: center
  :scale: 50%

  http://sferik.github.com/t/

rubygemsに登録されているので、インストールは ``gem install t`` と実行するだけ。コマンド名も"t"一文字と非常に覚えやすいです。
インストールしたら ``t authorize`` すると、twitter APIの使用申請をするページがブラウザで開くので
慌てず騒がず自分専用アプリの申請をしちゃってください。
今回は ``t`` が言うようにアプリ名は ``<twitterのID>/t`` でつくってみたよ。
websiteは自分のtwitterのページに、アプリの説明は「Rubyで書かれたCLIアプリだよ」とか書いておきましょう。
アプリを作ったあとにSettingsタブからApplication Typeで ``Read, Write and Access direct messages`` を選んでからアプリの更新をするのも忘れずに。

登録するとすぐにConsumer keyとConsumer secretが発行されるので、これをCLIから入力してあげる。

そうするともっかいブラウザが開いてアプリ連携してもいいかという画面が表示され、OKするとPINが発行されるのでこいつをCLIに入力してあげる。
全部うまく行けばこれでコンソールからtwitterを使う準備は整ったわけだ。ね、簡単でしょ？ [#irc_owattenai]_

.. [#irc_owattenai] まだ何も終わってないです

.. code-block:: bash

  $ t stream -N timeline
     @mono_shoo
     これって私が悪いんだっけ？ float.min → float.min_normal ってあってる?
     https://t.co/XRWoPGjt …あってる…よなぁ？
  
     @myrmecoleon
     特撮の三味線

  $ t update "ツイート内容"
  
----------------------------
 rubygemsプロジェクトの作成
----------------------------
今回はrubygems形式で作るよ。gem形式を一から作るのは大変なのでbundlerを使います

.. code-block:: bash

  bundle gem stig

  bundle gem stig
        create  stig/Gemfile
        create  stig/Rakefile
        create  stig/LICENSE
        create  stig/README.md
        create  stig/.gitignore
        create  stig/stig.gemspec
        create  stig/lib/stig.rb
        create  stig/lib/stig/version.rb

gemプロジェクトができたらstig.gemspecをいじります。

.. literalinclude:: stig.gemspec
  :linenos:
  :language: ruby

bundle installコマンドを ``stig.gemspec`` と同じディレクトリで実行すると、必要なライブラリ（このプログラムではnet-ircだけ）をインストールしてくれる。

.. code-block:: bash

  $ bundle install
  Fetching gem metadata from https://rubygems.org/..
  Installing net-irc (0.0.9)
  Using stig (0.0.1) from source at /home/user/stig
  Using bundler (1.1.1)

これで準備が整った。さあプログラムを書いていこう！

-------------
 lib/stig.rb
-------------

.. literalinclude:: stig.rb
  :linenos:
  :language: ruby

autoloadを一行書いただけです。

--------------------
 lib/stig/server.rb
--------------------

.. literalinclude:: server.rb
  :linenos:
  :language: ruby

こいつがプログラムのメイン部分。…といっても50行ないんだけど。
見て分かる人には申し訳ないけど、簡単に解説してみる。

^^^^^^^^^^^^
def on_user
^^^^^^^^^^^^
IRCゲートウェイサーバに新しくユーザが接続してきた時に呼び出されるメソッド。
ここでは、

* ``#timeline`` チャンネルにユーザを自動JOINさせる (17行目)
* 別スレッドで"t stream -N timeline"コマンドを実行し、受信した行をパースして1ツイートごとに投稿 (18-38行目)

という２つのことをやる。

^^^^^^^^^^^^^^^^^^^
def on_disconnected
^^^^^^^^^^^^^^^^^^^
ゲートウェイから接続が切れた時に呼び出されるメソッド。

``on_user`` でスレッドをメンバに持っていたのはユーザがIRCゲートウェイから切断された時にタイムラインの取得を止めるためだったという (42行目)。

^^^^^^^^^^^^^^
def on_privmsg
^^^^^^^^^^^^^^
ユーザがメッセージを投げた時に呼び出されるメソッド。
メッセージの内容を取得して"t update <message>"を実行する (46-47行目)。

他のメソッドは定義してないので、noticeメッセージやらjoinメッセージやらは全部無視される。

--------------------
 実行ファイルの作成
--------------------

最後に実行ファイルを作る。
``bin/stig`` (binディレクトリがなかったらmkdirする) を記述する。

.. literalinclude:: stig
  :linenos:
  :language: ruby

ポート番号は決め打ちで"26667"にしているので、手動で書き換えるかoptparser使って起動時の引数指定できるようにしてもいいと思う。

なお、できあがったものを

**https://github.com/mtgto/stig**

に置いてあるのでコピペするなりなんなりして使ってみてください(´ε｀ )

==========
 おわりに
==========
gitのリポジトリを作ったところから、タイムラインの取得と投稿が出来る状態になってコミットしたまでの時間が32分でした。

30分くらいでTwitterとIRCを連携できるんだ、簡単だなと思ったのでタイトル詐欺ではない！はず！

IRCは汎用性あってみんなで使ってるとおもしろいよ！それじゃまたね！
