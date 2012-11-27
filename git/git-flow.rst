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

git-flowについて知るには `git-flowによるブランチの管理`_ を参照しましょう。このサイトでは次のように説明があります。

.. _git-flowによるブランチの管理 : http://www.oreilly.co.jp/community/blog/2011/11/branch-model-with-git-flow.html

.. tip:: git-flow は Vincent Driessen 氏によって書かれた `A successful Git branching model`_ (`O-Show 氏による日本語訳`_) というブランチモデルを補助するための git 拡張です。 git-flow を利用する前には、まずこの文章を一読することをおすすめします。 その骨子については、 Voluntas 氏のブログ が参考になります。

.. _A successful Git branching model : http://nvie.com/posts/a-successful-git-branching-model/
.. _O-Show 氏による日本語訳 : http://keijinsonyaban.blogspot.jp/2010/10/successful-git-branching-model.html

要するに、Gitブランチをどのように運用するかを決めたガイドラインの一つです。Gitは柔軟性が高く、ブランチをどのように運用するかは開発者の判断に委ねられています。でも、Gitでの運用経験が少ないうちは、お手本となると手法を採用した方が良いかもしれません。そのような場合はgit-flowでのブランチ運用を考えると良いでしょう。

git-flowでは原則的セントラルリポジトリは1つです。それに伴いorigin上のmasterも唯一無二ということになります。

そのorigin上のmasterブランチの定義ですが、プロダクションリリースのためブランチです。リリースしたらタグ付けもします。masterブランチは安定しているリリース版がコミットされているので、普段の開発ではdevelopブランチを利用します。常に最新の開発版がコミットされているブランチです。リリースの準備ができたらmasterブランチにマージします。リリース前はこのブランチが最新バージョンとなる。これらのメインブランチは常に存在します。

用途に応じて3つブランチがあります。featureブランチとreleaseブランチ、hotfixブランチです。これらのブランチをサポートブランチと呼びます。
featureブランチ(別名topicブランチ)は新機能を開発するためのブランチです。ある程度の規模の機能を開発する際はこのブランチを使います。
releaseブランチはリリースする際の準備を行うためのブランチです。リリースのためのバージョン番号変更、軽微な修正などを反映します。
hotfixブランチはリリース済みの製品に対してバグフィックなどの修正を反映するためのブランチです。

***********************
git-flowコマンドを使う
***********************

=========
事前準備
=========

次のようなコマンドで事前準備を行います。originのurlは任意のものでよいです。

.. code-block:: console

  $ mkdir sandbox
  $ cd sandbox
  $ touch README.txt
  $ git init
  $ git add README.txt
  $ git commit README.txt -m 'first commit'

最初のコミットが完了しました。 ``git log`` すると以下のようになります。

.. code-block:: console

  $ git log
  * commit cc4c19b404abadd6bbee2b0d42b267e8cf239644
    Author: じゅんいち☆かとう <j5ik2o@gmail.com>
    Date:   Wed Nov 28 00:38:11 2012 +0900

        first commit

次に ``git flow init`` コマンドで初期化を行います。最初のブランチとして ``develop`` ブランチが作成され ``develop`` ブランチに切り替わります( ``git checkout develop`` されます)。 ``-d`` のコマンドラインオプションを指定した場合はデフォルトの引数で初期化されます。

.. code-block:: console

  $ git flow init -d
  Using default branch names.

  Which branch should be used for bringing forth production releases?
     - develop
     - master
  Branch name for production releases: [master]

  Which branch should be used for integration of the "next release"?
     - develop
  Branch name for "next release" development: [develop]

  How to name your supporting branch prefixes?
  Feature branches? [feature/]
  Release branches? [release/]
  Hotfix branches? [hotfix/]
  Support branches? [support/]
  Version tag prefix? []

必要に応じて、リモート上のセントラルリポジトリを設定し、pushします。

.. code-block:: console

  $ git remote add origin https://github.com/?????/sandbox.git
  $ git push origin

==================================
 featureブランチを開始する
==================================

それでは実際にブランチを作成しながらgit-flowコマンドを実行してみましょう。
とある新機能を実装することになったので、次のとおりfeatureブランチを作成します。

.. code-block:: console

  $ git flow feature start PRJ-123_kato
  Switched to a new branch 'feature/PRJ-123_kato'

  Summary of actions:
  - A new branch 'feature/PRJ-123_kato' was created, based on 'develop'
  - You are now on branch 'feature/PRJ-123_kato'

  Now, start committing on your feature. When done, use:

       git flow feature finish PRJ-123_kato


.. tip:: 課題管理システムを利用している場合は新機能のチケット番号+アカウント名などでブランチ名を作成するとよいかもしれません。わかりやすいブランチ名を付けておけば、セントラルにpushしてレビューする場合に有益です。

実際にREADME.txtを変更にコミットします。コミットを2回する理由は後で説明します。

.. code-block:: console

  $ echo "aaaaa" >> README.txt
  $ git add README.txt
  $ git commit README.txt -m 'aaaaa追加'
  $ echo "bbbbb" >> README.txt
  $ git add README.txt
  $ git commit README.txt -m 'aaaaa追加'

===========================
featureブランチを終了する
===========================

ブランチでの作業が終わったので次のコマンドを実行してdevelopにマージします。

.. code-block:: console

  $ git flow feature finish PRJ-123_kato
  Switched to branch 'develop'
  Merge made by the 'recursive' strategy.
   README.txt |    2 ++
   1 file changed, 2 insertions(+)
  Deleted branch feature/PRJ-123_kato (was f7f0e6d).

  Summary of actions:
  - The feature branch 'feature/PRJ-123_kato' was merged into 'develop'
  - Feature branch 'feature/PRJ-123_kato' has been removed
  - You are now on branch 'develop'

 ``feature/PRJ-123_kato`` ブランチの変更が ``develop`` ブランチにマージされ、削除されたことがわかります。
コミットログを確認します。マージされていることが確認できます。

.. code-block:: console

  $ git log --graph
  *   commit dfea61e1d30e1079f51240c9aa3e54d8729771ec
  |\  Merge: cc4c19b f7f0e6d
  | | Author: じゅんいち☆かとう <j5ik2o@gmail.com>
  | | Date:   Wed Nov 28 01:04:49 2012 +0900
  | |
  | |     Merge branch 'feature/PRJ-123_kato' into develop
  | |
  | * commit f7f0e6d4f0ce56a27122e87879cffaca43b4e911
  | | Author: じゅんいち☆かとう <j5ik2o@gmail.com>
  | | Date:   Wed Nov 28 01:04:40 2012 +0900
  | |
  | |     bbbbb追加
  | |
  | * commit 7387073ccb80243c42e9c93f93fa88ab9f96ed4e
  |/  Author: じゅんいち☆かとう <j5ik2o@gmail.com>
  |   Date:   Wed Nov 28 01:04:22 2012 +0900
  |
  |       aaaaa追加
  |
  * commit cc4c19b404abadd6bbee2b0d42b267e8cf239644
    Author: じゅんいち☆かとう <j5ik2o@gmail.com>
    Date:   Wed Nov 28 00:38:11 2012 +0900

        first commit


.. tip::  ``feature`` ブランチでのコミットが1つだけの場合に ``git flow feature finish`` コマンドを実行した場合は次のようなコミットになります。つまり、 ``feature`` ブランチが存在しなかったことになってしまいます。 ``finish`` に ``feature`` ブランチも削除されてしまうので、注意が必要です。


.. code-block:: console

  * commit 7387073ccb80243c42e9c93f93fa88ab9f96ed4e
  |  Author: じゅんいち☆かとう <j5ik2o@gmail.com>
  |  Date:   Wed Nov 28 01:04:22 2012 +0900
  |
  |     aaaaa追加
  |
  * commit cc4c19b404abadd6bbee2b0d42b267e8cf239644
    Author: じゅんいち☆かとう <j5ik2o@gmail.com>
    Date:   Wed Nov 28 00:38:11 2012 +0900

        first commit


==========================
relaseブランチを開始する
==========================

==========================
relaseブランチを終了する
==========================

==========================
hotfixブランチを開始する
==========================

==========================
hotfixブランチを終了する
==========================

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
