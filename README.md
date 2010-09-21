== purpose ==

- Provide repository to share database backend implementations and target platforms

- extract reusable code from SPOD implementation, such as store (dynamic)
  object in database. Build queries etc.

  Read more about it in db/DBConnection.hx

  The classes reuse Std where possible. But they are prefixed by DB.

== differences to STD ==

- quoteName. You can't use the Std quote function for all backends.
- substPH function providing DSL See below
- result sets should be freed.
  Thus this interface defines query wit a callback function.
  The result set is freed automatically (when implemented)
- functions generating the INSERT and UPDATE query code for you.
- probably I forgot some


== printf like DSL for writing sql queries ==

If you read the original SPOD code you notice one thing:
Each file has its own INSERT INTO .. implementation.
This code duplication is not necessary.


  // substitute placeholders
  //   ? : quoted value
  //   ?v: insert string verbatim (without quoting)
  //   ?n: quote name (table or field name)
  //   ?l: quote list for use in  WHERE field IN (a,b,c)
  //   ?w: {a:"abc", b:"foo"} yields a = "abc" AND b = "foo"
  //
  //   cnx.substPH("INSERT INSTO ?n VALUES (?,?,?v)", [ "table name", value1, value2.toString(), cnx.quote("a string")] )
  // note: the caller is responsible for converting a value into a string like
  //       thing which is understood by the database.
  public function substPH(query:String, args:Array<Dynamic>):String{


Examples:
  
  connection.substPH("SELECT * FROM ?n WHERE ?w", ["tablename", { id: 10, name : "you" }])
  result: SELECT * FROM tablename WHERE id = "10" AND name = "you"

  connection.substPH("UPDATE table SET value = 10 WHERE id in (?l)", [ ["1","2","3","4"] ])
  resuult: UPDATE table SET value = 10 WHERE id in ("1","2","3","4")

Now start browsing db/DBConnection.hx to learn about all funcctions

== pieces taken from ==

nPostgres:
  original upstream: http://code.google.com/p/npostgres (taken from rev 5)
  original author: Lee McColl Sylvester also modified by: Max S
  license & files: (neko/db/Postgresql.hx, npostgres/) see npostgres/LICENSE.txt

  It was also found on lib.haxe.org (Version 0.2.0) when it was included into
  this repository. No differences were found in important files (Makefile,
  Postgresql.hx, postgres.c)

  Reason for inclusion: I don't want to maintain / commit to two repositories -
  Maybe I change the API in the future.
