package pman.display.media;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.sys.*;
import tannus.async.*;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.bg.media.*;
import pman.media.*;

import edis.Globals.*;
import Std.*;
import tannus.math.TMath.*;

using tannus.math.TMath;
using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.async.Asyncs;

class LocalImageRenderer extends MediaRenderer {
    /* Constructor Function */
    public function new(m:Media, c:MediaController):Void {
        super( m );

        mediaController = c;
        if ((mediaController is LocalImageMediaDriver)) {
            var imd = cast(mediaController, LocalImageMediaDriver);
            this.i = imd.i;
        }
        else {
            throw 'WTF';
        }
        vr = new Rect();
    }

/* === Instance Methods === */

    override function render(stage:Stage, c:Ctx):Void {
        c.drawComponent(i, 0, 0, i.width, i.height, vr.x, vr.y, vr.width, vr.height);
    }

    override function update(stage: Stage):Void {
        super.update( stage );

        var imgSize:Rect<Float> = new Rect(0.0, 0.0, 0.0 + i.width, 0.0 + i.height);
        var viewport = pv.rect.clone();
        var scale:Float = (marScale(imgSize, pv.rect) * pv.player.scale);

        vr.width = (imgSize.width * scale);
        vr.height = (imgSize.height * scale);
        vr.centerX = viewport.centerX;
        vr.centerY = viewport.centerY;
    }

    /**
	  * scale to the maximum size that will fit in the viewport AND maintain aspect ratio
	  */
	private inline function marScale(src:Rect<Float>, dest:Rect<Float>):Float {
		return min((dest.width / src.width), (dest.height / src.height));
	}

    /**
      * deallocate [this] from memory entirely
      */
    override function dispose(cb: VoidCb):Void {
        if (i != null) {
            @:privateAccess i.img.remove();
        }
        i = null;
        super.dispose( cb );
    }

    override function onAttached(pv:PlayerView, cb:VoidCb):Void {
        this.pv = pv;

        super.onAttached(pv, cb);
    }

    override function onDetached(pv: PlayerView, cb:VoidCb):Void {
        pv = null;

        super.onDetached(pv, cb);
    }

/* === Instance Fields === */

    public var i: Null<Image>;
    public var vr: Rect<Float>;

	private var pv : Null<PlayerView> = null;
}
