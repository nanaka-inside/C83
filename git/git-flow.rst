#################
git-flow入門
#################

こんにちは ``@j5ik2o`` です。

開発の現場でバージョン管理を導入する際に、Subversion(以下、SVN)よりGitを採用しようという話を聞きます。また、GitのホスティングサービスであるGithub [#github]_ にアカウントを持っているエンジニアも増えています。この機運の高まりからわかるように、これからはGitです。Gitが普通に使えるエンジニアがイケてるエンジニアですね！

さて、Git入門系の書籍やブログなりの情報は、検索すればたくさん出てくるのでここでは触れずに、Gitにある程度慣れてきたがGitのブランチをどのようなルールで運用したらいいのかというテーマで、git-flowという考え方を取り上げて解説したいとおもいます。

gitとgit-flowの環境を構築したい方は :ref:`git-flow-install-label` を参照してください。

.. [#github] https://github.com/

*********************
git-flowという考え方
*********************

git-flowについて知るには `git-flowによるブランチの管理`_ [#git-flow-link]_ を参照しましょう。このサイトでは次のように説明があります。
要するに、Gitブランチをどのように運用するかを決めたイケてるガイドラインの一つです。[#guide-line]_

.. _git-flowによるブランチの管理 : http://www.oreilly.co.jp/community/blog/2011/11/branch-model-with-git-flow.html
.. [#git-flow-link] http://www.oreilly.co.jp/community/blog/2011/11/branch-model-with-git-flow.html
.. [#guide-line] ブランチモデルのデザインパターンの一つぐらいで考えてもらったらいいと思います。こんなパターンはクソだと思う人は既存パターンを改良したり新しくパターンを作ればよいのです。

.. topic:: git-flowによるブランチの管理から引用

   git-flow は Vincent Driessen 氏によって書かれた `A successful Git branching model`_ [#git-flow-branching-model]_ (`O-Show 氏による日本語訳`_ [#git-flow-branching-model-ja]_ ) というブランチモデルを補助するための git 拡張です。 git-flow を利用する前には、まずこの文章を一読することをおすすめします。 その骨子については、 Voluntas 氏のブログ が参考になります。

.. _A successful Git branching model : http://nvie.com/posts/a-successful-git-branching-model/
.. [#git-flow-branching-model] http://nvie.com/posts/a-successful-git-branching-model/
.. _O-Show 氏による日本語訳 : http://keijinsonyaban.blogspot.jp/2010/10/successful-git-branching-model.html
.. [#git-flow-branching-model-ja] http://keijinsonyaban.blogspot.jp/2010/10/successful-git-branching-model.html


================
ブランチの種類
================

``git-flow`` では原則的セントラルリポジトリは1つです。それに伴い ``origin`` 上の ``master`` も唯一無二ということになります。

その ``origin`` 上の ``master`` ブランチの定義ですが、プロダクションリリースのためブランチです。リリースしたらタグ付けもします。 ``master`` ブランチは安定しているリリース版がコミットされているので、普段の開発では ``develop`` ブランチを利用します。常に最新の開発版がコミットされているブランチです。リリースの準備ができたら ``master`` ブランチにマージします。リリース前はこのブランチが最新バージョンとなる。これらのメインブランチは常に存在します。

用途に応じて3つブランチがあります。 ``feature`` ブランチと ``release`` ブランチ、 ``hotfix`` ブランチです。これらのブランチをサポートブランチと呼びます。
``feature`` ブランチ [#topic-branch]_ は新機能を開発するためのブランチです。ある程度の規模の機能を開発する際はこのブランチを使います。
``release`` ブランチはリリースする際の準備を行うためのブランチです。リリースのためのバージョン番号変更、軽微な修正などを反映します。
``hotfix`` ブランチはリリース済みの製品に対してバグフィックなどの修正を反映するためのブランチです。

.. [#topic-branch] 別名トピックブランチという

***********************
git-flowコマンドを使う
***********************

=========
事前準備
=========

``git-flow`` を実践的に解説するために、次のようなコマンドでローカルにGitリポジトリを準備します。

編集対象としてなにかファイルがあった方がよいので、ここでは ``REAME.txt`` を作ってコミットします。

.. code-block:: console

  $ mkdir sandbox
  $ cd sandbox
  $ echo "Hello, git-flow" >  README.txt
  $ git init
  $ git add README.txt
  $ git commit README.txt -m 'first commit'

最初のコミットが完了しました。

次に ``git flow init`` コマンドで初期化を行います。最初のブランチとして ``develop`` ブランチが作成され ``develop`` ブランチに切り替わります(``git checkout -b develop`` 相当 [#nearly_eq_cmd]_)。 ``-d`` のコマンドラインオプションを指定した場合はデフォルトの引数で初期化されます。

.. [#nearly_eq_cmd] 厳密には異なりますが、イメージをつかみやすくするためのgitコマンドです。

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


``git branch`` で確認すると ``master`` ブランチ以外に ``develop`` ブランチが作成され切り替わっていることがわかります。

.. code-block:: console

  $ git branch
  * develop
    master


``git log`` すると以下のようにログを確認できます。

.. code-block:: console

  $ git log
  commit 41f033f4e4ef82666a207b33e4d0e62d2c5887c0
  Author: Junichi Kato <j5ik2o@gmail.com>
  Date:   Sat Dec 1 18:02:09 2012 +0900

      first commit

Atlassian製のSourceTree [#source-tree]_ を使うともっときれいにログを確認できるので、以後はこのツールの画面でログを確認します。現在は ``master`` と ``develop`` は同じリビジョンを指しています。

.. [#source-tree] 分散バージョン管理システム Git や Mercurial 用の強力な無料 Mac クライアントです。AppStoreから簡単にインストールできます。Windowsの人ごめんなさい... http://www.atlassian.com/ja/software/sourcetree/overview

.. figure:: git-flow-img/first-commit.eps
  :scale: 100%
  :alt: SourceTreeでのリビジョングラフ確認
  :align: center


必要に応じて、リモート上のセントラルリポジトリを設定し、 ``push`` します。 ``origin`` にはGithubなどの自分で用意したリモートリポジトリを指定します。

.. code-block:: console

  $ git remote add origin https://github.com/?????/sandbox.git
  $ git push origin

==================================
 featureブランチを開始する
==================================

それでは実際にブランチを作成しながら ``git-flow`` コマンドを実行してみましょう。

とある新機能を実装することになったので、次のとおりのコマンドを実行して ``feature`` ブランチを作成します(``git checkout -b feature/PRJ-123_kato`` 相当)。 ``feature`` ブランチには ``feature/`` というプレフィックス名が付きます。これは ``git flow init`` で指定したプレフィックス名が付加されます。他のサポートブランチにも同様に付加されます。

.. code-block:: console

  $ git flow feature start PRJ-123_kato
  Switched to a new branch 'feature/PRJ-123_kato'

  Summary of actions:
  - A new branch 'feature/PRJ-123_kato' was created, based on 'develop'
  - You are now on branch 'feature/PRJ-123_kato'

  Now, start committing on your feature. When done, use:

       git flow feature finish PRJ-123_kato


``git branch`` で確認すると ``feature/PRJ-123_kato`` ブランチが作成され切り替わっていることがわかります。

.. code-block:: console

  $ git branch
    develop
  * feature/PRJ-123_kato
    master


.. tip:: 課題管理システムを利用している場合は ``チケット番号 + _ + アカウント名`` などでブランチ名を作成するとよいかもしれません。わかりやすいブランチ名を付けておけば、セントラルにpushしてレビューする場合に有益です。

このコマンドライン引数の指定では、基点となるブランチは ``develop`` ブランチですが、 ``git flow feature start PRJ-123_kato b1`` などとすれば ``b1`` ブランチを基点にして ``feature`` ブランチを作成することもできます。

それでは、実際に ``README.txt`` を変更にコミットします。コミットを2回する理由は後で説明します。

.. code-block:: console

  $ echo "aaaaa" >> README.txt
  $ git add README.txt
  $ git commit README.txt -m 'aaaaa追加'
  $ echo "bbbbb" >> README.txt
  $ git add README.txt
  $ git commit README.txt -m 'bbbbb追加'

===========================
featureブランチを終了する
===========================

ブランチでの作業が終わったので次のコマンドを実行して ``develop`` にマージします。

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

このコマンドを実行すると、まず ``git checkout develop`` が実行され ``develop`` ブランチに切り替わります。次に ``git merge --no-ff feature/PRJ-123_kato`` が実行されマージが行われます。 ``--no-ff`` オプションをつけた場合は、 ``feature`` ブランチからマージしたという履歴を残すことができます。
コミットログを確認します。マージコミットがコミットされて、マージが完了したことが確認できます。

.. figure:: git-flow-img/feature-finish.eps
  :scale: 100%
  :alt: SourceTreeでのリビジョングラフ確認
  :align: center

``feature`` ブランチでのコミットが1つだけ存在した状態で、 ``git flow feature finish`` コマンドを実行すると次のようなログになってしまうので注意が必要です。``git-flow`` コマンドの仕様なので仕方ありません。

.. tip::
   finishの際にコミットが1つだけの場合は、 ``git merge --ff feature/PRJ-123_kato`` でマージが行われます。 ``--ff`` オプションがつくマージ( ``fast-forward`` マージ)では ``feature`` ブランチの最新コミットが ``develop`` の最新コミットになってしまうのでこのような現象が発生します。
   その反対の ``--no-ff`` オプションがつくマージ(``non-fast-forward`` マージ)は、 ``feature`` ブランチの最新コミットと ``master`` ブランチの最新コミットをマージした新しいコミットを作成します。

.. figure:: git-flow-img/ff-merge.eps
  :scale: 100%
  :alt: 1つのコミットの場合はff-mergeになる
  :align: center

==========================
releaseブランチを開始する
==========================

あなたはついにリリースの時を迎えました。リリース準備を行うため次のコマンドを実行して ``release`` ブランチを作成します。 ``start`` の後ろにはリリース番号を指定します。

.. code-block:: console

  $ git flow release start 1.0.0
  Switched to a new branch 'release/1.0.0'

  Summary of actions:
  - A new branch 'release/1.0.0' was created, based on 'develop'
  - You are now on branch 'release/1.0.0'

  Follow-up actions:
  - Bump the version number now!
  - Start committing last-minute fixes in preparing your release
  - When done, run:

       git flow release finish '1.0.0'

``git branch`` で確認すると ``release/1.0.0`` ブランチが作成され切り替わっていることがわかります。

.. code-block:: console

  $ git branch
    develop
    master
  * release/1.0.0


ここでは ``release/1.0.0`` 上で適当にREADME.txtを編集していますが、本来はリリース作業のためのビルドツールのバージョン番号を変更したり、リリースノートを書いたりします。

.. code-block:: console

  $ echo "version: 1.0.0" >> README.txt
  $ git add README.txt
  $ git commit README.txt -m 'version up'


==========================
releaseブランチを終了する
==========================

リリースの準備が整ったら、次のコマンドでリリース作業を行います。

.. code-block:: console

  $ git flow release finish 1.0.0
  Switched to branch 'master'
  Merge made by the 'recursive' strategy.
   README.txt |    4 ++++
   1 file changed, 4 insertions(+)
  Switched to branch 'develop'
  Merge made by the 'recursive' strategy.
   README.txt |    2 ++
   1 file changed, 2 insertions(+)
  Deleted branch release/1.0.0 (was 5b69f4d).

  Summary of actions:
  - Latest objects have been fetched from 'origin'
  - Release branch has been merged into 'master'
  - The release was tagged '1.0.0'
  - Release branch has been back-merged into 'develop'


このコマンドを実行すると、最初に ``release/1.0.0`` ブランチの変更を ``master`` ブランチに取り込むマージが実行されます(``git checkout master; git merge --no-ff release/1.0.0`` 相当)。次にそのリビジョンでタグを作成します(``git tag 1.0.0`` 相当)。タグ名はfinishの後に指定したバージョン番号です。次に ``release/1.0.0`` ブランチの変更を ``develop`` ブランチに取り込むマージが実行されます(``git checkout develop; git merge --no-ff release/1.0.0`` 相当)。最後の ``release/1.0.0`` ブランチを削除します。
ログは次のとおりになります。

.. figure:: git-flow-img/release-finish.eps
  :scale: 100%
  :alt: release-finish
  :align: center

作成されたタグ [#git-tag]_ は次のコマンドで確認できます。

.. code-block:: console

  $ git tag -n
  1.0.0           1.0.0 release

.. [#git-tag] finish時にタグに注釈を付加できます。 ``git tag -n`` の ``-n`` オプションはその注釈も表示するオプションです。

==========================
hotfixブランチを開始する
==========================

リリースしたプロダクトに不具合が発生する場合があります。そういう時は次のコマンドで ``hotfix`` ブランチを作成しましょう。

.. code-block:: console

  $ git flow hotfix start 1.0.1
  Branches 'master' and 'origin/master' have diverged.
  And local branch 'master' is ahead of 'origin/master'.
  Switched to a new branch 'hotfix/1.0.1'

  Summary of actions:
  - A new branch 'hotfix/1.0.1' was created, based on 'master'
  - You are now on branch 'hotfix/1.0.1'

  Follow-up actions:
  - Bump the version number now!
  - Start committing your hot fixes
  - When done, run:

``git branch`` で確認すると ``hotfix/1.0.1`` ブランチが作成され切り替わっていることがわかります。

.. code-block:: console

  $ git branch
    develop
  * hotfix/1.0.1
    master


それでは不具合修正作業を行います。ここでは ``README.txt`` を変更します。

.. code-block:: console

  $ vi README.txt # 不具合修正のために編集
  $ git add README.txt
  $ git commit README.txt -m 'bug fix'


==========================
hotfixブランチを終了する
==========================

不具合修正が完了したら、次のコマンドを実行して ``master`` ブランチと ``develop`` にマージします。

.. code-block:: console

  $ git flow hotfix finish 1.0.1
  Branches 'master' and 'origin/master' have diverged.
  And local branch 'master' is ahead of 'origin/master'.
  Switched to branch 'master'
  Your branch is ahead of 'origin/master' by 5 commits.
  Merge made by the 'recursive' strategy.
   README.txt | 3 +--
   1 file changed, 1 insertion(+), 2 deletions(-)
  Switched to branch 'develop'
  Merge made by the 'recursive' strategy.
   README.txt | 3 +--
   1 file changed, 1 insertion(+), 2 deletions(-)
  Deleted branch hotfix/1.0.1 (was ad04c26).

  Summary of actions:
  - Latest objects have been fetched from 'origin'
  - Hotfix branch has been merged into 'master'
  - The hotfix was tagged '1.0.1'
  - Hotfix branch has been back-merged into 'develop'
  - Hotfix branch 'hotfix/1.0.1' has been deleted

コマンドを実行すると、 ``master`` ブランチに切り替わり、 ``hotfix/1.0.1`` の変更内容を取り込むマージを実行します。そのリビジョンでタグも作成されます(``git checkout master; git merge --no-ff hotfix/1.0.1`` 相当)。次に ``develop`` ブランチに切り替わり、 ``hotfix/1.0.1`` ブランチの変更をマージします(``git checkout develop; git merge --no-ff hotfix/1.0.1`` 相当)。最後に ``hotfix/1.0.0`` ブランチを削除します。
ログは次のとおりになります。

.. figure:: git-flow-img/hotfix-finish.eps
  :scale: 100%
  :alt: release-finish
  :align: center

作成されたタグは次のコマンドで確認できます。

.. code-block:: console

  $ git tag -n
  1.0.0           release 1.0.0
  1.0.1           hotfix release 1.0.1


******************************
おわりに
******************************

Gitは柔軟性が高く、ブランチをどのように運用するかは開発者の判断に委ねられています。でも、Gitでの運用経験が少ないうちは、お手本となると手法を採用した方が良いかもしれません。そのような場合は 手始めに ``git-flow`` というブランチモデルを試してみるとよいと思います。


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

msysgit [#msysgit]_ からダウンロードしインストールする。 次のコマンドを実行しバージョンが確認できたらインストール完了。

.. [#msysgit] http://code.google.com/p/msysgit/downloads/list?q=full+installer+official+git

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
   util-linux-ng for Windows から「Complete package,  except sources」のリンクからダウンロードする。例えばデフォルトの「C:\Program Files (x86)\GnuWin32」にインストールしたら、その中の「bin\getopt.exe」と「bin\libintl3.ddl」をmsysgit のインストールディレクトリのbin、デフォルトだったら「C:\Program Files (x86)\Git\bin」にコピーする。

githubからgit-flowのリポジトリとクローンする。

.. code-block:: console

   C:\temp> git clone git://github.com/nvie/gitflow.git

shFlagsも取得する。

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

