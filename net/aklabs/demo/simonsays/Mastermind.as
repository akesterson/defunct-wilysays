package net.aklabs.demo.simonsays 
{
    
    import flash.utils.Timer;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.display.Sprite;
    import net.aklabs.demo.simonsays.Preloader;
    import net.aklabs.demo.simonsays.SimonButton;
    import net.aklabs.demo.simonsays.MastermindEvent;
    
    /*
     * Class: Mastermind
     * 
     * This class defines our "Simon Says", "Wily Lok", "Mastermind", whatever you want to call it.
     * (I called it 3 or 4 different things during the course of development.)
     *
     */
    public class Mastermind extends Sprite
    {
	protected var lightOutTimer:Timer; // timer that fires when it's time to turn off the lights
	protected var lightButtons:Array; // array of custom SimonButtons that exists in Pattern.COLOR_XXX order
	public var isLit:Boolean; // is the device currently lit?
        
	public function Mastermind()
	{
	    var preloader = Preloader.getInstance();
	    var lightPositions = new Array();
	    // this array holds pairs of (x,y) coordinates at which to place the dark/light colored
	    // Simon Says buttons, since they're meant to cover the existing buttons on the original graphic.
	    // These are hard-coded; in a better implementation, they would come from an XML or would be
	    // individual frames of an SWF which could be fired individually, etc. But this works.
	    // array idx 0: Blue, 1: Green, 2: Red, 3: Yellow

	    lightPositions.push( new Array(183, 187)); // blue
	    lightPositions.push( new Array(18,  17)); // green
	    lightPositions.push( new Array(185, 17)); // red
	    lightPositions.push( new Array(18,  186)); // yellow

	    // this array holds the button objects for the visible simon says buttons ... 
	    this.lightButtons = new Array();
	    // just a temporary array for which images to fetch for creating the down/up button images
            var fetchArray = new Array( new Array("gfx_btn_darkblue", "gfx_btn_lightblue"),
					new Array("gfx_btn_darkgreen", "gfx_btn_lightgreen"),
					new Array("gfx_btn_darkred", "gfx_btn_lightred"),
					new Array("gfx_btn_darkyellow", "gfx_btn_lightyellow") );
	    // Simon Says body
	    var whole = preloader.getObject("gfx_mastermind");
	    this.addChild(whole);

	    for ( var i = 0; i < fetchArray.length ; i++ ) {
		var btn:SimonButton = new SimonButton(preloader.getObject(fetchArray[i][1]), preloader.getObject(fetchArray[i][0]));
		btn.x = lightPositions[i][0];
		btn.y = lightPositions[i][1];
		this.lightButtons.push(btn);
		this.addChild(btn);
		btn.addEventListener(MouseEvent.CLICK, this.onMouseClick); // for some reason, MouseEvent.CLICK never actually does anything?
		//btn.addEventListener(MouseEvent.MOUSE_UP, this.onMouseClick);
	    }
	    this.lightOutTimer = new Timer(0);
	}

	/*
	 * flashAll(length)
	 *
	 * This function lights all the lights on the Mastermind for the given length of time
	 *
	 * arguments:
	 *    @length:Number, the time in milliseconds for which the Mastermind should stay lit
	 *
	 * Returns : none
	 */
	public function flashAll(length:Number)
	{
	    this.lightOutTimer.delay = length;
	    this.lightOutTimer.addEventListener(TimerEvent.TIMER, this.onTimer);
	    this.lightOutTimer.reset();
	    this.lightOutTimer.start();
	    for (var i = 0 ; i < 4 ; i++) {
		// fake mouse event to light it up
		this.lightButtons[i].onMouseDown(null);
	    }
	    this.isLit = true;
	}

	/*
	 * lightButton(btn, activeTime)
	 *
	 * This function lights up a given button on the Mastermind. Mostly used by the Pattern when it's replaying itself.
	 *
	 * arguments:
	 *    @btn:Number, the Pattern.COLOR_XXX button that should light
	 *    @activeTime:Number, the amount of milliseconds for which the button should stay lit
	 *
	 * Returns : none
	 */
	public function lightButton(btn:Number, activeTime:Number = 0 )
	{
            if ( btn < 4 ) {
		this.lightButtons[btn].onMouseDown(null);
		this.isLit = true;
	    }
	    if ( activeTime != 0 ) {
		this.lightOutTimer.delay = activeTime;
		this.lightOutTimer.addEventListener(TimerEvent.TIMER, this.onTimer);
		this.lightOutTimer.reset();
		this.lightOutTimer.start();
	    }
	}

	/*
	 * blackout()
	 *
	 * This function makes sure that all lights on the Mastermind are extinguished 
	 * 
	 * arguments : none
	 * 
	 * Returns : none
	 */
	public function blackout()
	{
	    if ( this.lightButtons.length <= 0 ) {
		return;
	    }
	    for ( var i = 0 ; i < this.lightButtons.length ; i++ ){
		this.lightButtons[i].onMouseUp(null);
	    }
	    this.isLit = false;
	}

	/* 
	 * onTimer(evt)
	 * 
	 * This function fires whenever the lightOutTimer fires, telling the lights to shut off
	 * 
	 * arguments : 
	 *    @evt:Event, the event that's firing this function
	 *
	 * Returns : none
	 */
	public function onTimer(evt:TimerEvent)
	{
	    if ( evt.target != this.lightOutTimer )
		return;
	    this.lightOutTimer.removeEventListener(TimerEvent.TIMER, this.onTimer);
	    this.lightOutTimer.stop();
	    this.lightOutTimer.reset();
	    this.blackout();
	}

	/*
	 * onMouseClick()
	 * 
	 * This function is fired whenever the user clicks one of the Mastermind's buttons
	 *
	 * arguments:
	 *    @evt:Event, the event firing this function
	 *
	 * Returns : none
	 */
	public function onMouseClick(evt:MouseEvent)
	{
	    // we don't do any processing here, as the SimonButton has already checked for 
	    // per-pixel accuracy w/ the click on our abnormally shaped buttons. We just propagate
	    // out a new MastermindEvent for the game to catch.
	    for ( var i:Number = 0; i < this.lightButtons.length ; i++ ) {
		if ( evt.target == this.lightButtons[i] ) {
		    var newEvt:MastermindEvent = new MastermindEvent(MastermindEvent.BTN_CLICKED);
		    newEvt.colorClicked = i;
		    this.dispatchEvent(newEvt);
		}
	    }
	}
    }
}  
