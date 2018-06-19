package pman.ds.io;

import tannus.ds.*;
import tannus.io.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.extern.EitherType as Either;
import haxe.Constraints.Function;

import edis.storage.fs.*;
import edis.storage.fs.async.FileSystem;

import pman.ds.Port;

import edis.Globals.*;
import pman.Globals.*;
import pman.GlobalMacros.*;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;
using tannus.FunctionTools;

class FilePort extends FileSystemPort <ByteArray> {
    override function read(?cb: Cb<ByteArray>):Promise<ByteArray> {
        return fs.read(path, tqm(pos, _.offset, null), tqm(pos, _.length, null)).toAsync( cb );
    }

    override function write(data:ByteArray, ?cb:VoidCb):VoidPromise {
        return fs.write(path, data, cb);
    }

    public function setSlice(?offset:Int, ?length:Int):FilePort {
        if (offset == null && length == null) {
            pos = null;
        }
        else {
            pos = {
                offset: offset,
                length: length
            };
        }
        return this;
    }

    var pos:Null<{?offset:Int, ?length:Int}> = null;
}
