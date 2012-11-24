====================================
Androidで学ぶDropboxAPI入門
====================================
みなさん初めまして、ちゅろっす(**Twitter: @chuross**)です。
プログラム書き始めてから大体二年くらいです、最初はPHP使ってニュースサイトや2chまとめアンテナサイトを作っては運営していました。

最近はJavaを始めて主にAndroidアプリを作っています。Androidは運営していたニュースサイトのアプリを作って公開していたのですが、ニュースサイトの閉鎖に合わせて公開を終了しています。

家でプログラムを書いている時はバンダイチャンネルでアニメを観ながらまったりと書いているのが好きです。最近はガンダム00を鑑賞していました。
ガンダム00といえば「ぐえー！」とか「GN電池」といったネタも豊富ですが、実際観てみると面白くてサクサク観れました。

休日はよく秋葉原に生息しています。秋葉原って萌えキャラグッズのイメージをよく持たれますが、意外と食べるとこも多いし上野まで歩いてそう遠くない位置にあるので便利です。もちろん萌えキャラグッズも購入しています。

12月くらいになってNexus7を購入したのですが、気付いたらぽんぽん本を買ってしまいますね。ページめくるのが面倒であんまり本は読まなかったのですが、フリックでページがめくれるし中々便利ですね！

自己紹介はここまでにしておいて早速プログラムの話に入っていきましょう。

DropboxAPIを使って試しになんか作ってみたかったので、Dropboxの中にある画像を使ってAndroidで表示できるアプリを作ってみました。コードは全てGitHubに上がっているので、このコードを読みながら見るとよいと思います！Pull Request待ってます！

`https://github.com/chuchuross/ImageGallery <https://github.com/chuchuross/ImageGallery>`_

今回はこの画像ギャラリーのアプリで使用した時を例にDropboxAPIの使い方を中心に説明していきたいと思います！

画像ギャラリーアプリについて
====================================
本題に入る前に例で使うアプリの紹介を使用と思います。
今回作ったアプリの機能は以下

1. Dropboxの認証
2. Dropboxに置いた画像を取得
3. サムネイルをグリッドで表示
4. サムネイルを押した時に画像を表示

DropboxAPIのサンプル用に作ったアプリなので機能は少なめです。
今作っているGooglePlayに出す予定のアプリでも似ている機能を実装させたいと思っています。

GooglePlayには過去一度公開したことがあるのですが、手間かかりますよねー要求される画像が思ったよりも多くてビックリしてました。
ちなみに初めて公開したアプリのDL数は大体100くらいでした。しょっぱい…。


DropboxAPIって何ぞや
====================================
Dropboxにあるファイル操作を外部のアプリケーションで行うことが可能で、主な機能は以下の二つです。

* アカウント情報取得
* ファイルのアップデート / ダウンロード

他にもファイルのコピーやリビジョンを指定してファイルを復旧させることもできます。

これらの機能が自分の作ったアプリで利用できるようになります！素敵ですね。
Android版の他にもiOS版、Ruby版などがあるので作りたい環境に合わせてAPIを利用できるのはいいですね！今回はAndroid版を使用します。

**DropboxAPIを利用するために必要な物**

SDKは `https://www.dropbox.com/developers/reference/sdk <https://www.dropbox.com/developers/reference/sdk>`_ で入手することができます。
APIの利用にはDropboxアカウントとデベロッパー登録が必要です。
デベロッパー登録は `https://www.dropbox.com/developers <https://www.dropbox.com/developers>`_ の「My apps」から行えます。

**入力項目**

   App type

      アプリのタイプ。core APIでOK

   App name

      アプリ名

   Description

      説明文。適当でいい気がします

   Access

      好きな方を選びましょう。

        * App folder   - Dropboxの中に専用フォルダが生成され、その中だけアクセスできます。
        * Full Dropbox - Dropbox全体にアクセスできます。

登録が終わるとApp keyとSectet keyが取得できるので、これを後で利用します。

.. figure:: src/1.eps
  :scale: 70%
  :alt: Dropboxのデベロッパー登録画面

**Dropboxのデベロッパー登録画面**

Androidへの導入
=================
必要な物(Android SDKやeclipseなど他にもありますが、大体どこでも書かれているので省略します)

* Dropboxアカウント
* DropboxのApp Key, App Secret
* Android Dropbox SDK

**1.** ダウンロードしたSDKのlibフォルダ内にあるjarを全てAndroidプロジェクトの中のlibsに入れましょう。

libsフォルダにjarを入れてプロジェクトをクリーンしてあげると、後はeclipseがよろしくやってくれてプロジェクト内でAPIが利用できるようになります。

**2.**  次にプロジェクトのAndroidManifest.xmlを編集します。

<application>タグ内に以下のコードを記述します。

.. code-block:: xml

  <activity
    android:name="com.dropbox.client2.android.AuthActivity"
    android:launchMode="singleTask"
    android:configChanges="orientation|keyboard">
    <intent-filter>
      <!-- db-INSERT-APP-KEY-HEREを取得したApp keyに変更する -->
      <data android:scheme="db-さっき取得してきたApp keyを入力する" />
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.BROWSABLE"/>
      <category android:name="android.intent.category.DEFAULT" />
    </intent-filter>
  </activity>

**3.** <manifest>タグ内のどこかに以下のパーミッションを追加します。

.. code-block:: xml

  <uses-permission android:name="android.permission.INTERNET"></uses-permission>

これで導入は完了です。
次の項目でDropboxの認証を説明していきます。

AndroidからDropbox認証を行う
==============================
関係のあるコード

   **DropboxAuthActivity(Dropboxの認証画面)**
   `https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/app/DropboxAuthActivity.java <https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/app/DropboxAuthActivity.java>`_

   **DropboxApiManager(DropboxAPIの実行クラス)**
   `https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/dropbox/DropboxApiManager.java <https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/dropbox/DropboxApiManager.java>`_

無事プロジェクトに導入したところで、いよいよ認証処理を実装します。
認証画面を作るためにメインのActivityとは別のActivityを実装しましょう。

--------------------------
認証画面表示まで
--------------------------
今回ぼくが作ったプロジェクトではDropboxAuthActivityという名前で実装しました。
このActivity内呼ばれているDropboxApiManagerがDropbpxApiの処理を行っていて、Authenticationで認証処理を行います。

.. code-block:: java

  /**
   * 認証する
   * 
   * @return session APIセッション
   */
  public DropboxAPI<AndroidAuthSession> Authentication() {
      AppKeyPair appkeys = new AppKeyPair(res.getString(R.string.dropbox_app_key),
  res.getString(R.string.dropbox_app_secret));
      AndroidAuthSession session = new AndroidAuthSession(appkeys, AccessType.APP_FOLDER);

      DropboxAPI<AndroidAuthSession> dropboxApi = new DropboxAPI<AndroidAuthSession>(session);
      dropboxApi.getSession().startAuthentication(context);

      return dropboxApi;
  }

AppKeyPairのコンストラクタにデベロッパー登録時に取得したApp KeyとApp Secretをセットして、AndroidAuthSessionにAppKeyPairとデペロッパー登録時に選択したAccess typeを引数に入れます。
そしてDropboxAPIの引数の中にAndroidAuthSessionを入れた後に、startAuthenticationを呼び出すとDropboxの認証画面が表示されるようになります。

.. figure:: src/2.eps
  :scale: 70%
  :alt: startAuthentication後に表示される認証画面

**startAuthentication後に表示される認証画面**

Authenticationで取得した値はDropboxAPI<AndroidAuthSession>型のメンバ変数に入れて保持させましょう。
この返り値は認証終わった後に使用します。

--------------------------
認証が終わった後
--------------------------
認証後の処理は認証画面のActivity内にあるonResumeで行います。
認証が成功しているかどうかはAuthenticationメソッドの処理で返しているDropboxAPI<AndroidAuthSession>からgetSessionからsessionを取得し、authenticationSuccessfulを呼び出すことで判別できます。

もし認証が完了していればfinishAuthenticationで認証処理を終了して、取得できるようになったトークンをSharedPreferencesに保存して認証画面の処理は終了です。
以降のAPIを使った処理はこのSharedPreferencesに保存したトークンを使用してDropboxから画像をダウンロードするようにします。

.. code-block:: java

  protected void onResume() {
      super.onResume();
      if (!dropboxApi.getSession().authenticationSuccessful()) {
          return;
      }

      //認証処理を終了する
      dropboxApi.getSession().finishAuthentication();

      //アクセストークンを取得する
      AccessTokenPair tokens = dropboxApi.getSession().getAccessTokenPair();

      //取得したトークンをSharedPreferencesに保存する
      Resources res = getResources();
      SharedPreferences sp = getSharedPreferences(res.getString(R.string.sp_dropbox_auth),
  MODE_PRIVATE);
      Editor edit = sp.edit();
      edit.putBoolean(res.getString(R.string.sp_key_is_autentication), true);
      edit.putString(res.getString(R.string.sp_key_access_token), tokens.key);
      edit.putString(res.getString(R.string.sp_key_access_token_secret), tokens.secret);

      //メイン画面に遷移させる
      startActivity(new Intent(this, MainActivity.class));
      finish();
  }

認証が完了するとDropboxから画像がダウンロードされます！やった！

.. figure:: src/3.eps
  :scale: 70%
  :alt: 認証後のメイン画面

**認証後のメイン画面**

----------------------------------------------------
認証済みアクセストークンを取得する
----------------------------------------------------
関係のあるコード

   **DropboxApiManager(DropboxAPIの実行クラス)**
   `https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/dropbox/DropboxApiManager.java <https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/dropbox/DropboxApiManager.java>`_

アクセストークンの取得は認証時に登録したSharedPreferencesから行います。
今回作ったアプリではDropboxApiManagerの中に実装されている、getApiでトークン取得処理実行されています。

.. code-block:: java

  /**
   * 認証済みAPIを取得する
   * 
   * @return 認証済みAPI
   * @throws DropboxException Tokenがnullの時
   */
  private DropboxAPI<AndroidAuthSession> getApi() throws DropboxException {
      SharedPreferences sp = context.getSharedPreferences(res.getString(
  R.string.sp_dropbox_auth), Context.MODE_PRIVATE);

      String userToken = sp.getString(res.getString(R.string.sp_key_access_token), null);
      String userSecret = sp.getString(res.getString(R.string.sp_key_access_token_secret), null);

      if (userToken == null || userSecret == null) {
          throw new DropboxException("Token is null.");
      }

      AppKeyPair access = new AppKeyPair(res.getString(R.string.dropbox_app_key),
  res.getString(R.string.dropbox_app_secret));
      AndroidAuthSession session = new AndroidAuthSession(access, AccessType.APP_FOLDER);

      DropboxAPI<AndroidAuthSession> dropboxApi = new DropboxAPI<AndroidAuthSession>(session);
      AccessTokenPair tokenPair = new AccessTokenPair(userToken, userSecret);
      dropboxApi.getSession().setAccessTokenPair(tokenPair);

      return dropboxApi;
  }

ポイントはAndroidAuthSessionまでは認証時と同じで、AccessTokenPairをセットする時にSharedPreferencesに保存したアクセストークンを入れています。
こうして取得したAPIを利用して後で説明するファイルのダウンロードや一覧の取得を行います。

Dropboxからファイルの取得する
===============================
関係のあるコード

   **DropboxApiManager(DropboxAPIの実行クラス)**
   `https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/dropbox/DropboxApiManager.java <https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/dropbox/DropboxApiManager.java>`_

フォルダにあるファイルを取得する時には先程説明したgetApiメソッドで取得したDropboxAPIの中にあるmetadataメソッドを利用することで取得する事ができます。
取得先のファイルパスと、取得する最大項目数をセットして利用します。この時、フォルダ内にあるファイル以上の数値を入れるとエラーで落ちる事があるので注意しましょう。

.. code-block:: java

  /**
   * Dropboxのファイル一覧を取得する
   * 
   * @param path ファイルパス
   * @param maxItemCount 取得する最大項目数
   * @return ファイルリスト
   * @throws DropboxException
   */
  public List<Entry> getFileList(String path, int maxItemCount) throws DropboxException {
      return getApi().metadata(path, maxItemCount, null, true, null).contents;
  }

Dropboxからファイルのダウンロードを行う
========================================
関係のあるコード

   **DropboxApiManager(DropboxAPIの実行クラス)**
   `https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/dropbox/DropboxApiManager.java <https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/dropbox/DropboxApiManager.java>`_

   **ImageCache(画像キャッシュ)**
   `https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/image/ImageCache.java <https://github.com/chuchuross/ImageGallery/blob/master/src/com/asomal/imagegallery/domain/image/ImageCache.java>`_

ファイルの取得はgetApiで取得したDropboxAPIの中のgetFileStreamで行えます。
先程の項目で説明したgetFileListメソッドで取得したファイルパスを基にgetFileStreamメソッドにファイルパスを入れると、Dropbox内に保存している画像のInputStreamを取得する事ができます。
こうして取得したInputStreamをContext#openFileOutputのwriteで書き込んであげると、Androidの端末内にファイルが保存されます。

.. code-block:: java

  /**
   * ファイルを取得する
   * 
   * @param filePath ファイルのパス
   * @return {@link DropboxInputStream}
   * @throws DropboxException
   */
  public DropboxInputStream getFileStream(String filePath) throws DropboxException {
      return getApi().getFileStream(filePath, null);
  }

感想とまとめ
=================
ここまで読んでみて大体のDropboxAPIはいかがでしょうか！
導入と認証は手順が多いですが、トークンが利用できるようになれば後の操作は簡単ですね。
Dropboxからファイルを取得する時はInputstreamでくるのでZIPファイルに圧縮したり、AndroidであればBitmapFactoryに放り込んだ後のBitmapをImageViewにセットして表示したり自由度は高そうですね！

ただ1つ1つのファイルの取得できる速度は割と遅いので、画像のサムネイルを取得するような大量にリクエストを投げる場合はバックグラウンドで常にDropbox内のフォルダから画像を取得して端末内に保存処理を動かし続けたりする必要がありそうですね。

簡単なアプリを例にDropboxAPIを紹介してみました、みなさんも機会があれば是非アプリに導入してみてください！