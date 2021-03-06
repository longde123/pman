package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.Path;
import tannus.http.Url;
import tannus.math.Random;

import haxe.Serializer;
import haxe.Unserializer;

import pman.core.*;
import pman.media.PlaylistChange;
import pman.media.MediaSource;
import pman.bg.MediaTools as MediaMixin;
import pman.bg.MediaTools.MediaSourceTools as MediaSrcTools;
import pman.bg.MediaTools.UriTools as UriMixin;
import pman.bg.URITools;
import pman.media.MediaTools;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
//using pman.media.MediaTools;

@:forward
abstract MediaSourceList (Array<MediaSource>) from Array<MediaSource> to Array<MediaSource> {
    /* Constructor Function */
    public inline function new(?a : Array<MediaSource>):Void {
        this = (a != null ? a : []);
    }

/* === Methods === */

/* === Casting Methods === */

    /**
      * convert [this] to an Array of Strings
      */
    @:to
    public inline function toStrings():Array<String> {
        return this.map(MediaSrcTools.toUri);
    }

    /**
      * Build MediaSourceList from an Array of Strings
      */
    @:from
    public static inline function fromStrings(sl : Array<String>):MediaSourceList {
        return sl.map(UriMixin.toMediaSource);
    }

    @:to
    public inline function toMediaProviders():Array<MediaProvider> {
        //return this.map.fn(_.mediaSourceToMediaProvider());
        return this.map(MediaSourceTools.toMediaProvider);
    }

    @:to
    public inline function toTracks():Array<Track> {
        //return this.map.fn(new Track(_.mediaSourceToMediaProvider()));
        return this.map(MediaSourceTools.toTrack);
    }

    @:from
    public static inline function fromTracks(tracks : Array<Track>):MediaSourceList {
        return tracks.map.fn( _.source );
    }

/* === Instance Fields === */

}
