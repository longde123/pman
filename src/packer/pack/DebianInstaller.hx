package pack;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;
import tannus.async.*;

import haxe.Json;
import js.Lib.require;

import pack.*;
import pack.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pack.Tools;

class DebianInstaller extends Installer {
    /* Constructor Function */
    public function new(arch:String):Void {
        super('linux', arch);
    }

/* === Instance Methods === */

    /**
      * get the function that'll be used to build installer
      */
    override function getBuildFunction():Dynamic {
        return require( 'electron-installer-debian' );
    }

    /**
      * amend [options]
      */
    override function buildOptions():Void {
        super.buildOptions();
        options.write({
            categories: ['Player', 'Media', 'Video', 'Audio', 'Movie', 'Music'],
            mimeType: ['video/mp4', 'audio/mp3']
        });
    }

    /**
      * build icon spec
      */
    override function getIcon():Dynamic {
        var icons:Object = {};
        inline function i(size : Int) {
            icons['${size}x${size}'] = path('assets/icon$size.png').toString();
        }
        for (size in [16, 32, 48, 64, 128, 256]) {
            i( size );
        }
        return icons;
    }
}
