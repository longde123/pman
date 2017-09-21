package pman.async.tasks;

import tannus.io.*;
import tannus.ds.*;
import tannus.sys.*;

import pman.core.*;
import pman.media.*;
import pman.edb.*;
import pman.edb.MediaStore;
import pman.async.*;

import Std.*;
import tannus.math.TMath.*;
import Slambda.fn;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using pman.media.MediaTools;
using pman.async.Asyncs;
using pman.async.VoidAsyncs;

@:access( pman.media.Track )
class EfficientTrackListDataLoader extends Task1 {
    /* Constructor Function */
    public function new(tracks:Array<Track>, ms:MediaStore):Void {
        super();

        this.tracks = tracks;
        this.ms = ms;
        this.missingData = new Array();
        this.treg = new Dict();
        this.writes = new Array();
    }

/* === Instance Methods === */

    /**
      * execute [this] Task
      */
    override function execute(done : VoidCb):Void {
        var uris:Array<String> = new Array();//tracks.map.fn( _.uri );
        for (track in tracks) {
            uris.push( track.uri );
            treg[track.uri] = track;
        }

        function complete(?error : Dynamic) {
            var end = now();
            var took = (end - startTime);
            trace('EfficientTrackListDataLoader loaded data for ${tracks.length} in ${took}ms');
            done( error );
        }

        var rlp = ms.getRowsByUris( uris );
        rlp.then(function( rows ) {
            process_existing_rows(rows, complete);
        });
        rlp.unless(function( error ) {
            complete( error );
        });
    }

    /**
      * process and handle the rows loaded for the Tracks who already have data in the database
      */
    private function process_existing_rows(rows:Array<MediaRow>, done:VoidCb):Void {
        var subs = new Array();
        var stupidTracks = new List();
        for (track in tracks) {
            stupidTracks.add( track );
        }
        for (row in rows) {
            var track = treg[row.uri];
            var data = new TrackData( track );
            subs.push(process_existing_row.bind(track, data, row, _));
            stupidTracks.remove( track );
        }
        subs.series(function(?error) {
            if (error != null) {
                return done( error );
            }
            else {
                missingData = stupidTracks.array();
                [writes.series, create_missing_track_data, update_views].series( done );
            }
        });
    }

    /**
      * update the views for all Tracks
      */
    private function update_views(done : VoidCb):Void {
        for (track in tracks) {
            var view = track.getView();
            if (view != null) {
                view.update();
            }
        }
        done();
    }

    /**
      * create new TrackData for those Tracks that were missing theirs
      */
    private function create_missing_track_data(done : VoidCb):Void {
        var creates = new Array();
        var pushes = new Array();

        for (track in missingData) {
            if ( !track._loadingData ) {
                creates.push(function(next : VoidCb) {
                    track._loadingData = true;
                    create_new_data(track, pushes, function(?error, ?data:TrackData) {
                        track._loadingData = false;
                        if (error != null) {
                            next( error );
                        }
                        else {
                            track.data = data;
                            next();
                            track._dataLoaded.call( data );
                        }
                    });
                });
            }
        }

        [creates.series, pushes.series].series( done );
    }

    /**
      * create new TrackData for the given Track
      */
    private function create_new_data(track:Track, pushes:Array<VoidAsync>, submit:Cb<TrackData>):Void {
        var data:TrackData = new TrackData( track );
        load_media_metadata(track, function(?error, ?meta) {
            if (error != null) {
                return submit(error, null);
            }
            else {
                data.meta = meta;
                pushes.push(push_new_data_to_db.bind(data, _));
                return submit(null, data);
            }
        });
    }

    /**
      * push some data to the database
      */
    private function push_new_data_to_db(data:TrackData, done:VoidCb):Void {
        var raw:MediaRow = data.toRaw();
        
        // function to perform a basic INSERT operation
        function insert(done : VoidCb) {
            ms._insertRow(raw, function(?error, ?row:MediaRow) {
                if (error != null) {
                    return done( error );
                }
                else {
                    data.pullRaw( row );
                    data.track.mediaId = data.media_id;
                    return done();
                }
            });
        }

        // function to handle errors in the push operation
        function handle_error(error : Dynamic):Void {
            trace([error]);
            done( error );
        }

        insert(function(?error) {
            if (error != null) {
                handle_error( error );
            }
            else {
                done();
            }
        });
    }

    /**
      * get the media metadata for the given Track
      */
    private function load_media_metadata(track:Track, done:Cb<MediaMetadata>):Void {
        track.source.getMediaMetadata().toAsync( done );
    }

    /**
      * process a single pre-existing row
      */
    private function process_existing_row(track:Track, data:TrackData, row:MediaRow, next:VoidCb):Void {
        track._loadingData = true;
        track.data = data;
        defer(function() {
            data.pullRaw( row );
            ensure_track_data_completeness(data, function(?error) {
                track._loadingData = false;
                if (error != null) {
                    return next( error );
                }
                else {
                    next();
                    track._dataLoaded.call( data );
                }
            });
        });
    }

    /**
      * check that the given TrackData has all expected data, and if not, fill it in
      */
    private function ensure_track_data_completeness(data:TrackData, next:VoidCb):Void {
        if (!data_is_complete( data )) {
            patch_data( data );
        }
        next();
    }

/* === Utility Methods === */

    /**
      * check that the given TrackData is complete
      */
    private inline function data_is_complete(data : TrackData):Bool {
        return true;
    }

    /**
      * patch the given TrackData
      */
    private function patch_data(data:TrackData):Void {
        //TODO
    }

    /**
      * queue up the saving of the given TrackData
      */
    private inline function schedule_data_write(data:TrackData):Void {
        writes.push(untyped data.save.bind(_, ms));
    }

/* === Instance Fields === */

    private var tracks : Array<Track>;
    private var ms : MediaStore;
    private var missingData : Array<Track>;
    private var treg : Dict<String, Track>;
    private var writes : Array<VoidAsync>;
}