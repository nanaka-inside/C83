

#########################################
Git + Jenkins + Sphinxでドキュメント生成
#########################################


**********************
劇的びふぉーあふたー
**********************


きっかけ
=========

.. topic:: ある日の会話

   j5ik2o「前回 LaTeX で作ったから、今回は Sphinx でいこうよ」
   
   tboffice「Sphinxですか...」( 前回 LaTeX で苦労してたのに、また新しいのキター)
   
   j5ik2o「ドキュメントはgithubに入ってるから、Jenkins入れて自動ビルドできたらいいね！」
   
   tboffice「Jenkinsですか...」(Jenkinsおじさんはみたことがあるけれど使ったことがないなー) 


いままで
=========


登場人物：ビルドマスターtboffice、メンバーA、メンバーB。

.. topic:: ある日よりも前の会話

   前号 [#gjs-zengou]_ を執筆したときは、TeXファイルを書いて、専用のビルド環境でdvipdfmxを使ってビルドしていました。そのときの会話をお聞き下さい。
   
   メンバーA「ファイル修正したからビルドしてー」
   
   tboffice「ビルドするでー、あ、ここでこけたから修正してー」
   
   メンバーA「修正するー」
   
   メンバーB「おい、自分のドキュメントがビルドできなくなったぞ」
   
   tboffice「はわわ、ごめんなさいー」 [#gjs-cha]_

.. [#gjs-cha] こんなキャラじゃないです念のため

誰かがこけると誰かの作業が止まるという非常によろしくない環境でした。githubでドキュメントを管理していましたが、ファイルの置き場と化していました。



導入後
=========


.. topic:: 導入後の喜びの声をお聞き下さい

   tboffice「githubにpushするといつのまにかビルドしてpdf作ってくれる！なにこれすげー」


誰がいつpushしても、1分くらい待てばビルドしたpdfができあがるようになるのでした。

*****************
はじめに
*****************

まえがき終わりです [#gjs-e]_ [#gjs-ee]_ 。
今回、Sphinx(スフィンクス) を使って誌面を作ろうということになりました。Sphinxは、python製のドキュメントビルダーです。rst(reStructuredText)形式 [#gjs-rst]_ で書かれたプレーンテキストを用意します。そのファイルを、コマンドラインからmakeします [#gjs-sm]_ 。make時のオプションで、HTML形式やepub形式といったドキュメントへ変換できます。前号で使っていたLaTeX(dvipdfmx)環境があったのでそれをそのまま流用し、LaTeXを経由して入稿用のpdfを出力します。

.. [#gjs-zengou] コミックマーケット82で頒布した、「ななかInside Press 夏」のことです
.. [#gjs-e] えっ
.. [#gjs-ee] えっ
.. [#gjs-rst] markdownやwiki記法に似ていないこともないマークアップ言語
.. [#gjs-sm] makeするまえに、 sphinx-quickstartというコマンドでひな形のドキュメントを作成しておきましょう


仕組み
======
#. できあがったrstファイルをgithubにpush
#. Jenkinsが1分に1回ポーリングしていて、pushされたことを検知したら次へ
#. Jenkinsが指定されたコマンドを実行
#. コマンドの結果をJenkinsが取り込んで、ビルド成功/失敗を表示
#. ビルドに成功していればpdfができている！
#. ついでにビルド成功/失敗の記録がJenkinsに残っている


用いた環境
==========

* CentOS 5.7 64bit (さくらのVPS)
* Sphinx 1.1.3 (デフォルトではdvipdfmxのオプションがないので設定が必要 [#gjs-fmx1]_ )
* TeX Live 2012
* Java 7u9
* Apache Tomcat 7.0.33
* Jenkins 1.491

.. [#gjs-fmx1] http://sphinx-users.jp/cookbook/pdf/latex.html


インストール
============

SphinxとTeX Live [#gjs-fmx]_ のインストール方法は省略します。

.. [#gjs-fmx] dvipdfmxコマンドを使えるようにしておきましょう

Javaは公式サイトからrpmを持ってきてインストール。tomcatのtar ballも持ってきてセオリー通りに展開。


.. code-block:: console

   # rpm -ivh java-7u9.rpm
   # tar zvxf apache-tomcat-7.0.33.tar.gz -C /usr/local/
   # cd !$
   # ln -s apache-tomcat-7.0.33 apache-tomcat


Jenkins のインストールは、公式サイトから、warファイルをダウンロード。tomcatのwebappsディレクトリに置くだけ。


.. code-block:: console

   # cd  /usr/local/apache-tomcat/webapps/
   # wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war


****************************
アプリケーションの起動と設定
****************************

tomcatを起動
============

.. code-block:: console

   # cd /usr/local/apache-tomcat/bin
   # sh start.sh


デフォルトでは8080ポートで起動するのでアクセスしてみましょう。 [#gjs-tomcatp]_ [#gjs-port]_ [#gjs-jen-dir]_ [#gjs-tomcat-root]_ [#gjs-tomcat-stop]_ [#gjs-tomcat-stop2]_ [#gjs-nanndekonnna]_ 。

.. [#gjs-tomcatp] If you're seeing this, you've successfully installed Tomcat. Congratulations! と書かれたページが表示されれば成功です
.. [#gjs-port] アクセスできないときは、ファイアウォールなどで遮断していないことを確認してください
.. [#gjs-jen-dir] 起動したときに /usr/local/apache-tomcat/webapps/jenkins/ ディレクトリができることを確認しておきましょう
.. [#gjs-tomcat-root] ここではrootで作業していますが、tomcatユーザを作ってそこで立ち上げる方が無難かと思います。起動時のユーザの ~/.jenkinsディレクトリ下に作成したジョブなどができるので注意
.. [#gjs-tomcat-stop] stopするときは、start.shと同じディレクトリにある shutdown.sh を実行します。トイレに行って戻ってくるとjavaのプロセスが終了している感じです。焦らない、焦らない
.. [#gjs-tomcat-stop2] でも、Jenkinsの設定画面からシャットダウンをあらかじめやっておくと、プロセスが落ちるのが早い気がします
.. [#gjs-nanndekonnna] そしてどうしてこんなに注釈が多いんだ。どうしてこうなった。増やしてどうする←


Jenkinsの設定
================

次にJenkinsの画面にアクセスできることを確認します。アドレスは、tomcatの起動画面のあとに、 /jenkins/ を付け足せば良いです。例：http://hostname:8080/jenkins/。


.. figure:: img/start-jenkins.eps
  :scale: 70%
  :alt: Jenkinsの起動画面
  :align: center

  **Jenkinsの起動画面**


gitプラグインをインストール
---------------------------

「Jenkinsの管理」->「プラグインの管理」から「利用可能タブ」で、「Git Plugin」にチェックを入れ、下にある「ダウンロードして再起動後にインストール」を押します。その後の画面で、「インストール完了後、ジョブがなければJenkinsを再起動する」にチェックを入れるとJenkinsが再起動してプラグインが使えるようになります。


.. figure:: img/install-git-plugin.eps
  :scale: 100%
  :alt: git pluginのインストール
  :align: center

  **git pluginのインストール**


.. figure:: img/install-git-plugin2.eps
  :scale: 50%
  :alt: git pluginのインストール2
  :align: center

  **git pluginの適用**


jenkinsにプロジェクト作成
---------------------------

いよいよJenkinsにプロジェクトを作ります。起動画面より、「新規ジョブを作成」を選択してジョブ名を適当に入力。「フリースタイル・プロジェクトのビルド」を選択して「OK」ボタンを押して下さい。
次の画面で、「ソースコード管理システム」にGitがるのでそれを選択して下さい。さっそくgitのURLを入力する画面が現れるのでURLを打ち込んでやってください。
ビルド・トリガの「SCMをポーリング」に「 ``* * * * *`` 」を打ち込んでやってください。
「ビルド」の部分でシェルの実行を選択。シェルスクリプトを書け！と言われるのでsphinxのmakeコマンドを書きます。

.. code-block:: console

   PATH=$PATH:/usr/local/texlive/2012/bin/x86_64-linux/
   make html && make latexpdfja


そのほかの設定は任意です。最後に「保存」を押せば完了です。


.. figure:: img/setting-job.eps
  :scale: 80%
  :alt: jobの設定
  :align: center

  **ジョブの設定画面**


***********
ビルド結果
***********
ビルドが成功なら青で示され、pdfが出力されているので確認します。プロジェクトの「ワークスペース」から自動でビルドされたファイルを見ることが出来ます。
もしビルドがNGなら赤で示されています。コンソール出力から失敗した理由を調査して修正し、再度pushしましょう [#gjs-mo]_ 。

*********
おしまい
*********

こうしてgithubにpushするとpdfが生成できる環境ができあがったのでした [#gjs-acc]_ 。

.. [#gjs-acc] アカウント管理について書いていませんでしたが、ジョブに対してログインアカウントを作ることが出来るので、各自やってみて下さい
.. [#gjs-mo] githubにpushする前に、rstファイルが意図したとおりになっているかローカルで確認する必要があります。ツールについてはrst2pdf(http://code.google.com/p/rst2pdf/)などがあります。
