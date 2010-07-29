package net.aklabs.demo.simonsays {
	
	import net.aklabs.demo.simonsays.LoadingObject;
	import flash.utils.Dictionary;
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.media.Sound;
	import flash.display.MovieClip;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.Event;
        
	/*
	 * Class Preloader
	 * 
	 * This class is what loads and manages the cache of media assets for the game
	 * This class is a singleton, which was annoyingly difficulty to implement in 
	 * Actionscript 3 because it doesn't support private constructors.
	 *
	 * Be careful subclassing this, because of the way the singleton mechanism was implemented,
	 * it may break. 
	 *
	 * This class can be added as a child asset, and it will display a pair of progress
	 * bars as it loads all the assets. The top bar is the progress on the current file,
	 * the bottom bar is the progress on the total set of assets. You don't have to display the
	 * preloader, but if you do, make sure to load via the assets array, rather than calling loadImage()
	 * and such manually, as the progress bars will act funky.
	 *
	 * When the preloader has loaded all of the assets, it will dispatch a COMPLETE event that should be handled
	 * by whatever higher game class, as a signal that all assets are ready and cached.
	 */

	public class Preloader extends Sprite {
		protected var objects:Dictionary; // this contains all loaded objects, keyed by their handle
		protected var loading_by_instance:Dictionary; // this contains the [handle, bytes read, bytes total] of all objects that are currently loading, keyed by their instance
		protected var loading_by_handle:Dictionary; // this contains the [instance, bytes read, bytes total] of all objects that are currently loading, keyed by their handle
		protected static var instance:Preloader = null; // the singleton instance
		protected var curAsset:Number; // the index of the asset (in the assets array) currently being loaded
		
		protected var assets:Array; // the array of all the assets to be loaded
		/* format of the 'assets' array:
		    [ ASSET_ARRAY, ASSET_ARRAY ...]  
		    
		   each ASSET_ARRAY is...
		   
		    ["images"|"sounds"|"movies", "TEXT HANDLE", "URI", "CLASS NAME"]
		    
		  ... The "images"|"sounds"|"movies" serves an obvious purpose; it says what kind of asset we're loading,
		  as the mechanism for loading images/sounds/movies are different.
		  
		  The TEXT HANDLE is a text handle that can be used when referencing this asset in the preloader
		  
		  The URI is just that, the URI where this object can be found. Usual security restrictions apply.
		  
		  The CLASS NAME is only important for exported SWF movies, and must equal whatever the class name is
		  that you set for that SWF when telling Flash to export it for Actionscript. If this is wrong, or you
		  don't export your SWFs for actionscript, you won't be able to instantiate new MovieClip/Sprites of them.
		  */
		
		protected var loadingLabel:TextField; // just a text label that says "Please wait; loading"
		protected var progressSpinner:Array = new Array("-", "\\", "|", "/"); // an array of characters that creates a spinner for the loading label
		protected var progSpin:Number = 0; // the current index in the progressSpinner array
		protected var classDefs:Dictionary; // classDefs holds the class definitions for each of the given objects (if supplied), keyed by text handle
		protected var classNames:Dictionary; // classNames holds the name of the classes for each of the given objects (if supplied), keyed by text handle

		/*
		 * getInstance()
		 * 
		 * Returns the instance of the singleton
		 *
		 * arguments: none
		 * 
		 * Returns: Preloader
		 */
		public static function getInstance():Preloader
		{
		    if ( Preloader.instance == null )
			Preloader.instance = new Preloader();
                    return Preloader.instance;
		}

		/*
		 * Preloader(assets)
		 *
		 * Default constructor for Preloader
		 * 
		 * arguments:
		 *    @assets:Array, the asset array to be loaded (default null)
		 *
		 * Returns: none
		 */
		public function Preloader(assets:Array = null)
		{
		    if ( Preloader.instance != null )
			throw("Don't use (new Preloader()) directly, use Preloader.getInstance() to prevent duplication of this singleton class.");
		    this.objects = new Dictionary();
		    this.loading_by_instance = new Dictionary();
		    this.loading_by_handle = new Dictionary();
		    Preloader.instance = this;
		    this.curAsset = 0;
		    if ( assets != null) 
			this.assets = assets;
		    var labelFormat = new TextFormat();
		    labelFormat.font = "Courier New";
		    labelFormat.bold = false;
		    labelFormat.color = 0xFFFFFF;
		    labelFormat.size = 12;;
		    this.loadingLabel = new TextField();
		    this.loadingLabel.background = false;
		    this.loadingLabel.autoSize = TextFieldAutoSize.LEFT;
		    this.loadingLabel.defaultTextFormat = labelFormat;
		    this.loadingLabel.text = "Please wait; loading |"
		    this.loadingLabel.x = 0;
		    this.loadingLabel.y = 0;
		    this.addChild(loadingLabel);
		    this.classDefs = new Dictionary();
		    this.classNames = new Dictionary();
		}
		
		/* 
		 * setAssets(assets)
		 *
		 * Set the asset array for the preloader
		 *
		 * arguments:
		 *    @assets:Array, the array of assets
		 * 
		 * returns: none
		 */  
		public function setAssets(assets:Array)
		{
		    this.assets = assets;
		}

		/*
		 * loadAssets()
		 *
		 * Start loading all the assets 
		 *
		 * arguments: none
		 *
		 * returns: none
		 */  
		public function loadAssets()
		{
		    this.onLoadComplete(null);
		}

		/*
		 * getObject(handle)
		 *
		 * Get a generic Object referenced by the given handle
		 *
		 * argument:
		 *    @handle:String, the text handle of the object you want
		 *
		 * returns: object you want, or null
		 */
		public function getObject(handle:String)
		{
		    if ( this.objects[handle] ) 
			return this.objects[handle];
		    return null;
		}
		
		/*
		 * getBitmap(handle:String)
		 *
		 * This function returns a CLONE of a Bitmap object in the preloader. Use this when
		 * you want a bitmap that you can use in more than one place, e.g., more like a sprite.
		 * All instances will reference the same bitmap data, however, so any modification to
		 * the core bitmap data will show up in all instances.
		 *
		 * arguments:
		 *    @handle:String, the text handle reference for the bitmap you want
		 *
		 * returns Bitmap on success, null on failure
		 */
		 
		public function getBitmap(handle:String)
		{
			var obj = this.getObject(handle);
			if ( (obj) && (obj is Bitmap) ) {
				var bm = new Bitmap(obj.bitmapData);
				return bm;
			}
			return obj;
		}

		/*
		 * getBitmap(handle:String)
		 *
		 * This function returns a CLONE of a MovieClip object in the preloader. Use this when
		 * you want a MovieClip that you can use in more than one place, e.g., more like a sprite.
		 * All instances will reference the same frame data, however, so any modification to
		 * the core frame data will show up in all instances.
		 *
		 * arguments:
		 *    @handle:String, the text handle reference for the bitmap you want
		 *
		 * returns MovieClip on success, null on failure
		 */
		public function getMovieClip(handle:String):MovieClip
		{
		    var obj = this.getObject(handle);
		    try {
			var clip:Class = this.classDefs[handle];
			if ( clip ) {
			    return new clip();
			}
		    } catch (error:Error) {
			trace(error);
			return null;
		    }
		    return null;
		}

		/*
		 * startObject(obj, handle)
		 * 
		 * Start loading the given object with the given handle. Sets up event handling for notifications on the event while it loads.
		 *
		 * arguments:
		 *    @obj:Loader|Sound, either a Loader or a Sound object, referencing the object which has already had its URI set and begun loading
		 *    @handle:String, the text string by which this object should be referenced
		 *
		 * returns: none
		 */
		protected function startObject(obj, handle:String)
		{
			var toadd = obj;
			if ( obj is Loader ) {
				toadd = obj.contentLoaderInfo;
			}
		   	toadd.addEventListener(Event.COMPLETE, this.onLoadComplete);
			toadd.addEventListener(ProgressEvent.PROGRESS, this.onProgressUpdate);
			toadd.addEventListener(IOErrorEvent.IO_ERROR, this.onIOError);
			toadd.addEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onSecurityError);
			this.loading_by_instance[toadd] = new Array(handle, 0, 0);
			this.loading_by_handle[handle] = new Array(obj, 0, 0);
		}
		
		/*
		 * stopObject(obj)
		 *
		 * Stops loading on a given object, unhooks all the event listeners, etc
		 * 
		 * arguments:
		 *    @obj:Loader|Sound, the object on which loading should stop
		 *
		 * returns: none
		 */
		protected function stopObject(obj)
		{
			var obj_info = this.loading_by_instance[obj];
			obj.removeEventListener(Event.COMPLETE, this.onLoadComplete);
			obj.removeEventListener(ProgressEvent.PROGRESS, this.onProgressUpdate);
			obj.removeEventListener(IOErrorEvent.IO_ERROR, this.onIOError);
			obj.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, this.onSecurityError);
			delete this.loading_by_handle[this.loading_by_instance[obj][0]];
			delete this.loading_by_instance[obj];			
		}		
		
		/*
		 * getObjectStatus(handle)
		 *
		 * Returns a LoadingObject object that describes the current loading status of the object you're inquiring about
		 * 
		 * arguments:
		 *    @handle:String, the handle of the object you want to know about
		 * 
		 * returns : LoadingObject
		 */
		public function getObjectStatus(handle:String):LoadingObject
		{
			var objStats = new LoadingObject();
			objStats.handle = handle;
			if ( this.objects[handle] ) {
				objStats.state = LoadingObject.STATE_READY;
			} else if ( this.loading_by_handle[handle] ) {
				objStats.state = LoadingObject.STATE_LOADING;
				objStats.bytesRead = this.loading_by_handle[handle][1];
				objStats.bytesTotal = this.loading_by_handle[handle][2];
			}
			return objStats;
		}
		
		/*
		 * loadImage(uri, handle)
		 *
		 * Start loading the image at the given URI with the given handle
		 *
		 * arguments: 
		 *    @uri:String, the URI where the file lives
		 *    @handle:String, the handle for the object 
		 * 
		 * returns: none
		 */  
		public function loadImage(uri:String, handle:String)
		{
		    var request:URLRequest = new URLRequest(uri);
		    var img = new Loader();
		    img.load(request);
		    this.startObject(img, handle);
		}
		
		/*
		 * loadMovie(uri, handle, className)
		 *
		 * Loads an external SWF object from URI and stores it as 'handle' and stores the class definition from it where the class name is className
		 *
		 * arguments:
		 *    @uri:String, the URI where the file lives
		 *    @handle:String, the handle for this object
		 *    @className:String, the name of the SWF class when exported for Actionscript
		 *
		 * returns: none
		 */
		public function loadMovie(uri:String, handle:String, className:String)
		{
		    var request:URLRequest = new URLRequest(uri);
		    var movie = new Loader();
		    movie.load(request);
		    this.startObject(movie, handle);
		    this.classNames[handle] = className;
		    trace(this.classNames[handle]);
		}

		/*
		 * loadSound(uri, handle)
		 * 
		 * Loads the given sound
		 * 
		 * arguments:
		 *    @uri:String, the URI from which to load the sound
		 *    @handle:String, the handle to store the sound as
		 *
		 * returns: none
		 */
		public function loadSound(uri:String, handle:String) 
		{
		    var request:URLRequest = new URLRequest(uri);
		    var snd = new Sound();
		    snd.load(request);
		    this.startObject(snd, handle);
		}
		
		/*
		 * playSound(handle)
		 *
		 * Locates the sound associated with the given handle, and plays it
		 *
		 * arguments:
		 *    @handle:String, the text handle for the sound you want
		 *
		 * returns: Boolean (true on success, false on error)
		 */
		public function playSound(handle:String):Boolean
		{
			var snd = this.getObject(handle);
			if ( !snd ) 
			    return false;
			snd.play(); // we don't care about the channel it returns
			return true;
		}
		
		/*
		 * onIOError(evt)
		 *
		 * This function fires whenever there's an IO Error that prevents the object from finishing loading
		 *
		 * arguments:
		 *    @evt:IOErrorEvent, the event firing this function
		 *
		 * returns: none
		 */
		protected function onIOError(evt:IOErrorEvent)
		{
			var obj = evt.target;
			var obj_info = this.loading_by_instance[obj];
			var handle = obj_info[0];
			var read = obj_info[1];
			var total = obj_info[2];
			this.stopObject(obj);
		}

		/*
		 * onSecurityError(evt)
		 *
		 * This function fires whenever there's a security error that prevents the object from finishing loading
		 *
		 * arguments:
		 *    @evt:SecurityErrorEvent, the event firing this function
		 *
		 * returns: none
		 */
		protected function onSecurityError(evt:SecurityErrorEvent)
		{
			var obj = evt.target;
			var obj_info = this.loading_by_instance[obj];
			var handle = obj_info[0];
			var read = obj_info[1];
			var total = obj_info[2];
			this.stopObject(obj);
		}
		
		/*
		 * onProgressUpdate(evt)
		 *
		 * This function fires whenever there's a progress update on the object currently loading
		 *
		 * arguments:
		 *    @evt:ProgressEvent, the event firing this function
		 *
		 * returns: none
		 */
		protected function onProgressUpdate(evt:ProgressEvent) 
		{
		    var obj = evt.target;
		    var handle = this.loading_by_instance[obj][0];
		    this.loading_by_instance[obj][1] = this.loading_by_handle[handle][1] = evt.bytesLoaded;
		    this.loading_by_instance[obj][2] = this.loading_by_handle[handle][2] = evt.bytesTotal;
		    this.drawProgressMeters(evt);
		    this.progSpin += 1;
		    if ( this.progSpin >= this.progressSpinner.length ) {
			this.progSpin = 0;
		    }
		    this.loadingLabel.text = "Please wait; loading ... " + this.progressSpinner[this.progSpin];
		}
		
		/*
		 * onLoadComplete(evt)
		 *
		 * This function fires whenever a file finishes loading. You can call this, after setting the assets array, with a null event.
		 * In such a case, the loading process will simply be started.
		 *
		 * arguments:
		 *    @evt:Event, the event firing this function (default null)
		 *
		 * returns: none
		 */
		protected function onLoadComplete(evt:Event = null) 
		{			
		    if ( evt != null ) {
			var obj = evt.target;
			var handle = this.loading_by_instance[obj][0];
			if ( obj is LoaderInfo ) {
			    this.objects[handle] = obj.content;
			    trace(this.classNames[handle]);
			    if ( (this.classNames[handle]) && (this.classNames[handle] != "") )
				this.classDefs[handle] = obj.applicationDomain.getDefinition(this.classNames[handle]);
			    else
				this.classDefs[handle] = null;
			} else
			    this.objects[handle] = obj
			this.stopObject(obj);
			this.curAsset += 1;
		    }
		    if ( this.curAsset < this.assets.length ) {
			var asset = this.assets[this.curAsset];
			var asset_stat = this.getObjectStatus(asset[1]);
			if ( asset_stat.state == LoadingObject.STATE_NOTFOUND ) {
			    if ( asset[0] == "sounds" ){
				this.loadSound(asset[2], asset[1]);
			    } else if ( asset[0] == "images" ) {
				this.loadImage(asset[2], asset[1]);
			    } else if ( asset[0] == "movies" ) {
				this.loadMovie(asset[2], asset[1], asset[3]);
			    }
			}
		    } else if ( this.curAsset >= this.assets.length ) {
			var evt = new Event(Event.COMPLETE);
			this.dispatchEvent(evt);
		    }
		}

		/*
		 * drawProgressMeters(evt)
		 *
		 * This function redraws the visible progress meters; it is generally called from inside of onProgressUpdate.
		 * It isn't fired by a timer, but it does need to have the event passed in to it so it can access the bytes read, etc.
		 *
		 * arguments:
		 *    @evt:ProgressEvent, the event firing this function (default null)
		 *
		 * returns: none
		 */
		protected function drawProgressMeters(evt:ProgressEvent)
		{
		    this.graphics.clear();
		    // draw the file progress meter
		    // white box
		    this.graphics.lineStyle(1,0xFFFFFF);
		    this.graphics.beginFill(0xFFFFFF);
		    this.graphics.drawRoundRect(60, 30, 200, 15, 5);
		    this.graphics.endFill();
		    // blue bar
		    this.graphics.lineStyle(1,0x6E6BF4);
		    this.graphics.beginFill(0x6E6BF4);
		    this.graphics.drawRoundRect(60, 30, 200*(evt.bytesLoaded/evt.bytesTotal), 15, 5);
		    this.graphics.endFill();
		    // red box
		    this.graphics.lineStyle(3, 0xAC2626);
		    this.graphics.drawRoundRect(60, 30, 200, 15, 5);
		    // draw the total progress meter
		    // white box
		    this.graphics.lineStyle(1,0xFFFFFF);
		    this.graphics.beginFill(0xFFFFFF);
		    this.graphics.drawRoundRect(60, 60, 200, 15, 5);
		    this.graphics.endFill();
		    // blue bar
		    this.graphics.lineStyle(1,0x6E6BF4);
		    this.graphics.beginFill(0x6E6BF4);
		    this.graphics.drawRoundRect(60, 60, 200*(this.curAsset/this.assets.length), 15, 5);
		    this.graphics.endFill();
		    // red box
		    this.graphics.lineStyle(3, 0xAC2626);
		    this.graphics.drawRoundRect(60, 60, 200, 15, 5);
		}
	}
	
}