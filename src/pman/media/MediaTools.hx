package pman.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import gryffin.media.MediaObject;
import gryffin.display.Video;
import gryffin.audio.Audio;

import Slambda.fn;
import foundation.Tools.defer;

import pman.core.PlayerMediaContext;
import pman.display.*;
import pman.display.media.*;
import pman.ds.*;

import js.html.MediaElement as NativeMediaObject;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;

/**
  * mixin class containing utility methods pertaining to the pman.media.* objects
  */
class MediaTools {
    /**
      * probe the given Directory for all openable files
      */
    public static function getAllOpenableFiles(dir:Directory, done:Array<File>->Void):Void {
        var probe = new OpenableFileProbe();
        probe.setSources([dir]);
        probe.run( done );
    }

    /**
      * convert the given file list into a track list
      */
    public static inline function convertToTracks(files : Array<File>):Array<Track> {
        return (new FileListConverter().convert( files ).toArray());
    }

    /**
      * initialize a list of Tracks all at once
      */
    public static function initAll(tracks:Array<Track>, done:Void->Void):Void {
        var initter = new TrackListInitializer();
        initter.initAll(tracks, function(count : Int) {
            done();
        });
    }

	/**
	  * given a Track object, loads the [media, driver, renderer] fields onto that Track
	  */
	@:access( pman.media.Track )
	public static function loadTrackMediaState(track:Track, callback:Null<Dynamic>->Void):Void {
		var rethrow = fn([error] => callback( error ));
		track.provider.getMedia().unless( rethrow ).then(function(media : Media) {
			track.media = media;
			media.getPlaybackDriver().unless( rethrow ).then(function(driver : PlaybackDriver) {
				track.driver = driver;
				media.getRenderer( driver ).unless( rethrow ).then(function(renderer : MediaRenderer) {
					track.renderer = renderer;
					callback( null );
				});
			});
		});
	}

	/**
	  * wraps a Promise in a standard js-style callback
	  */
	private static function jscbWrap<T>(promise:Promise<T>, handler:Null<Dynamic>->T->Void):Void {
		promise.then(fn([result] => handler(null, result)));
		promise.unless(fn([error] => handler(error, null)));
	}

	/**
	  * get underlying media object from the given MediaObject
	  */
	@:access( gryffin.display.Video )
	@:access( gryffin.audio.Audio )
	public static function getUnderlyingMediaObject(mo : MediaObject):NativeMediaObject {
	    if (Std.is(mo, Video)) {
	        return cast(cast(mo, Video).vid, NativeMediaObject);
	    }
        else if (Std.is(mo, Audio)) {
            return cast(cast(mo, Audio).sound, NativeMediaObject);
        }
        else {
            throw 'Error: Unknown MediaObject type';
        }
	}

	/**
	  * parse the given URI to a MediaProvider
	  */
	public static function uriToMediaProvider(uri : String):MediaProvider {
	    if (uri.startsWith('/')) {
	        return cast new LocalFileMediaProvider(new File( uri ));
	    }
        else {
            var protocol:String = uri.before(':');
            switch ( protocol ) {
                case 'file':
                    return cast new LocalFileMediaProvider(new File(new Path(stripSlashSlash(uri.after(':')))));

                case 'http', 'https':
                    return cast new HttpAddressMediaProvider( uri );

                default:
                    throw 'Error: Malformed media URI "$uri"';
            }
        }
	}

    /**
      * parse the given URI into a Track object
      */
	public static inline function parseToTrack(uri : String):Track {
	    return new Track(uriToMediaProvider( uri ));
	}

    /**
      * trim leading '//' from String
      */
	private static function stripSlashSlash(s : String):String {
	    if (s.startsWith('//')) {
	        s = s.slice( 2 );
	    }
	    return s;
	}
}
