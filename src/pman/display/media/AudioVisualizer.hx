package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
import pman.display.media.AudioPipeline;

import electron.Tools.defer;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;
using tannus.async.Asyncs;

class AudioVisualizer extends MediaRendererComponent {
    /* Constructor Function */
    public function new(r : Mor):Void {
        super();

        renderer = r;
        viewport = new Rect();
    }

/* === Instance Methods === */

    /**
      * render visualization
      */
    override function render(stage:Stage, c:Ctx):Void {
        //TODO
    }

    /**
      * update data associated with visualization
      */
    override function update(stage : Stage):Void {
        viewport = player.view.rect;
    }

    /**
      * called when [this] gets attached to the media renderer
      */
    override function attached(done : VoidCb):Void {
        super.attached(function(?error) {
            if (error != null) {
                done( error );
            }
            else {
                build_tree( done );
            }
        });
    }

    /**
      * called when [this] gets detached from the media renderer
      */
    override function detached(done : VoidCb):Void {
        context = null;
        source = null;
        destination = null;
        splitter = null;
        merger = null;
        leftAnalyser = null;
        rightAnalyser = null;

        super.detached( done );
    }

	/**
	  * Configure [this] AudioVisualizer
	  */
	public function config(fftSize:Int=2048, smoothing:Float=0.8):Void {
		this.fftSize = fftSize;
		this.smoothing = smoothing;
	}

    /**
      * build out the audio analysis tree
      */
    private function build_tree(done : VoidCb):Void {
        var vizNode = mr.audioManager.createNode({
            init: function(self: Fapn) {
                var m = self.pipeline;
                context = m.context;
                source = m.source;
                destination = m.destination;

                splitter = context.createChannelSplitter( 2 );
                merger = context.createChannelMerger( 2 );
                leftAnalyser = context.createAnalyser();
                rightAnalyser = context.createAnalyser();

                splitter.connect(leftAnalyser, [0]);
                splitter.connect(rightAnalyser, [1]);
                leftAnalyser.connect(merger, [0, 0]);
                rightAnalyser.connect(merger, [0, 1]);

                self.setNode(cast splitter, cast merger);
            }
        });
        mr.audioManager.prependNode( vizNode );
        config();
        done();
    }

/* === Computed Instance Fields === */

    //public var controller(get, never):MediaController;
    //private inline function get_controller():MediaController return renderer.mediaController;

    //public var mediaObject(get, never):MediaObject;
    //@:access( pman.display.media.LocalMediaObjectRenderer )
    //private inline function get_mediaObject():MediaObject return untyped renderer.mediaObject;

    //private var mo(get, never):MediaObject;
    //private inline function get_mo():MediaObject return mediaObject;

    //private var mc(get, never):MediaController;
    //private inline function get_mc():MediaController return controller;

    //private var mr(get, never):Mor;
    //private inline function get_mr():Mor return renderer;

    public var fftSize(get, set):Int;
	private function get_fftSize():Int return leftAnalyser.fftSize;
	private function set_fftSize(v : Int):Int {
	    configChanged = true;
		return (leftAnalyser.fftSize = rightAnalyser.fftSize = v);
	}

	public var smoothing(get, set):Float;
	private function get_smoothing():Float return leftAnalyser.smoothing;
	private function set_smoothing(v : Float):Float {
	    configChanged = true;
	    return (leftAnalyser.smoothing = rightAnalyser.smoothing = v);
    }

/* === Instance Fields === */

    //public var renderer : Mor;
    //public var player : Null<Player> = null;
    //public var viewport : Rect<Float>;

    public var context : AudioContext;
    public var source : AudioSource;
    public var destination : AudioDestination;
    public var splitter : AudioChannelSplitter;
    public var merger : AudioChannelMerger;
    public var leftAnalyser : AudioAnalyser;
    public var rightAnalyser : AudioAnalyser;

    private var configChanged:Bool = false;
}

private typedef Mor = Lmor<MediaObject>;
