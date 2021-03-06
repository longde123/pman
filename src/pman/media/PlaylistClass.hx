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

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;

/**
  * PlaylistClass -- Object used to hold an ordered list of multiple Track objects
  */
class PlaylistClass {
	/* Constructor Function */
	public function new(?a:Array<Track>, ?parent:Playlist):Void {
		l = (a != null ? a.copy() : new Array());
		if (parent != null)
		    this.parent = parent;

		changeEvent = new Signal();
	}

/* === Instance Methods === */

	/**
	  * get a Track from [this] Playlist at the given index
	  */
	public inline function get(index : Int):Null<Track> {
		return l[ index ];
	}

	/**
	  * create and return a new Playlist by combining [this] one and [other]
	  */
	public function concat(other : Playlist):Playlist {
		return new Playlist(l.concat( other.l ), this);
	}

	/**
	  * create and return a copy of [this] Playlist
	  */
	public inline function copy():Playlist {
		return new Playlist(l.copy(), this);
	}

	/**
	  * Clear [this] Playlist -- alters [this] object in place
	  */
	public function clear():Void {
		l = new Array();
		change( PCClear );
	}

	/**
	  * filter [this] Playlist
	  */
	public function filter(f : Track -> Bool):Playlist {
		return new Playlist(l.filter( f ), this);
	}

	/**
	  * get the index of the given Track
	  */
	public inline function indexOf(track : Track):Int {
		return l.indexOf( track );
	}

	/**
	  * check whether [this] Playlist contains an instance of [t]
	  */
	public function has(t : Track):Bool {
	    for (track in l) {
	        if (track.uri == t.uri) {
	            return true;
	        }
	    }
	    return false;
	}

	/**
	  * get all tracks that occur before [t]
	  */
	public function before(t : Track):Array<Track> {
	    return l.slice(0, (has(t)?indexOf(t):null));
	}

	/**
	  * get all tracks that occur after [t]
	  */
	public function after(t : Track):Array<Track> {
	    return l.slice(has(t)?indexOf(t)+1:0);
	}

	/**
	  * insert the given Track at the given position
	  */
	public function insert(pos:Int, track:Track, report:Bool=true):Void {
		l.insert(pos, track);
		if ( report ) {
			change(PCInsert(pos, track));
		}
	}

	/**
	  * move the given Track to the given index
	  */
	public function move(track:Track, pos:Void->Int, report:Bool=true):Void {
		if (l.has( track )) {
			var oldPos:Int = indexOf( track );
			remove(track, false);
			var newPos:Int = pos();
			insert(newPos, track, false);
			if ( report ) {
				change(PCMove(track, oldPos, newPos));
			}
		}
	}

	/**
	  * iterate over [this] Playlist's Tracks
	  */
	public inline function iterator():Iterator<Track> {
		return l.iterator();
	}

	/**
	  * get the last index at which [track] can be found in [this] Playlist
	  */
	public inline function lastIndexOf(track : Track):Int {
		return l.lastIndexOf( track );
	}

	/**
	  * map [this] Playlist
	  */
	public inline function map<T>(f : Track -> T):Array<T> {
		return l.map( f );
	}

	/**
	  * remove and return the last Track in [this] Playlist
	  */
	public function pop():Null<Track> {
		var t = l.pop();
		if (t != null) {
			change(PCPop( t ));
		}
		return t;
	}

	/**
	  * add [track] to the end of [this] Playlist
	  */
	public function push(track : Track):Int {
		var n = l.push( track );
		change(PCPush( track ));
		return n;
	}

	/**
	  * randomly insert the given Track into [this] Playlist
	  */
	public inline function shuffledPush(track : Track):Void {
	    insert((new Random()).randint(0, length), track);
	}

	/**
	  * delete [track] from [this] Playlist
	  */
	public function remove(track:Track, report:Bool=true, bubble:Bool=true):Bool {
		var status = l.remove( track );
		if (status && report) {
			change(PCRemove( track ));
		}
		if (parent != null && bubble) {
		    parent.remove(track, report, bubble);
		}
		return status;
	}

	/**
	  * reverse [this] Playlist's contents, in place
	  */
	public function reverse():Void {
		l.reverse();
		change( PCReverse );
	}

	/**
	  * remove and return the first Track in [this] Playlist
	  */
	public function shift():Null<Track> {
		var t = l.shift();
		if (t != null) {
			change(PCShift( t ));
		}
		return t;
	}

	/**
	  * get a slice of [this] Playlist
	  */
	public inline function slice(pos:Int, ?end:Int):Playlist {
		return new Playlist(l.slice(pos, end), this);
	}

	/**
	  * sort [this] Playlist
	  */
	public function sort(f : Track->Track->Int):Void {
		l.sort( f );
		change(PCSort( f ));
	}

    /**
      get a sorted copy of [this] Playlist
     **/
	public function sorted(f:Track->Track->Int):Playlist {
	    return new Playlist(l.copy().isort(f), this);
	}

	/**
	  * splice [this] Playlist
	  */
	public inline function splice(pos:Int, len:Int):Playlist {
		return new Playlist(l.splice(pos, len), this);
	}

	/**
	  * convert [this] Playlist to a String
	  */
	public function toString():String {
		return ('Playlist');
	}

	/**
	  * get the Array of Tracks
	  */
	public inline function toArray():Array<Track> {
		return l;
	}

	/**
	  * report a change in [this] Playlist
	  */
	private inline function change(c : PlaylistChange):Void {
		changeEvent.call( c );
	}

    /**
      * check whether [this] Playlist is a child playlist
      */
	public inline function isChildPlaylist():Bool {
	    return (parent != null);
	}

	/**
	  check whether [this] Playlist is a root playlist
	 **/
	public inline function isRootPlaylist():Bool {
	    return !isChildPlaylist();
	}

    /**
      get [this]'s parent playlist
     **/
	public inline function parentPlaylist():Null<PlaylistClass> {
	    return parent;
	}

	public function parentPlaylistUntil(f : Playlist->Bool):Null<PlaylistClass> {
	    var p = parentPlaylist();
	    if (p == null) {
	        return null;
	    }
        else {
            while (p.parent != null) {
                if (f( p )) {
                    return p;
                }
                p = p.parent;
            }
            return null;
        }
	}

    /**
      * get the root Playlist
      */
	public function getRootPlaylist():PlaylistClass {
	    if (isRootPlaylist()) {
	        return this;
	    }
        else {
            var p = parent;
            while (p.parent != null) {
                p = p.parent;
            }
            return p;
        }
	}

/* === Serialization Methods === */

	@:keep
	public function hxSerialize(s : Serializer):Void {
		return ;
	}

	@:keep
	public function hxUnserialize(u : Unserializer):Void {
		return ;
	}

	/**
	  * Convert [this] to a JSON Array
	  */
	public function toJSON():Array<String> {
	    return map.fn(_.provider.getURI());
	}
	//public function toStrings():Array<String> return toJSON();

    /**
      * convert [this] Playlist to a Set of Tracks
      */
	public function toSet():Set<Track> {
	    var set:Set<Track> = new Set();
	    set.pushMany( l );
	    return set;
	}

    /**
      * create a MediaSourceList from [this]
      */
	public function toMediaSourceList():MediaSourceList {
	    return new MediaSourceList(map.fn(_.source));
	}

    /**
      * create and return new Playlist containing no duplicate Tracks
      */
	public function uniqueify():Playlist {
	    return new Playlist(toSet().toArray(), this);
	}

	/**
	  * walk up the playlist 'hierarchy', applying [action] to every playlist until reaching the root
	  */
	public function ascend(action : Playlist->Void):Void {
	    action( this );
	    if (parent != null)
	        parent.ascend( action );
	}

/* === Computed Instance Fields === */

	// the number of items in [this] Playlist
	public var length(get, never):Int;
	private inline function get_length():Int return l.length;

/* === Instance Fields === */

	// the Signal fired when [this] Playlist changes
	public var changeEvent : Signal<PlaylistChange>;
	public var parent : Null<PlaylistClass> = null;

	// the Array of Tracks in [this] Playlist
	private var l : Array<Track>;

/* === Class Methods === */

	/**
	  * Build a Playlist from a JSON array
	  */
	public static function fromJSON(dataStrings : Array<String>):PlaylistClass {
		var tracks:Array<Track> = dataStrings.map.fn(_.toTrack());
		return new PlaylistClass( tracks );
	}

    /**
      * build a Playlist from a MediaSourceList object
      */
	public static function fromMediaSourceList(msl : MediaSourceList):PlaylistClass {
	    return new PlaylistClass(msl.map.fn(new Track(_.toMediaProvider())));
	}

    /**
      * build a Playlist from an Array of Strings that represent references to playable media in some form or another
      */
	public static function fromStrings(sl : Iterable<String>):PlaylistClass {
	    return new PlaylistClass(sl.array().map.fn(_.toTrack()));
	}
}
