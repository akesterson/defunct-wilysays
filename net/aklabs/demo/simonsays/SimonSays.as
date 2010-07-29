package net.aklabs.demo.simonsays 
{
    
    import flash.utils.Timer;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import net.aklabs.demo.simonsays.Preloader;
    
    public class Mastermind
    {
	protected var lightOutTimer:Timer;
	protected var lightBitmaps:Array;
        
	public function Mastermind(preloader:Preloader, screenX:Number = 0, screenY:Number = 0)
	{
	    // pass in a preloader so the class knows where to get its resources
	    var lightPositions = new Array();
	    // this array holds pairs of (x,y) coordinates at which to place the dark/light colored
	    // Simon Says buttons, since they're meant to cover the existing buttons on the original graphic.
	    // These are hard-coded; in a better implementation, they would come from an XML or would be
	    // individual frames of an SWF which could be fired individually, etc. But this works.
	    // array idx 0: Blue, 1: Green, 2: Red, 3: Yellow
	    lightPositions.push( new Array(screenX + 216, screenY + 220)); // blue
	    lightPositions.push( new Array(screenX + 22,  screenY + 20)); // green
	    lightPositions.push( new Array(screenX + 218, screenY + 20)); // red
	    lightPositions.push( new Array(screenX + 22,  screenY + 218)); // yellow
	    // this array holds the light/dark bitmaps for the simon says buttons ... each idx is an array which holds (dark, light) bitmap objects
	    // the indexes (0-3) correspond to the above for colors
	    this.lightBitmaps = new Array();
            var fetchArray = new Array( new Array("gfx_btn_darkblue", "gfx_btn_lightblue"),
					new Array("gfx_btn_darkgreen", "gfx_btn_lightgreen"),
					new Array("gfx_btn_darkred", "gfx_btn_lightred"),
					new Array("gfx_btn_darkyellow", "gfx_btn_lightyellow") );
	    for ( var i = 0; i < fetchArray.length ; i++ ) {
		light = preloader.getObject(fetchArray[i][0]);
		dark = preloader.getObject(fetchArray[i][1]);
		light.x = lightPositions[i][0];
		light.y = lightPositions[i][1];
		dark.x = lightPositions[i][0];
		dark.y = lightPositions[i][1];
                // we don't check the return values here because the preloader shouldn't even fire
		// the application up if resources are missing
		this.lightBitmaps.push(new Array(light, dark));
		// the dark buttons are always there, the lighted ones are just temporarily overlain on them for effect
		addChild(dark);
	    }
	    whole = preloader.getObject("gfx_background");
	    whole.x = screenX;
	    whole.y = screenY;
	    addChild(whole);

	    this.lightOutTimer = Timer(1000);
	    this.lightOutTimer.addEventListener(TimerEvent.TIMER, this.onTimer);
	    this.lightOutTimer.start();
	} 

	public function flashAll(length:Number)
	{
	    this.lightOutTimer.reset();
	    this.lightOutTimer.delay(length);
	    this.lightOutTimer.start();
	}

	public function lightButton(btn:Number, activeTime:Number)
	{
            if ( btn < 4 ) {
		this.lightOutTimer.reset();
		this.lightOutTimer.delay(activeTime);
		addChild(this.lightBitmaps[btn][0]);
		this.lightOutTimer.start();
	    }
	}

	public function onTimer(evt:TimerEvent);
	{
	    for ( i = 0 ; i < this.lightBitmaps.length ; i++ ){
		removeChild(this.lightBitmaps[i][0]);
	    }
	}
    }
}
