package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.sys.FileSystem as Fs;
import tannus.node.*;
import tannus.node.Process;
import tannus.async.*;

import pack.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.VoidAsyncs;

class Tools {
    /**
      *
      */
    public static inline function defer(action : Void->Void):Void {
        ((untyped __js__('process')).nextTick( action ));
    }

    /**
      * get the absolute Path to the pack script
      */
    public static function path(?s : String):Path {
        var result:Path = Path.fromString(untyped __js__('__dirname'));
        if (s != null) {
            result = result.plusString( s );
        }
        return result;
    }

    /**
      * perform a batch of Tasks
      */
    public static function batch<T:Task>(tasks:Array<T>, callback:VoidCb):Void {
        var functions = tasks.map.fn( _.run );
        VoidAsyncs.series(functions, callback);
    }

    /**
      * read entire data from Readable
      */
    public static function readAll(s:ReadableStream<Buffer>, cb:ByteArray->Void):Void {
        var buf = new ByteArrayBuffer();
        s.onData(function(dat : Dynamic) {
            if (Std.is(dat, Buffer)) {
                buf.add(ByteArray.ofData(cast dat));
            }
            else if (Std.is(dat, Binary)) {
                buf.add(cast dat);
            }
            else if (Std.is(dat, String)) {
                buf.addString(cast dat);
            }
            else {
                throw 'Error: invalid data $dat';
            }
        });
        s.onEnd(function() {
            cb(buf.getByteArray());
        });
    }

    /**
      * compare the last modified time
      */
    public static function compareLastModified(a:Path, b:Path):Int {
        inline function mtime(x) return Fs.stat( x ).mtime.getTime();
        return Reflect.compare(mtime(a), mtime(b));
    }

    /**
      * check whether [a] is newer than [b]
      */
    public static function newerThan(a:Path, b:Path):Bool {
        inline function mtime(x) return Fs.stat( x ).mtime.getTime();
        return (mtime( a ) > mtime( b ));
    }

    /**
      * check whether any of the files referenced in [a] are newer than [b]
      */
    public static function anyNewerThan(a:Array<Path>, b:Path):Bool {
        for (x in a) {
            if (newerThan(x, b)) {
                return true;
            }
        }
        return false;
    }
}
