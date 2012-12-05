.. raw:: latex

   \clearpage

*******************************************
ありがとうSQLが可能!? PostgreSQLに命令を実装
*******************************************
\section{PostgreSQLと話そう！}
こんにちは。@ijust3でございます。
11月某日、本誌を一緒に執筆しているtbofficeさんから図\ref{}のようなIRCメッセージが突然送られてきました。。(実話です。)

 な…　何を言っているのか　わからねーと思うが
 おれも　何を言われているのか　わからなかった…

さて、「御利益のあるバイト列を回転させることは出来ませんが、独自の命令を実装することなら出来ますよ」ということで、
「PostgreSQLとお話したい!」というtbofficeさんの熱い期待に応えるため、
今回はPostgreSQLで一問一答が出来るような簡単な機能を題材に、独自の構文拡張について書いていこうと思います。

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
  図1 


\section{作るもの}
図\ref{}に示すような、「THANKS, ほげほげ」とクエリを投げると、PostgreSQLサーバから何か返答が返ってくるような、THANKSコマンドを実装してみます。

# THANKS, postgres
You're welcome!
図 

返答の内容については、簡単のため、図\ref{}のように「thanks」というテーブルと、対話用のデータを予め作っておいて、
「THANKS, (req列にあるキーワード)」とクエリが来たら、該当する行のres列のデータを返すようにします。

::
  CREATE TABLE thanks (
    req   text    NOT NULL,
    res   text
  );
  INSERT INTO thanks (req, res) VALUES ('postgres', E'You\'re welcome!');
  INSERT INTO thanks (req, res) VALUES ('a lot!', 'Not at all!');

図 



\section{実装}
\subsection{ソースコードの取得}
まずはPostgreSQLのソースコードを取得して展開してみましょう。\footnote{http://www.postgresql.org/download からSource code版を取得できます。}
なお、今回は執筆時点で最新のバージョンであるPostgreSQL9.2.1を使用します。

展開したPostgreSQLのソースコードの中には、サーバサイトのソースコードだけで無く、psqlのようなクライアントアプリケーションや関連するライブラリ等も含まれています。
今回は、サーバサイドのコードが配置されている"src/backend"ディレクトリと、そこで利用するヘッダファイルが置かれている"src/include"ディレクトリ(図\ref{})を主に見ていきます。



図 配布されているソースコードのディレクトリ構造

\subsection{クエリ処理の概要}
まずは、今回の変更箇所を明確にするため、サーバ側でのクエリ処理全体の流れについて簡単に紹介します。

通常、PostgreSQLサーバの起動には図\ref{}のようにpostgresかpg_ctlを使用すると思います。\footnote{pg_ctlは内部でsystem()からpostgresコマンドを呼び出して、PostgreSQLサーバを起動させています。} ..引用: http://www.postgresql.jp/document/9.2/html/server-start.html
postgresのエントリポイントであるmain関数は"src/backend/main/main.c"にあります。
postgresは起動すると一連の初期化処理を行った後、クライアントからの接続を待つループ処理に入ります。
クライアントからの接続を受けるとpostgresはforkし、子プロセスがクライアントからのクエリを処理します。

::

  $ postgres
  または
  $ pg_ctl start

クエリ処理は大まかに次のような流れになります。
1. 字句・構文解析
  クエリとして受信した文字列を字句・構文解析し、構文木を生成します。
2. 意味解析・リライト
  構文木からクエリ木\footnote{SQL文の内部表現です。PostgreSQLサーバ起動時にデバッグレベルを設定することで簡単に見ることが出来ます。デバッグレベルは"-d"オプションで、"$ postgres -d5"等と指定します。(5が最大です。) クエリ木については、マニュアルにも記述があります。http://www.postgresql.org/docs/9.2/static/querytree.html}を生成と、ルール条件に従ったクエリの書き換え（例えばVIEWの適用など）を行います。
3. 実行計画の作成・最適化
  クエリ木からプラン木（実行計画）を作成します。(図\ref{})
  実行計画は基本的にはルールベース・コストベース\footnote{例えばテーブルを結合する際に、入れ子結合・マージ結合・ハッシュ結合が使えるが、どれが一番速く処理できるか、と言った推測をします。}・結合順序の組み合わせ\footnote{使用するリレーションが3つ以上の場合。}で決定されます。
4. 実行
  決定されたプラン木を基に、処理を実行していきます。

では早速、新しいコマンド作成のために構文解析器を拡張してみましょう。

..ここに図を挿入
図 プラン木の例

\subsection{字句・構文解析}
PostgreSQLにおける字句解析・構文解析器はそれぞれ、flexとBisonにより生成されています。
flexとBisonはそれぞれ、字句解析器・構文解析器の生成ツールの1つで、解析のルールを与えるとC言語で書かれた解析器を生成します。
PostgreSQLでは"src/backend/parser/"以下のscan.lとgram.yにそれぞれ、字句解析・構文解析のルールが書かれており、scan.cとgram.c,gram.hが生成された解析器になります。
本記事では、新しいコマンドの構文を拡張したいので、gram.yへ変更を加えて、構文を新しく定義します。¥footnote{開発環境にはflexとBisonを入れておきましょう。配布されているPostgreSQLのソースコードには生成済みのscan.c, gram.c, gram.hは既に含まれていて、flex,Bisonが使用できない場合には字句・構文解析器の再生成は行われません。}

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

\subsubsection{キーワードの登録}
THANKSコマンドの実装のためには、クエリの冒頭に置く"THANKS"という文字列を特別な終端記号（トークン）として扱う必要があります。

ここで終端記号（トークン）とは、意味を持つ文字の並びの最小単位の事です。
前節で述べた字句解析器は、クエリとして受け取った文字列をこの最小単位に分割し、意味を付与して（トークン化）、構文解析器へ渡してくれます。
例えば、「SELECT 1, 2.2, ijust3;」というクエリは、
* SELECT: SELECT {名前付きトークン型(named token type)として型が定義されていて、独自の意味を持っています¥footnote{1,2,3...は整数という括りで分類されますが、SELECTは「SELECT」として分類されるのです！と乱暴な補足を入れてみます。})
* 1: ICONST {整数}
* 2.2: FCONST {浮動小数点数}
* ijust3: IDENT {識別子}
* コンマとセミコロン: single-characterトークン
といった具合に分類されます。¥footnote{そう分類されるようにscan.lが実装されています。}

そういう訳で、"THANKS"をSELECTと同様に特別な終端記号として字句解析されるように、キーワードに登録します。(図¥ref{})
このkwlist.hは、字句解析器と構文解析器の両方から参照され、キーワードを共有しています。
PG_KEYWORDの第2引数はトークン型の値を表す定数で、THANKSという定数はgram.yで定義します。
PG_KEYWORDの第3引数はキーワードの値を名前として使用可能な範囲を設定しています。選択可能な値は下記の4種類があります。
* UNRESERVED_KEYWORD 予約されていないキーワードであり、どの種類の名前にも使用可能
* COL_NAME_KEYWORD カラム名やテーブル名などとして使用可能¥footnote{"BETWEEN"はCOL_NAME_KEYWORDですので、"CREATE TABLE between (between int);"としてテーブルを作成すると、"SELECT between FROM between WHERE between BETWEEN 1 AND 2;"のようなbetween好きにはたまらないクエリが発行出来ます}
* TYPE_FUNC_NAME_KEYWORD データ型や関数名として使用可能
* RESERVED_KEYWORD 予約語であり、列ラベルのみで使用可能¥footnote{例) "SELECT 'select' AS select;"}


/*
 * List of keyword (name, token-value, category) entries.
 *
 * !!WARNING!!: This list must be sorted by ASCII name, because binary
 *		 search is used to locate entries.
 */

/* name, value, category */
PG_KEYWORD("abort", ABORT_P, UNRESERVED_KEYWORD)
...
PG_KEYWORD("text", TEXT_P, UNRESERVED_KEYWORD)
PG_KEYWORD("thanks", THANKS, UNRESERVED_KEYWORD)
PG_KEYWORD("then", THEN, RESERVED_KEYWORD)
...
図 文字列"thanks"をキーワードとして登録 (src/include/parser/kwlist.h)


次に構文解析器へ"thanks"の処理を加えていきます。


::

/*
 * If you want to make any keyword changes, update the keyword table in
 * src/include/parser/kwlist.h and add new keywords to the appropriate one
 * of the reserved-or-not-so-reserved keyword lists, below; search
 * this file for "Keyword category lists".
 */

/* ordinary key words in alphabetical order */
%token <keyword> ABORT_P ABSOLUTE_P ACCESS ACTION ADD_P ADMIN AFTER
	AGGREGATE ALL ALSO ALTER ALWAYS ANALYSE ANALYZE AND ANY ARRAY AS ASC
	...
	TABLE TABLES TABLESPACE TEMP TEMPLATE TEMPORARY TEXT_P THANKS THEN TIME TIMESTAMP
    ...

図 Bison宣言部でトークン(終端記号)としてTHANKSを定義



::

%type <node>	stmt schema_stmt
		AlterDatabaseStmt AlterDatabaseSetStmt AlterDomainStmt AlterEnumStmt
		...
		RuleActionStmt RuleActionStmtOrEmpty RuleStmt
		SecLabelStmt SelectStmt TransactionStmt TruncateStmt ThanksStmt
		UnlistenStmt UpdateStmt VacuumStmt
		...
図 Bison宣言部で、Nodeポインタ型としてThanksStmtを非終端記号として定義


::

stmt :
			AlterDatabaseStmt
			| AlterDatabaseSetStmt
			...
			| SelectStmt
			| ThanksStmt
			| TransactionStmt
			...
			| ViewStmt
			| /*EMPTY*/
				{ $$ = NULL; }
		;

図 文法規則部にstmtの規則としてThanksStmtを追加



\subsubsection{パラメータを持たないコマンドの実装}

::
/*****************************************************************************
 *
 *		QUERY:
 *				THANKS
 *
 *****************************************************************************/
ThanksStmt: 
		THANKS
 				{
					VacuumStmt *n = makeNode(VacuumStmt);
					n->options = VACOPT_ANALYZE;
					n->freeze_min_age = -1;
					n->freeze_table_age = -1;
					n->relation = NULL;
					n->va_cols = NIL;
					$$ = (Node *)n;
				}
図 パラメータを取らないコマンドの実装例

\subsubsection{パラメータの取得}

::
/*****************************************************************************
 *
 *		QUERY:
 *				THANKS target_list FROM from_list
 *
 *****************************************************************************/
ThanksStmt: 
		THANKS target_list from_clause
				{
					SelectStmt *n = makeNode(SelectStmt);
					n->distinctClause = NIL;
					n->targetList = $2;
					n->intoClause = NULL;
					n->fromClause = $3;
					n->whereClause = NULL;
					n->groupClause = NIL;
					n->havingClause = NULL;
					n->windowClause = NIL;
					$$ = (Node *)n;
				}
		;
図 


/*****************************************************************************
 *
 *		QUERY:
 *				THANKS a_expr
 *
 *****************************************************************************/
ThanksStmt: 
		THANKS thanks_cmd		{ $$ = (Node *) $2; }
		| THANKS ',' thanks_cmd	{ $$ = (Node *) $3; }
	;

thanks_cmd:
		a_expr
			{
				ResTarget *rt = makeNode(ResTarget);
				RangeVar *from = NULL;
				Node *colref = NULL;
				A_Expr *where = NULL;
				SelectStmt *n = makeNode(SelectStmt);
				
				/* target_el */
				rt->name = NULL;
				rt->indirection = NIL;
				rt->val = (Node *)makeColumnRef("res", NIL, @1, yyscanner);;
				rt->location = @1;

                /* table_ref */
                from = makeRangeVar(NULL, "thanks", @1);
				from->inhOpt = INH_DEFAULT;
				from->alias = NULL;
					
				/* where clause */
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
				n->isThanks = TRUE;
				$$ = (Node *)n;
			}
		;
図 


\subsubsection{SelectStmtへのメンバの追加}




\subsection{終わりに}



