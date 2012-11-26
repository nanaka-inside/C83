
Git + Jenkins + Sphinxでドキュメント生成
==========================================

劇的びふぉーあふたー
---------------------

きっかけ
*********

j5ik2o「前回 LaTeX で作ったから、今回は Sphinx でいこうよ」

tboffice「Sphinxですか...」( 前回 LaTeX で苦労してたのに、また新しいのキター)

j5ik2o「ドキュメントはgithubに入ってるから、Jenkins入れて自動ビルドできたらいいね！」

tboffice「Jenkinsですか...」(Jenkinsおじさんはみたことがあるけれど使ったことがないなー) 


いままで
*********

登場人物：ビルドマスターtboffice、メンバーA、メンバーB。

前号 [#gjs-zengou]_ を執筆したときは、TeXファイルを書いて、専用のビルド環境でdvipdfmxを使ってビルドしていました。そのときの会話をお聞き下さい。

メンバーA「ファイル修正したからビルドしてー」

tboffice「ビルドするでー、あ、ここでこけたから修正してー」

メンバーA「修正するー」

メンバーB「おい、自分のドキュメントがビルドできなくなったぞ」

tboffice「スマソ」

そんな感じで、誰かがこけると誰かの作業が止まるという非常によろしくない環境でした。githubでドキュメントを管理していましたが、ファイルの置き場を化していました。

導入後
*******
tboffice「githubにpushするといつのまにかビルドしてpdf作ってくれる！なにこれすげー」

誰がいつpushしても、1分くらい待てばビルドしたpdfができあがるようになるのでした。


はじめに
------------------
まえがき終わりです [#gjs-e]_ 。
今回、Sphinx(スフィンクス) を使って誌面を作ろうということになりました。Sphinxは、python製のドキュメントビルダーです。rst(reStructureText)形式 [#gjs-rst]_ で書かれたプレーンテキストを用意します。そのファイルを、コマンドラインからmakeします。make時のオプションで、HTML形式やepub形式といったドキュメントへ変換できます。前号で使っていたLaTeX(dvipdfmx)環境があったのでそれをそのまま流用し、LaTeXを経由して入稿用のpdfを出力します。

.. [#gjs-zengou] コミックマーケット82で頒布した、ななかInside Press 夏のことです
.. [#gjs-e] えっ!?
.. [#gjs-rst] 見た目は、markdownやwiki記法に似ていないこともないマークアップ言語


仕組み
------
1. できあがったrstファイルをgithubにpush
2. Jenkinsがpushされたことを検知
3. Jenkinsが指定されたsphinxのmakeコマンドを実行
4. makeコマンドの結果をJenkinsが取り込んで、ビルド成功/失敗を表示
5. ビルドに成功していればpdfができている！


用いた環境
----------
* CentOS 5.7(さくらのVPS)
* Sphinx 1.1.3 (デフォルトではdvipdfmxを使ってくれないので設定が必要 [gjs-fmx1]_ )
* TeX Live 2012
* Java 7u9 (JRE)
* Apache Tomcat 7.0.33
* Jenkins 1.491

.. [#gjs-fmx1] http://sphinx-users.jp/cookbook/pdf/latex.html


インストール
------------
SphinxとTeX Live のインストール方法は省略します [#gjs-fmx]_ 。

.. [#gjs-fmx] dvipdfmxコマンドを使えるようにしておきましょう

Javaは公式サイトからrpmを持ってきてインストール。tomcatのtar ballも持ってきてセオリー通りに展開。


.. code-block:: sh

   # rpm -ivh java-7u9.rpm
   # tar zvxf apache-tomcat-7.0.33.tar.gz -C /usr/local/
   # cd !$
   # ln -s apache-tomcat-7.0.33 apache-tomcat


Jenkins のインストールは、公式サイトから、warファイルをダウンロード。tomcatのwebappディレクトリに置くだけ。


.. code-block:: sh

   # cd  /usr/local/apache-tomcat/webapps/
   # wget http://mirrors.jenkins-ci.org/war/latest/jenkins.war



アプリケーションの起動と設定
----------------------------


tomcatを起動
*************

.. code-block:: sh

   # cd /usr/local/apache-tomcat/bin
   # sh start.sh


デフォルトでは8080ポートで起動するのでアクセスしてみましょう [#gjs-port]_ [#gjs-jen-dir]_ [#gjs-tomcat-root]_ [#gjs-tomcat-stop]_ [#gjs-tomcat-stop2]_ [#gjs-nanndekonnna]_ 。

.. figure:: img/start-tomcat.eps
  :scale: 100%
  :alt: tomcatの起動画面
  :align: center

  **tomcatの起動画面**


.. [#gjs-port] アクセスできないときは、ファイアウォールなどで遮断していないことを確認してください
.. [#gjs-jen-dir] 起動したときに /usr/local/apache-tomcat/webapps/jenkins/ ディレクトリができることを確認しておきましょう
.. [#gjs-tomcat-root] ここではrootで作業していますが、jenkinsユーザを作ってそこで立ち上げる方が無難かと思います。起動時のユーザの ~.jenkinsディレクトリ下に作成したジョブなどができるので注意
.. [#gjs-tomcat-stop] stopするときは、start.shと同じディレクトリにある shutdown.sh を実行します。トイレに行って戻ってくるとjavaのプロセスが終了している感じです。焦らない、焦らない
.. [#gjs-tomcat-stop2] Jenkinsの設定画面からシャットダウンをあらかじめやっておくと、プロセスが落ちるのが早い気がする
.. [#gjs-nanndekonnna] どうしてこんなに注釈がおおいんだ。どうしてこうなった。増やしてどうする←


Jenkinsの設定
*************

次にJenkinsの画面にアクセスできることを確認します。アドレスは、tomcatの起動画面のあとに、 /jenkins/ を付け足せば良いです。例：http://hostname:8080/jenkins/。


.. figure:: img/start-jenkins.eps
  :scale: 70%
  :alt: Jenkinsの起動画面
  :align: center

  **Jenkinsの起動画面**


gitプラグインをインストール
^^^^^^^^^^^^^^^^^^^^^^^^^^^

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
^^^^^^^^^^^^^^^^^^^^^^^^^^^
いよいよJenkinsにプロジェクトを作ります。起動画面より、「新規ジョブを作成」を選択してジョブ名を適当に入力。「フリースタイル・プロジェクトのビルド」を選択して「OK」ボタンを押して下さい。
次の画面で、「ソースコード管理システム」にGitがるのでそれを選択して下さい。さっそくgitのURLを入力する画面が現れるのでURLを打ち込んでやってください。
ビルド・トリガの「SCMをポーリング」に「* * * * *」を打ち込んでやってください。
「ビルド」の部分でシェルの実行を選択。シェルスクリプトを書け！と言われるのでsphinxのmakeコマンドを書きます。


:: 

   PATH=$PATH:/usr/local/texlive/2012/bin/x86_64-linux/
   make html && make latexpdfja


そのほかの設定は任意です。最後に「保存」を押せば完了です。


.. figure:: img/setting-job.eps
  :scale: 50%
  :alt: jobの設定
  :align: center

  **ジョブの設定画面**



ビルド結果
***********
ビルドがOKなら青で示され、pdfが出力されているので確認します。
もしビルドがNGなら赤で示されています。コンソール出力からコケた理由をみることができます。


おしまい
--------
こうしてgithubにpushするとpdfが生成できる環境ができあがったのでした [#gjs-acc]_ 。

.. [#gjs-acc] アカウント管理について書いていませんでしたが、ジョブに対してログインアカウントを作ることが出来るので、各自やってみて下さい
