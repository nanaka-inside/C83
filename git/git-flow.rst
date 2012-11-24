git+git-flow入門
#################

開発の現場でバージョン管理を導入する際に、Subversion(以下、SVN)よりGitを採用しようという話を聞きます。また、GitのホスティングサービスであるGithub [#f1]_ にアカウントを持っているエンジニアも増えています。この機運の高まりからわかるように、これからはGitです。Gitが普通に使えるエンジニアがイケてるエンジニアですね！

さて、Git入門系の書籍やブログなりの情報は、検索すればたくさん出てくるのでここでは触れずに、Gitにある程度慣れてきたがGitのブランチをどのようなルールで運用するのかというテーマで、git-flowという考え方を取り上げて解説したいとおもいます。

git + git-flow の環境構築手順
******************************

Windows編
==========

gitをインストールする
----------------------

msysgit [#f2]_ からダウンロードしインストールする。 次のコマンドを実行しバージョンが確認できたらインストール完了。

.. code-block:: console

  C:\> git --version
  git version 1.X.X

.gitconfigに名前とメールアドレスを設定する
--------------------------------------------

コミット時に利用される名前とメールアドレスを次のコマンドを実行し設定する。

.. code-block:: console

  C:\> git config --global user.name "あなたの名前"
  C:\> git config --global user.email your_name@dwango.co.jp

このコマンドを実行するとホームディレクトリ直下に.gitconfigファイルができるが、Shift_JISのエンコードのままだとコミットした際に問題が起きるので、UTF-8に変換しておくこと。

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


MacOSX編
=========

gitをインストールする
----------------------

homebrewを使ってインストールし、バージョンを確認できればインストール完了です。

.. code-block:: console

  $ brew install git
  $ git --version
  git version 1.X.X

git-flowをインストールする
---------------------------

.. code-block:: console
   $ brew install git-flow
   $ git-flow version


.. rubric:: 脚注

.. [#f1] https://github.com/
.. [#f2] http://code.google.com/p/msysgit/downloads/list?q=full+installer+official+git
.. [#f3] コマンドラインを解析するためのライブラリ。
