package ;

import tannus.io.*;
import tannus.ds.*;
import tannus.math.Random;
import tannus.graphics.Color;
import tannus.node.ChildProcess;
import tannus.sys.*;

import crayon.*;

import electron.ext.*;
import electron.ext.Dialog;
import electron.ext.MenuItem;
import electron.Tools.defer;

import pman.core.*;
import pman.ui.*;
import pman.db.*;
import pman.events.*;
import pman.media.*;
import pman.ww.Worker;
import pman.ipc.RendererIpcCommands;

import Std.*;
import tannus.internal.CompileTime in Ct;
import tannus.TSys as Sys;

using StringTools;
using tannus.ds.StringUtils;
using tannus.ds.ArrayTools;
using Lambda;
using Slambda;

class BPlayerMain extends Application {
	/* Constructor Function */
	public function new():Void {
		super();

		_ready = false;
		_rs = new VoidSignal();
		_rs.once(function() {
		    _ready = true;
		});

		win.expose('main', this);

		if (instance == null) {
		    instance = this;
		}
        else {
            throw 'Error: Only one instance of BPlayerMain can be constructed';
        }
	}

/* === Instance Methods === */

    /**
      * initialize [this] shit
      */
    private function init(cb : Void->Void):Void {
        onready( cb );


        // need to find a better way to do this
		browserWindow = BrowserWindow.getAllWindows()[0];

        appDir = new AppDir();

        db = new PManDatabase();
        db.init(function() {
            _rs.fire();
        });
    }

	/**
	  * start the Application
	  */
	@:access( pman.db.StoredModel )
	override function start():Void {
		title = 'BPlayer';

		playerPage = new PlayerPage( this );

		body.open( playerPage );

		keyboardCommands = new KeyboardCommands( this );
		keyboardCommands.bind();

		dragManager = new DragDropManager( this );
		dragManager.init();

		//__buildMenus();
        ipcCommands = new RendererIpcCommands( this );
        ipcCommands.bind();
	}

	/**
	  * quit this shit
	  */
	public inline function quit():Void {
		App.quit();
	}

    /**
      * send command to the main process, telling it to update the application menu
      */
	public inline function updateMenu():Void {
	    ic.send('UpdateMenu');
	}

	/**
	  * display an error message
	  */
	public inline function errorMessage(error : Dynamic):Void {
		player.message({
			text: Std.string( error ),
			color: new Color(255, 0, 0),
			fontSize: '10pt'
		});
	}

	/**
	  * create and display FileSystem prompt
	  */
	public inline function fileSystemPrompt(options:FSPromptOptions, callback:Array<String>->Void):Void {
		Dialog.showOpenDialog(_convertFSPromptOptions(_fillFSPromptOptions( options )), function(paths : Null<Array<String>>):Void {
		    if (paths == null) {
		        paths = [];
		    }

			var mr:Null<String> = paths.last();
			if (mr != null) {
			    trace('lastDirectory: $mr');
			    db.configInfo.lastDirectory = mr;
			}

			callback( paths );
		});
	}

	/**
	  * create and display a FileSystem 'save' dialog
	  */
	public function fileSystemSavePrompt(?options:FSSPromptOptions, ?callback:Null<Path>->Void):Void {
	    if (options == null) options = {};
	    Dialog.showSaveDialog(_convertFSSPromptOptions(options), function(name : Null<String>) {
	        var path:Null<Path> = (name != null ? new Path( name ) : null);
	        if (options.complete != null) {
	            options.complete( path );
	        }
	        if (callback != null) {
	            callback( path );
	        }
	    });
	}

	/**
	  * fill in missing fields on FSPromptOptions
	  */
	private function _fillFSPromptOptions(o : FSPromptOptions):FSPromptOptions {
		if (o.directory == null)
			o.directory = false;
		if (o.title == null)
			o.title = 'BPlayer FileSystem Prompt';
		return o;
	}

	/**
	  * convert FSPromptOptions to FileOpenOptions
	  */
	private function _convertFSPromptOptions(o : FSPromptOptions):FileOpenOptions {
		var res:FileOpenOptions = {
			title: o.title,
			buttonLabel: o.buttonLabel,
			defaultPath: o.defaultPath,
			filters: o.filters,
			properties: (o.directory ? [OpenDirectory] : [OpenFile, MultiSelections])
		};
		if (res.defaultPath == null) {
		    res.defaultPath = db.configInfo.lastDirectory;
		}
		return res;
	}

	private function _convertFSSPromptOptions(o : FSSPromptOptions):FileDialogOptions {
	    var res:FileDialogOptions = {
            title: o.title,
            buttonLabel: o.buttonLabel,
            defaultPath: o.defaultPath,
            filters: o.filters
	    };
	    if (res.defaultPath == null) {
	        res.defaultPath = db.configInfo.lastDirectory;
	    }
	    return res;
	}

	/**
	  * ensure that the app has been initialized before running [task]
	  */
	public function onready(task : Void->Void):Void {
	    if ( _ready ) {
	        defer( task );
	    }
        else {
            _rs.once( task );
        }
	}

	/**
	  * process the given LaunchInfo
	  */
	public function launchInfo(info : LaunchInfo):Void {
	    trace( info );
	}

/* === Compute Instance Fields === */

    // reference to the Player object
	public var player(get, never):Player;
	private inline function get_player():Null<Player> {
	    return (playerPage != null ? playerPage.player : null);
    }

    public var ic(get, never):RendererIpcCommands;
    private inline function get_ic() return ipcCommands;

/* === Instance Fields === */

	public var playerPage : Null<PlayerPage>;
	public var browserWindow : BrowserWindow;
	public var keyboardCommands : KeyboardCommands;
	public var appDir : AppDir;
	public var db : PManDatabase;
	public var dragManager : DragDropManager;
	public var tray : Tray;
	public var ipcCommands : RendererIpcCommands;

	private var _ready : Bool;
	// ready signal
	private var _rs : VoidSignal;

/* === Class Methods === */

	/* main function */
	public static function main():Void {
	    var app = new BPlayerMain();
	    app.init( app.start );
	}

/* === Static Fields === */

    public static var instance : Null<BPlayerMain> = null;
}

typedef FSSPromptOptions = {
    ?title:String,
    ?defaultPath:String,
    ?buttonLabel:String,
    ?filters:Array<FileFilter>,
    ?complete:Null<Path>->Void
};

typedef FSPromptOptions = {
	?title:String,
	?defaultPath:String,
	?buttonLabel:String,
	?filters:Array<FileFilter>,
	?directory:Bool
};

typedef LaunchInfo = {
    argv: Array<String>,
    env: Object
};
