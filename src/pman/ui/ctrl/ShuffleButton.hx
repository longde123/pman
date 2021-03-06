package pman.ui.ctrl;

import tannus.io.*;
import tannus.ds.*;
import tannus.geom2.*;
import tannus.events.*;
import tannus.graphics.Color;

import gryffin.core.*;
import gryffin.display.*;

import pman.core.*;
import pman.display.*;
import pman.display.media.*;
import pman.ui.*;
import pman.ui.ctrl.PlayerControlButton;
import tannus.math.TMath.*; import foundation.Tools.*;

using StringTools;
using tannus.ds.StringUtils;
using Lambda;
using tannus.ds.ArrayTools;
using Slambda;
using tannus.ds.AnonTools;

/**
  * button used for toggling fullscreen
  */
class ShuffleButton extends ImagePlayerControlButton {
	/* Constructor Function */
	public function new(c : PlayerControlsView):Void {
		super( c );

		btnFloat = Left;
		name = 'toggle-shuffle';
	}

/* === Instance Methods === */

	// set up the icon data
	override function initIcon():Void {
		_il = Icons.shuffleIcon.with([
		    _(iconSize, iconSize).toImage(),
		    _(iconSize, iconSize, _enabled()).toImage()
		]);
	}

	// get the currently active icon at any given time
	override function getIcon():Image {
		return _il[player.shuffle ? 1 : 0];
	}

    // get the 'glow color'
	//override function getGlowColor():String {
        //return (player.shuffle ? player.theme.secondary.toString() : 'white');
	//}

	// handle click events
	override function click(event : MouseEvent):Void {
		player.shuffle = !player.shuffle;
	}

	override function update(stage: Stage):Void {
	    super.update( stage );

	    enabled = (player.track == null || !player.track.type.equals(MTImage));
	}
}
