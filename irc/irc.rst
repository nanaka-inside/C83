*******************************************
Twitter IRC Gatewayでいこう！30分クッキング
*******************************************

おら ``@mtgto`` ! おっすおっす（挨拶）

==============================================
 IRC Gatewayってなんだよ！ってかIRCって（ｒｙ
==============================================
みんなIRCって使ってるかな？え、なにそれ知らないだって？じゃあぐぐれ！ぐぐればいいんや！

これで君も今日からIRC

Q. IRCって古臭くね？
古いからこそ様々なサポートツール [#irc_jenkins_ci]_ や

Q. 画像とか映像とかだめじゃね？

.. image:: images/gununu.*
   :width: 300px
   :alt: ぐぬぬ
   :align: center

ほ、ほら

.. [#irc_jenkins_ci] Jenkinsからビルド結果をIRCに通知することもできます

=======================================
 インチキtwitter IRC Gatewayつくるよ！
=======================================
今記事ではTwitterへの投稿と自分のタイムラインの表示がIRCクライアントからできるIRCゲートウェイを作ります。
ちなみにTwitter用のIRCゲートウェイってすでにいっぱいあって、そっちのほうが機能も充実しているので
使いたいだけなら以下のソフトウェアの方をおすすめしますー。日本人作者ばかりなので検索すれば情報も結構見つかるし。

* TwitterIrcGateway ( ``.NET`` ) [#irc_link_twitterircgateway]_
* tig.rb (net-ircのサンプル) ( ``ruby`` ) [#irc_link_tig]_
* Another Twitter Irc Gateway ( ``ruby`` ) [#irc_link_atig]_

.. [#irc_link_twitterircgateway] http://www.misuzilla.org/Distribution/TweetIrcGateway/
.. [#irc_link_tig] https://github.com/cho45/net-irc
.. [#irc_link_atig] http://mzp.github.com/atig/

今回はなるべく簡単に出来る方法をとってみたよ！
それは・・・

.. important::
  「コンソールからTwitter投稿できるソフトを呼び出すだけのゲートウェイサーバを作ろう！」

twitter接続周りは全部コンソール版アプリに、IRC接続周りはgemライブラリに任せちゃって、
残ったところだけのソースコードならこの短い紙面でも全部載せられるって、痛い、物投げないで、ごめんｎ（ｒｙ

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
http://sferik.github.com/t/
gem install t

``gem install t``
``t authorize`` すると、twitter APIの使用申請をするページがブラウザで開くので
慌てず騒がず自分専用アプリの申請をしちゃってください。
``t`` が言うようにアプリ名は ``<twitterのID>/t`` でつくってみたよ。
websiteは自分のtwitterのページに、アプリの説明は「Rubyで書かれたCLIアプリだよ」とか書いておきましょう。
アプリを作ったあとにSettingsタブからApplication Typeで ``Read, Write and Access direct messages`` を選んでからアプリの更新をするのも忘れずに。

登録するとすぐにConsumer keyとConsumer secretが発行されるので、これをCLIから入力してあげる。
そうするともっかいブラウザが開いてアプリ連携してもいいかという画面が表示され、OKするとPINが発行されるのでこいつをCLIに入力してあげる。
全部うまく行けばこれでコンソールからtwitterを使う準備は整ったわけだ。

.. code-block:: bash

  $ t stream -N timeline
     @mono_shoo
     これって私が悪いんだっけ？ float.min → float.min_normal ってあってる? https://t.co/XRWoPGjt …あってる…よなぁ？
  
     @myrmecoleon
     特撮の三味線

  $ t update "ツイート内容"

gemで作るよ

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

stig.gemspecをいじります。

.. code-block:: ruby

  # -*- encoding: utf-8; mode: ruby -*-
  require File.expand_path('../lib/stig/version', __FILE__)
  
  Gem::Specification.new do |gem|
    gem.authors       = ["mtgto"]
    gem.email         = ["hogerappa@gmail.com"]
    gem.description   = %q{TODO: Write a gem description}
    gem.summary       = %q{TODO: Write a gem summary}
    gem.homepage      = ""
  
    gem.files         = `git ls-files`.split($\)
    gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
    gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
    gem.name          = "stig"
    gem.require_paths = ["lib"]
    gem.version       = Stig::VERSION
  
    gem.add_dependency "net-irc", "~> 0.0.9"
  end

bundle installコマンドを ``stig.gemspec`` と同じディレクトリで実行すると、必要なライブラリ（このプログラムではnet-ircだけ）をインストールしてくれる。

.. code-block:: bash

  $ bundle install
  Fetching gem metadata from https://rubygems.org/..
  Installing net-irc (0.0.9)
  Using stig (0.0.1) from source at /home/user/stig
  Using bundler (1.1.1)

これで準備が整った。さあプログラムを書いていこう！

最後に実行ファイルを作る。
``bin/stig`` (binディレクトリがなかったらmkdirする) を記述する。

.. code-block:: ruby

  puts 'hoge'

おわりー！なお、できあがったものがTODO githubのリンク

==========
 おわりに
==========
gitのリポジトリを作ったところから、タイムラインの取得と投稿が出来る状態になってコミットしたまでの時間が32分でした。
30分くらいでTwitterとIRCを連携できるんだ、簡単だなと思ったのでタイトル詐欺ではない！はず！
