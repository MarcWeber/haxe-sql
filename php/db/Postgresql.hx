package php.db;

import neko.db.Connection;
import neko.db.ResultSet;

// TODO must all resultsets be closed?
// PostgresResultSet does so only if all rows have been read


private class PostgresConnection implements Connection {

	private var __c : Void;
	private var id : Int;
        private var __h : Dynamic; // last resultset. reference kept for lastInsertId

	public function new( c ) {
                __c = c;
	}

	public function close() {
            untyped __call__("pg_close", __c);
	}


	public function request( qry : String ) : ResultSet {
		__h = untyped __call__("pg_query", __c, qry);
		if(untyped __physeq__(__h, false))
			throw "Error while executing "+qry+" ("+untyped __call__("pg_last_error", c)+")";
		return new PostgresResultSet(cast __h, cast __c);
	}

	public function escape( s : String ) {
                return untyped __call__("pg_escape_string", s);
	}

	public function quote( s : String ) {
                return untyped "'"+__call__("pg_escape_string", s)+"'";
	}

        // what is this func used for?
	public function addValue( s : StringBuf, v : Dynamic ) {
		if( untyped __call__("is_int", v) || __call__("is_null", v))
			s.add(v);
		else if( untyped __call__("is_bool", v) )
			s.add(if( v ) 1 else 0);
		else
			s.add(quote(Std.string(v)));
	}

	public function lastInsertId() {
		var r:PostgresResultSet = cast(request("SELECT lastval()"));
                r.next();
                var e = r.getIntResult(0); 
                r.free();
                return e;
	}

	public function dbName() {
		return "PostgreSQL";
	}

	public function startTransaction() {
		request("BEGIN TRANSACTION");
	}

	public function commit() {
		request("COMMIT");
	}

	public function rollback() {
		request("ROLLBACK");
	}
/*
	public function hasFeature( f ) {
		switch( f ) 
		{
			case "ForUpdate": return false;
		}
		return false;
	}
*/


#if postgresql_specific
        public function lastOid(){
               return untyped { "pg_last_oid($this->r)"; };
        }
#end
}

private class PostgresResultSet implements ResultSet {

	public var length(getLength,null) : Int;
	public var nfields(getNFields,null) : Int;
        var h : Dynamic; // connection object - probably superfluous
	var __r : Dynamic; // pg_query result
	var cache : Dynamic; // pg_fetch_assoc result or null
        var conn: PostgresConnection;

	public function new( r, h ) {
		this.__r = r;
	}

	function getLength():Int {
                // TODO what about affected rows on insert, update? see std, Mysql implementation
                return untyped __call__("pg_num_rows", this.r );
	}

	private var _nfields : Int;
	function getNFields():Int {
		if(_nfields == null)
			_nfields = untyped __call__("pg_num_fields", __r);
		return _nfields;
	}


	private var _fieldsDesc : Array<Dynamic>;
	private function getFieldsDescription() {
		if(_fieldsDesc == null) {
			_fieldsDesc = [];
			for (i in 0...nfields) {
				var item = {
					name : untyped __call__("pg_field_name", __r, i),
					type : untyped __call__("pg_field_type", __r, i)
				};
				_fieldsDesc.push(item);
			}
		}
		return _fieldsDesc;
	}


	private function convert(v : String, type : String) : Dynamic {
		if (v == null) return v;
		switch(type) {
			case "int", "year":
				return untyped __call__("intval", v);
			case "real":
				return untyped __call__("floatval", v);
			case "datetime", "date":
				return Date.fromString(v);
			default:
				return v;
		}
	}


	public function hasNext() {
		if( cache == null )
			cache = next();
		return (cache != null);
	}


	private var cRow : ArrayAccess<String>;
	private function fetchRow() : Bool {
		cRow = untyped __call__("pg_fetch_row", __r);
		return ! untyped __physeq__(cRow, false);
	}

	public function next() : Dynamic {
		if( cache != null ) {
			var t = cache;
			cache = null;
			return t;
		}
		if(!fetchRow()) return null;

		var o : Dynamic = {};
		var descriptions = getFieldsDescription();
		for(i in 0...nfields)
			Reflect.setField(o, descriptions[i].name, convert(cRow[i], descriptions[i].type));
		return o;
	}

	public function results() : List<Dynamic> {
		var l = new List();
		while( hasNext() )
			l.add( next() );
		return l;
	}

	public function getResult( n : Int ) : String {
		if(cRow == null)
			if(!fetchRow())
				return null;
		return cRow[n];
	}


	public function getIntResult( n : Int ) : Int {
		return untyped __call__("intval", getResult(n));
	}


	public function getFloatResult( n : Int ) : Float {
		return untyped __call__("floatval", getResult(n));
	}


	public function free() {
            untyped __call__("pg_free_result", __r);
	}
}

class Postgresql {

	public static function open( conn : String ) : Connection {
		var c = untyped __call__("pg_connect",conn /* ,__php__{"PGSQL_CONNECT_FORCE_NEW";} */ );
		if(untyped __physeq__(c,false))
			throw "Unable to connect to Postgres database by connection string: " + conn;
		return new PostgresConnection(c);
	}

}
