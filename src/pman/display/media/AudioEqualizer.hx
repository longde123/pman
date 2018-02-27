package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.graphics.Color;
import tannus.math.Percent;
import tannus.html.Win;

import gryffin.core.*;
import gryffin.display.*;
import gryffin.media.MediaObject;
import gryffin.audio.*;
import gryffin.audio.AudioBiquadFilter;

import pman.core.*;
import pman.media.*;
import pman.display.media.LocalMediaObjectRenderer in Lmor;
import pman.display.media.AudioPipeline;

import electron.Tools.defer;
import Std.*;
import Slambda.fn;
import tannus.math.TMath.*;
import edis.Globals.*;
import pman.Globals.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.html.JSTools;

class AudioEqualizer extends MediaRendererComponent {
    /* Constructor Function */
    public function new():Void {
        super();
    }

/* === Instance Methods === */

    override function attached(done: Void->Void):Void {
        super.attached(function() {
            inline function bq(c:AudioContext, type:BiquadFilterType, frequency:Float, gain:Float):AudioBiquadFilter {
                var n = c.createBiquadFilter();
                n.type = type;
                n.frequency = frequency;
                n.gain = gain;
                return n;
            }
            inline function gn(c:AudioContext, ?gain:Float):AudioGain {
                var n = c.createGain();
                if (gain != null)
                    n.gain = gain;
                return n;
            }

            var eqNode = mr.audioManager.createNode({
                init: function(self: Fapn) {
                    var c = self.pipeline.context;

                    bandSplit = [360, 3600];
                    values = [100.0, 100.0, 100.0];
                    gainDb = -40.0;

                    var _i = gn( c );
                    var sum = gn( c );
                    self.setNode(cast _i, cast sum);

                    var hBand = bq(c, Lowshelf, bandSplit[0], gainDb);
                    var hInvert = gn(c, -1.0);
                    var mBand = gn(c);
                    var lBand = bq(c, Highshelf, bandSplit[1], gainDb);
                    var lInvert = gn(c, -1.0);

                    _i.connect(lBand);
                    _i.connect(mBand);
                    _i.connect(hBand);

                    hBand.connect( hInvert );
                    lBand.connect( lInvert );
                    hInvert.connect( mBand );
                    lInvert.connect( mBand );

                    this.bands = {
                        low: {
                            band: lBand,
                            invert: lInvert
                        },
                        mid: mBand,
                        high: {
                            band: hBand,
                            invert: hInvert
                        }
                    };

                    var lGain = gn( c );
                    var mGain = gn( c );
                    var hGain = gn( c );

                    lBand.connect(lGain);
                    mBand.connect(mGain);
                    hBand.connect(hGain);

                    this.gains = {
                        low: lGain,
                        mid: mGain,
                        high: hGain
                    };

                    lGain.connect(sum);
                    mGain.connect(sum);
                    hGain.connect(sum);

                    self.setNode(cast _i, cast sum);

                    trace('URINAL BETTY YEAH');
                    _expose();
                }
            });

            mr.audioManager.prependNode( eqNode );

            done();
        });
    }

    private function _expose():Void {
        var export = window.expose.bind(_, _);
        var exposed:Dynamic = {};
        window.expose('PManEqualizer', exposed);
        exposed.defineProperties({
            values: { get: cast Getter.create( values ) },
            bandSplit: {get: cast Getter.create(bandSplit)},
            setBandSplit: {value: this.setBandSplit},
            setValues: {value: this.setValues},
            sync: {
                value: (function() {
                    syncConfig();
                })
            }
        });
    }

    /**
      * sync the configuration-related properties with the audio nodes
      */
    public function syncConfig():Void {
        bands.low.band.frequency = bandSplit[0];
        bands.low.band.gain = gainDb;
        bands.high.band.frequency = bandSplit[1];
        bands.high.band.gain = gainDb;

        gains.low.gain = (values[0] / 100.0);
        gains.mid.gain = (values[1] / 100.0);
        gains.high.gain = (values[2] / 100.0);
        trace([gains.low.gain, gains.mid.gain, gains.high.gain]);
    }

    public function setBandSplit(splits: Array<Float>):Void {
        this.bandSplit = splits.copy();
    }

    public function setValues(boosts: Array<Float>):Void {
        values = boosts.copy();
    }

/* === Instance Fields === */

    public var gains: EqualizerGainNodes;
    public var bands: EqualizerBandNodes;

    public var values: Array<Float>;
    public var bandSplit: Array<Float>;
    public var gainDb: Float;
}

typedef EqualizerGainNodes = {
    low: AudioGain,
    mid: AudioGain,
    high: AudioGain
};

typedef EqualizerBand = {band: AudioBiquadFilter, ?invert: AudioGain};
typedef EqualizerBandNodes = {
    low: EqualizerBand,
    mid: AudioGain,
    high: EqualizerBand
};
