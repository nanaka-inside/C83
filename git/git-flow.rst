#################
git-flow入門
#################

こんにちは ``@j5ik2o`` です。

開発の現場でバージョン管理を導入する際に、Subversion(以下、SVN)よりGitを採用しようという話を聞きます。また、GitのホスティングサービスであるGithub [#f1]_ にアカウントを持っているエンジニアも増えています。この機運の高まりからわかるように、これからはGitです。Gitが普通に使えるエンジニアがイケてるエンジニアですね！

さて、Git入門系の書籍やブログなりの情報は、検索すればたくさん出てくるのでここでは触れずに、Gitにある程度慣れてきたがGitのブランチをどのようなルールで運用するのかというテーマで、git-flowという考え方を取り上げて解説したいとおもいます。

gitとgit-flowの環境を構築したい方は :ref:`git-flow-install-label` を参照してください。

*********************
git-flowという考え方
*********************

git-flowについて知るには `git-flowによるブランチの管理`_ [RefGitFlow]_ を参照しましょう。このサイトでは次のように説明があります。

.. _git-flowによるブランチの管理 : http://www.oreilly.co.jp/community/blog/2011/11/branch-model-with-git-flow.html

  .. [RefGitFlow] git-flow は Vincent Driessen 氏によって書かれた `A successful Git branching model`_ (`O-Show 氏による日本語訳`_) というブランチモデルを補助するための git 拡張です。 git-flow を利用する前には、まずこの文章を一読することをおすすめします。 その骨子については、 Voluntas 氏のブログ が参考になります。

.. _A successful Git branching model : http://nvie.com/posts/a-successful-git-branching-model/
.. _O-Show 氏による日本語訳 : http://keijinsonyaban.blogspot.jp/2010/10/successful-git-branching-model.html

要するに、Gitブランチをどのように運用するかを決めたガイドラインの一つです。Gitは柔軟性が高く、ブランチをどのように運用するかは開発者の判断に委ねられています。しかしながら、Gitでの運用経験が少ないうちはお手本となると手法を採用した方が良いかもしれません。そのような場合はgit-flowでのブランチ運用を考えると良いでしょう。

git-flowでは原則的セントラルリポジトリは1つです。それに伴いorigin上のmasterも唯一無二ということになります。
まずmasterブランチの定義ですが、プロダクションリリース用ブランチです。プロダクトをリリースするためのブランチ。プロダクトとしてリリースするためのブランチ。リリースしたらタグ付けします。masterブランチは安定しているリリース版がコミットされているので、普段の開発ではdevelopブランチを利用します。常に最新の開発版がコミットされているブランチです。リリースの準備ができたらmasterブランチにマージします。リリース前はこのブランチが最新バージョンとなる。これらのメインブランチは常に存在します。

===============
ブランチの種類
===============
*  ``master`` ブランチ
*  ``feature`` ブランチ(topicブランチ)
*  ``release`` ブランチ
*  ``hotfix`` ブランチ

======================
ブランチのユースケース
======================
* 新しい機能を開発するために ``feature`` ブランチを作成する
* リリースするために ``release`` ブランチを作成する
* 不具合修正のために ``hotfix`` ブランチを作成する

***********************
git-flowコマンドを使う
***********************

==========================
featureブランチを作成する
==========================

.. code-block:: console

  $ git-flow feature start PRJ-123_kato


.. _git-flow-install-label:

******************************
git & git-flow の環境構築手順
******************************

==========
Windows編
==========

----------------------
gitをインストールする
----------------------

msysgit [#f2]_ からダウンロードしインストールする。 次のコマンドを実行しバージョンが確認できたらインストール完了。

.. code-block:: console

  C:\> git --version
  git version 1.X.X

--------------------------------------------
.gitconfigに名前とメールアドレスを設定する
--------------------------------------------

コミット時に利用される名前とメールアドレスを次のコマンドを実行し設定する。

.. code-block:: console

  C:\> git config --global user.name "あなたの名前"
  C:\> git config --global user.email your_name@dwango.co.jp

このコマンドを実行するとホームディレクトリ直下に.gitconfigファイルができるが、Shift_JISのエンコードのままだとコミットした際に問題が起きるので、UTF-8に変換しておくこと。

---------------------------
git-flowをインストールする
---------------------------

.. note:: その前に getopt と libinit3.ddl をインストールする。
   util-linux-ng for Windows [#f3]_ から「Complete package,  except sources」のリンクからダウンロードする。例えばデフォルトの「C:\Program Files (x86)\GnuWin32」にインストールしたら、その中の「bin\getopt.exe」と「bin\libintl3.ddl」をmsysgit のインストールディレクトリのbin、デフォルトだったら「C:\Program Files (x86)\Git\bin」にコピーする。

githubからgit-flowのリポジトリとクローンする。

.. code-block:: console

   C:\temp> git clone git://github.com/nvie/gitflow.git

shFlags [#f3]_ も取得する。

.. code-block:: console

   C:\tmp> cd gitflow
   C:\tmp\gitflow> git clone git://github.com/nvie/shFlags.git

mysysgitにインストールするコマンドを実行する。次の例は "C:\Program Files (x86)\Git"にインストールしている。

.. code-block:: console

   C:\tmp\gitflow> contrib\msysgit-install.cmd "C:\Program Files (x86)\Git"
   Submodule 'shFlags' (git://github.com/nvie/shFlags.git) registered for path 'shFlags'

=========
MacOSX編
=========

----------------------
gitをインストールする
----------------------

homebrewを使ってインストールし、バージョンを確認できればインストール完了です。

.. code-block:: console

  $ brew install git
  $ git --version
  git version 1.X.X

--------------------------------------------
.gitconfigに名前とメールアドレスを設定する
--------------------------------------------

コミット時に利用される名前とメールアドレスを次のコマンドを実行し設定する。

.. code-block:: console

  $ git config --global user.name "あなたの名前"
  $ git config --global user.email your_name@dwango.co.jp

---------------------------
git-flowをインストールする
---------------------------

homebrewからgit-flowをインストールする。

.. code-block:: console

   $ brew install git-flow
   $ git-flow version

.. rubric:: 脚注

.. [#f1] https://github.com/
.. [#f2] http://code.google.com/p/msysgit/downloads/list?q=full+installer+official+git
.. [#f3] コマンドラインを解析するためのライブラリ。
