.. raw:: latex

   \clearpage

*******************************************
ありがとうSQLが可能!? PostgreSQLに命令を実装
*******************************************

======================
 PostgreSQLと話そう！
======================
こんにちは。@ijust3でございます。
11月某日、本誌を一緒に執筆しているtbofficeさんから下記のようなIRCメッセージが送られてきました。。[#postgresql_real]_

::

  (tboffice) ijust3: ねーねー
  (tboffice) postgresでありがとうSQLみたいなのを実装できない？
  (tboffice) DBが元気になるようなそんなクエリ
  (mtgto) なにをいってるんだこいつ
  (ijust3) DBが元気になるクエリ？
  (tboffice) だってさあ
  (tboffice) サーバにありがとうっていうと故障しないっていうし
  (tboffice) 御利益のあるバイト列を回転させて
  (tboffice) んーと、んーと
  (mtgto) いまのクエリはまずかったよ、まどか
  (tboffice) あーあ刺さっちゃった

さて、「御利益のあるバイト列を回転させる方法は分かりませんが、独自の命令を実装することなら出来ますよ」ということで、
「PostgreSQLとお話したい!」というtbofficeさんの熱い期待に応えるため、[#postgresql_tboffice]_
今回はPostgreSQLで一問一答が出来るような簡単な機能で、独自の構文拡張について書くことにしました。

.. [#postgresql_real] 実話です
.. [#postgresql_tboffice] この解釈で合っていたのだろうか？

==========
 作るもの
==========
以下に示すような、「THANKS, ほげほげ」とクエリを投げると、PostgreSQLサーバから何か返答が返ってくるような、THANKSコマンドを実装してみます。

::

  # THANKS, postgres
  You're welcome!

返答の内容については、簡単のため、図\ref{}のように「thanks」というテーブルと、対話用のデータを予め作っておいて、
「THANKS, (req列にあるキーワード)」とクエリが来たら、該当する行のres列のデータを返すようにします。

.. code-block:: sql

  CREATE TABLE thanks (
    req   text    NOT NULL,  /* リクエスト */
    res   text               /* レスポンス */
  );
  INSERT INTO thanks (req, res) VALUES ('postgres', E'You\'re welcome!');
  INSERT INTO thanks (req, res) VALUES ('a lot!', 'Not at all!');

図 thanksテーブルの定義と挿入したデータ

======
 実装
======

-------------------
ソースコードの取得
-------------------
まずはPostgreSQLのソースコードを取得して展開してみましょう [#postgresql_download]_ 。
なお、今回は執筆時点で最新のバージョンであるPostgreSQL9.2.1を使用します。

.. [#postgresql_download] http://www.postgresql.org/download からSource code版を取得できます。

展開したPostgreSQLのソースコードの中には、サーバサイトのソースコードだけで無く、psqlのようなクライアントアプリケーションや関連するライブラリ等も含まれています。
今回は、サーバサイドのコードが配置されている"src/backend"ディレクトリと、そこで利用するヘッダファイルが置かれている"src/include"ディレクトリを主に見ていきます。

----------------
クエリ処理の概要
----------------
まずは、今回の変更箇所を明確にするため、サーバ側でのクエリ処理全体の流れについて簡単に紹介します。

通常、PostgreSQLサーバの起動にはpostgresかpg_ctlを使用すると思います [#postgresql_server_start]_ [#postgresql_pg_ctl]_ 。
postgresのエントリポイントであるmain関数は"src/backend/main/main.c"にあります。
postgresは起動すると一連の初期化処理を行った後、クライアントからの接続を待つループ処理に入ります。
クライアントからの接続を受けるとpostgresはforkし、子プロセスがクライアントからのクエリを処理します。

.. [#postgresql_server_start] http://www.postgresql.jp/document/9.2/html/server-start.html
.. [#postgresql_pg_ctl] pg_ctlは内部でsystem()からpostgresコマンドを呼び出して、PostgreSQLサーバを起動させています。

クエリ処理は大まかに次のような流れになります。

1. 字句・構文解析
  クエリとして受信した文字列を字句・構文解析し、構文木を生成します。
2. 意味解析・リライト
  構文木からクエリ木 [#postgresql_query_tree]_ を生成と、ルール条件に従ったクエリの書き換え（例えばVIEWの適用など）を行います。
3. 実行計画の作成・最適化
  クエリ木からプラン木（実行計画）[#postgresql_plan_tree]_を作成します。
  実行計画は基本的にはルールベース・コストベース [#postgresql_plan]_ ・結合順序の組み合わせ [#postgresql_plan2]_ で決定されます。
4. 実行
  決定されたプラン木を基に、処理を実行していきます。

.. [#postgresql_plan_tree] EXPLAIN文の実行結果として表示されるツリーがプラン木です。
.. [#postgresql_query_tree] SQL文の内部表現です。PostgreSQLサーバ起動時にデバッグレベルを設定することで簡単に見ることが出来ます。デバッグレベルは"-d"オプションで、"$ postgres -d5"等と指定します。(5が最大です。) クエリ木については、マニュアルにも記述があります。http://www.postgresql.org/docs/9.2/static/querytree.html
.. [#postgresql_plan] 例えばテーブルを結合する際に、入れ子結合・マージ結合・ハッシュ結合が使えるが、どれが一番速く処理できるか、と言った推測をします。
.. [#postgresql_plan2] 使用するリレーションが3つ以上の場合。


新しいコマンド作成のために、まず、構文解析器を拡張する必要がありそうですね。早速やってみましょう。

--------------
字句・構文解析
--------------
PostgreSQLにおける字句解析・構文解析器はそれぞれ、flexとBisonにより生成されています。
flexとBisonはそれぞれ、字句解析器・構文解析器の生成ツールの1つで、解析のルールを与えるとC言語で書かれた解析器を生成します。
PostgreSQLでは"src/backend/parser/"以下のscan.lとgram.yにそれぞれ、字句解析・構文解析のルールが書かれており、scan.cとgram.c,gram.hが生成された解析器になります。
本記事では、新しいコマンドの構文を拡張したいので、gram.yへ変更を加えて、構文を新しく定義します [#postgresql_flex_bison]_ 。

.. [#postgresql_flex_bison] 開発環境にはflexとBisonを入れておきましょう。配布されているPostgreSQLのソースコードには生成済みのscan.c, gram.c, gram.hは既に含まれていて、flex,Bisonが使用できない場合には字句・構文解析器の再生成は行われません。

Bison文法ファイルは図¥ref{}のような4つの主要な部分から成り、gram.yもこれに従って記述されています。
各部分の書き方は実際にTHANKSコマンドを実装する過程で必要な部分だけ見ていこうと思います。

::

  %{
  Prologue
  (文法規則のアクション部分で使うマクロ定義や変数・関数の定義をC言語でここに書くことが出来ます。
  Prologueの記述は生成されるパーサの実装ファイルの先頭にコピーされます。)
  %}
     
  Bison declarations
  (Bison宣言)
     
  %%
  Grammar rules
  (文法規則)
  %%
     
  Epilogue
  (Epilogueの記述は生成されるパーサの実装ファイルの最後にコピーされます。
  文法規則では使用しないがパーサの実装に必要な処理をC言語で書くことが出来ます。)

図 Bison文法ファイルの概要 (Bisonマニュアルより引用、日本語部分は筆者加筆)

~~~~~~~~~~~~~~~~
キーワードの登録
~~~~~~~~~~~~~~~~
THANKSコマンドの実装のためには、クエリの冒頭に置く"THANKS"という文字列を特別な終端記号（トークン）として扱う必要があります。

ここで終端記号（トークン）とは、意味を持つ文字の並びの最小単位の事です。
前節で述べた字句解析器は、クエリとして受け取った文字列をこの最小単位に分割し、意味を付与して（トークン化）、構文解析器へ渡してくれます。
例えば、「SELECT 1, 2.2, ijust3;」というクエリは、

* SELECT: SELECT {名前付きトークン型(named token type)として型が定義されていて、独自の意味を持っています [#postgresql_token]_ })
* 1: ICONST {整数}
* 2.2: FCONST {浮動小数点数}
* ijust3: IDENT {識別子}
* コンマとセミコロン: single-characterトークン
といった具合に分類されます [#postgresql_scan]_ 。

.. [#postgresql_token] 1,2,3...は整数という括りで分類されますが、SELECTは「SELECT」として分類されるのです！
.. [#postgresql_scan] scan.lにその実装があります。

そういう訳で、"THANKS"をSELECTと同様に特別な終端記号として字句解析されるように、キーワードに登録します。(図¥ref{})
このkwlist.hは、字句解析器と構文解析器の両方から参照され、キーワードを共有しています。
PG_KEYWORDの第2引数はトークン型の値を表す定数で、THANKSという定数はgram.yで定義します。
PG_KEYWORDの第3引数はキーワードの値を名前として使用可能な範囲を設定しています。選択可能な値は下記の4種類があります。

* UNRESERVED_KEYWORD 予約されていないキーワードであり、どの種類の名前にも使用可能
* COL_NAME_KEYWORD カラム名やテーブル名などとして使用可能 [#postgresql_between]_
* TYPE_FUNC_NAME_KEYWORD データ型や関数名として使用可能
* RESERVED_KEYWORD 予約語であり、列ラベルのみで使用可能 [#postgresql_reserved_keyword]_

.. [#postgresql_between] "BETWEEN"はCOL_NAME_KEYWORDですので、"CREATE TABLE between (between int);"としてテーブルを作成すると、"SELECT between FROM between WHERE between BETWEEN 1 AND 2;"のようなbetween好きにはたまらないクエリが発行出来ます。
.. [#postgresql_reserved_keyword] 例) "SELECT 'select' AS select;"

.. code-block:: c

  /* name, value, category */
  PG_KEYWORD("abort", ABORT_P, UNRESERVED_KEYWORD)
  ...
  PG_KEYWORD("text", TEXT_P, UNRESERVED_KEYWORD)
  PG_KEYWORD("thanks", THANKS, UNRESERVED_KEYWORD)
  PG_KEYWORD("then", THEN, RESERVED_KEYWORD)
  ...

図 文字列"thanks"をキーワードとして登録 (src/include/parser/kwlist.h)

次に構文解析器へ"thanks"の処理を加えていきます。
gram.yで、図¥ref{}のように、トークン型としてTHANKSを宣言します。
%tokenで宣言したトークン型には、構文解析器生成時にgram.h内の#defineディレクティブで他のトークン型と衝突しないように数値が割り振られます。[#postgresql_define_token_type]_
<keyword>の部分は型識別子と呼ばれていて、gram.yの中で「const char *」と定義されており、続いて宣言されるトークン型の値も<keyword>と同じ型であることを表しています。

.. [#postgresql_define_token_type] kwlist.hで使用した定数THANKSは、ここで定義されています。

.. code-block:: c
  
  /* ordinary key words in alphabetical order */
  %token <keyword> ABORT_P ABSOLUTE_P ACCESS ACTION ADD_P ADMIN AFTER
    ...
    TABLE TABLES TABLESPACE TEMP TEMPLATE TEMPORARY TEXT_P THANKS
    ...

図 Bison宣言部でトークン型としてTHANKSを定義

~~~~~~~~~~~~~~~~
ステートメントの定義
~~~~~~~~~~~~~~~~
次にTHANKSコマンドのクエリ全体の規則を定義するための非終端記号として、ThanksStmtを宣言します。

非終端記号は、構文的に等価な、(自分自身を含んでも良い)非終端記号や終端記号、その組み合わせのグループを表現した記号です。
非終端記号の文法規則はGrammar rulesの領域に、図¥ref{}のような形式で記述されます。
図¥ref{}は具体例でFROM句の直後で、そのクエリで使用するテーブル名を列挙出来るfrom_listの文法規則を記述しています。
ここでは、再帰的規則を用いながらfrom_listをtable_refへ変換し解析していく様子が分かります。[#postgresql_from_list]_

.. [#postgresql_from_list] SELECT * FROM A, B, C;のようにテーブルは複数指定出来ます。from_listはこの"A, B, C"の部分等に該当する非終端記号です。

::

  非終端記号: ルール1 (非終端記号, 終端記号, その組み合わせ) { アクション (C言語で記述) }
         | ルール2 (複数のルールを並べて定義) { アクション (ルール適用された方を実行) }

図 Bison文法規則の書式

::

  from_list:
      table_ref						{ $$ = list_make1($1); }
      | from_list ',' table_ref		{ $$ = lappend($1, $3); }
    ;

図 再帰的規則を使ったfrom_listの規則

非終端記号の宣言は、Bison宣言部で図¥ref{}のように%typeを用いて宣言します。
<node>はここで宣言される非終端記号がNode型(構文木の1ノード)であることを表しています。

::

  %type <node>	stmt schema_stmt
    ...
    SecLabelStmt SelectStmt TransactionStmt TruncateStmt ThanksStmt
    ...

図 Bison宣言部でThanksStmt

次に図¥ref{}では、stmtの規則としてThanksStmtを追加しています。
stmtにはセミコロン(;)で区切られたクエリ1文が入ってきます。
残る作業は、THANKSコマンドの仕様に沿ったクエリ1文(例: "THANKS, postgres")がstmtに入ってきた際に、ThanksStmtへマッチするように規則を定義すれば良さそうです。

::

  stmt :
			AlterDatabaseStmt
			...
			| SelectStmt
			| ThanksStmt
			...

図 文法規則部にstmtの規則としてThanksStmtを追加

~~~~~~~~~~~~~~~~
ThanksStmtの定義
~~~~~~~~~~~~~~~~
図¥ref{}にThanksStmtの文法規則を記述してみました。
  
.. code-block:: c
  
  ThanksStmt: 
      THANKS thanks_cmd    { $$ = (Node *) $2; }
      | THANKS ',' thanks_cmd  { $$ = (Node *) $3; }
    ;
  
  thanks_cmd:
      a_expr
        {
          ResTarget *rt = makeNode(ResTarget);
          RangeVar *from = NULL;
          Node *colref = NULL;
          A_Expr *where = NULL;
          SelectStmt *n = makeNode(SelectStmt);
        
          /* 取得するカラムとして"res"を指定 */
          rt->name = NULL;
          rt->indirection = NIL;
          rt->val = (Node *)makeColumnRef("res", NIL, @1, yyscanner);;
          rt->location = @1;
  
          /* 検索対象のテーブルとして"thanks"を指定 */
          from = makeRangeVar(NULL, "thanks", @1);
          from->inhOpt = INH_DEFAULT;
          from->alias = NULL;
          
          /* 絞り込み条件として req = a_exprになるように指定 */
          colref = (Node *) makeColumnRef("req", NIL, @1, yyscanner);
          where = makeSimpleA_Expr(AEXPR_OP, "=", colref, $1, @1);
        
          /* Select Stmt */
          n->distinctClause = NIL;
          n->targetList = list_make1(rt);
          n->intoClause = NULL;
          n->fromClause = list_make1(from);
          n->whereClause = (Node *) where;
          n->groupClause = NIL;
          n->havingClause = NULL;
          n->windowClause = NIL;
          $$ = (Node *)n;
        }
      ;


2,3行目は"THANKS"の文字列の後にコンマを付けても付けなくても動作するようにしてみました。
ここで{}に囲われたアクションの実装が異なるのに気がつくかと思います。
$$はこの非終端記号の意味値(Semantic Value)です。$nは右辺に書かれたルールのn番目の記号の意味値を表します。

thanks_cmdは新たに宣言した非終端記号です。[#postgresql_thanks_cmd]_
thanks_cmdの文法規則はa_exprと等価ですが、アクションではSelectStmtから検索用の構文木のノードを生成しています。
また、THANKSコマンドではユーザからresと比較する値以外のデータは与えられませんので、下記のクエリと同等の構文木になるように検索ノードに必要なパラメータを補っています。

::

  SELECT res FROM thanks WHERE req = $1;

.. [#postgresql_thanks_cmd] 紙面では宣言部分の記述は省略しています。


--------
実行結果
--------
さて、psqlからTHANKS文を発行してみると、下記のようなお返事がサーバから返ってきました！やったね！

::

ijust3=# THANKS, 'postgres';
       res       
-----------------
 You're welcome!
(1 row)

======
終わりに
======


======
参考文献
======

