package net.aklabs.demo.simonsays
{
    import flash.utils.Timer;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.events.EventDispatcher;
    import flash.display.Sprite;
    import flash.display.Bitmap;
    import net.aklabs.demo.simonsays.Mastermind;
    import net.aklabs.demo.simonsays.Powerup;
    import net.aklabs.demo.simonsays.PowerupEvent;
    import net.aklabs.demo.simonsays.Preloader;
    
    /*
     * Class Pattern
     *
     * This class defines a "pattern", which is where most of the game challenge exists.
     * It just defines the pattern currently being traced out on the Simon Says/Mastermind/etc
     *
     * In addition to doing processing, this class also does some graphical representation,
     * in the way of a series of red/green lights to show how far along the player is inside the
     * pattern. The image is 16 pixels wide, and (16*maxSize) pixels tall.
     *
     */
    public class Pattern extends Sprite
    {
	public static var COLOR_BLUE:Number = 0;
	public static var COLOR_GREEN:Number = 1;
	public static var COLOR_RED:Number = 2;
	public static var COLOR_YELLOW:Number = 3;
	
	protected var patternTimer:Timer; // timer that fires to check pattern logic independently of game timer
	protected var curIndex:Number; // amount of the pattern currently finished
	protected var pattern:Array;  // the array of colors that make up the actual pattern
	protected var simon:Mastermind; // A link back up to the parent Mastermind (put here because I didn't want to assume that this.parent would always be correct)
	protected var delay:Number; // The number of milliseconds that should pass before the logic timer fires
	protected var playCount:Number; // The number of times this pattern has been played through (via Forgiveness). Not currently used for anything.
	public var clearTime:Number; // the amount of time the player has (in milliseconds) to finish the pattern
	public var state:Number; // state of the pattern at current
	public static var STATE_RUNNING = 0; // STATE : pattern is currently "running" - e.g., waiting for input from the player and checking logic
	public static var STATE_DEMO = 1; // STATE : pattern is currently "demoing", e.g., flashing the lights up to this.curIndex of the pattern
	public static var STATE_FAILED = 2; // STATE : pattern is stopped and the player screwed up
	public static var STATE_CORRECT = 3; // STATE : pattern is stopped and the player got the last iteration correct
	public static var STATE_STOPPED = 4; // STATE : pattern is just stopped w/ no further info
	public static var STATE_COMPLETE = 5; // STATE : pattern is stopped because the player has finished all iterations of this pattern
	public var score:Number; // Score currently built up in this pattern
	protected var maxSize:Number; // Maximum length of the pattern
	public var patternPowerups:Array; // array of powerups assigned to any given button on this pattern
	protected var scoreMultiplier:Number; // Set by powerup, the multiplier for current score (default x1)
	protected var clearDecrement:Number; // Set by powerup, defines how quickly the pattern's timer runs
	protected var progressLights:Array; // An array of bitmaps equal in length to the pattern; all the lights up to this.curIndex will be green, the rest are red
	protected var level:Number; // The level of pattern which this is (mainly used for calculating pattern length, could probly be scrapped)
	protected var difficulty:Number; // The difficulty of the pattern (used in calculating timer speed)

	/* 
	 * Pattern()
	 * 
	 * Default constructor
	 *
	 * arguments:
	 *    @levelNumber:Number, the level number for which this pattern is being made
	 *    @simon:Mastermind, the Mastermind object to which this pattern is to be applied (default null)
	 *    @difficulty:Number, the difficulty level for this pattern (default 1)
	 *
	 * Returns: Pattern
	 */
	public function Pattern(levelNumber:Number, simon:Mastermind = null, difficulty:Number = 1)
	{
	    this.state = 0;
	    this.simon = simon;
	    this.level = levelNumber;
	    this.difficulty = difficulty;
	    this.curIndex = -1;
	    this.maxSize = 2+levelNumber; // smallest pattern will never be less than 3 lights total
	    this.pattern = new Array();
	    this.patternPowerups = new Array();
	    this.progressLights = new Array();
	    this.patternTimer = null;
	    this.delay = 1000;
	    this.playCount = 0;
	    this.clearTime = 0;
	    this.score = 0;
	    this.scoreMultiplier = 1;
	    this.clearDecrement = 0;
	    this.patternTimer = new Timer(0);
	    
	    this.addEventListener(PowerupEvent.USED_POWERUP, this.onUsedPowerup);
	    
	    var preloader:Preloader = Preloader.getInstance();
	    var newLight:Bitmap;
	    // populate all the red lights for this pattern that will turn green as the player goes on
	    for ( var i:Number = 0; i < this.maxSize ; i++ ) {
		newLight = preloader.getBitmap("gfx_progress_red");
		newLight.x = 0;
		newLight.y = i*16;
		if ( i > 15 ) {
		    newLight.x += 20;
		    newLight.y = (i-15)*16;
		}
		this.progressLights.push(newLight);
		this.addChild(newLight);
	    }
	    this.complexify();
	}
	
	/*
	 * patternLength()
	 * 
	 * Just a getter for the length of the pattern
	 *
	 * arguments : none
	 * 
	 * Returns : Number
	 */
	public function patternLength():Number
	{
	    return this.pattern.length;
	}

	/*
	 * forceState()
	 * 
	 * Forces a given state onto the pattern
	 *
	 * arguments: none
	 *
	 * Returns : none
	 */
	public function forceState(state:Number)
	{
	    this.state = state;
	}

	/*
	 * complexify()
	 *
	 * This function adds another element to the pattern, so that it becomes a longer pattern, up until the maximum length of the pattern
	 * 
	 * arguments: none
	 * 
	 * Returns : none
	 */
	public function complexify()
	{
	    // we're complete if we're beyond the maximum size
	    if ( this.pattern.length >= this.maxSize ) {
		this.stop();
		this.state = Pattern.STATE_COMPLETE;
		return null;
	    }
	    // reset the score multiplier and such 'cause complexify only gets called at the end of a round
	    this.scoreMultiplier = 1;
	    this.state = Pattern.STATE_STOPPED;
	    this.stop(); // -- wtf why did I call stop on myself? ...
	    var newcolor = (Math.round(int(Math.random()*4)));
	    this.pattern.push(newcolor);
	    // create a new powerup ~20% of the time that complexify is ran
	    if ( Math.random() < 0.20 ) {
		var powerup = new Powerup();
		powerup.pType = (Math.round(int(Math.random()*Powerup.PTYPE_MAXVALUE)));
		powerup.imgHandle = Powerup.POWERUP_IMAGES[powerup.pType];
		powerup.sndHandle = Powerup.POWERUP_SOUNDS[powerup.pType];
		this.patternPowerups.push(powerup);
	    } else {
		this.patternPowerups.push(null);
	    }
	    this.clearTime = 2000 * ( this.pattern.length );
	}

	/*
	 * play(lightSimon)
	 *
	 * This function tells the pattern to start playback in one of two modes; demo, or running. Demo mode
	 * just has the pattern playing itself back via the lights on the Mastermind. The running mode doesn't
	 * do any playback, it just checks logic.
	 *
	 * arguments:
	 *    @lightSimon:Boolean, set this to True to run in Demo mode (default false)
	 *
	 * Returns : none
	 */
	public function play(lightSimon:Boolean = false)
	{
	    if ( this.patternTimer ) {
		this.patternTimer.reset()
	    } else {
		this.patternTimer = new Timer( this.delay );
	    }
	    if ( lightSimon ){
		this.state = Pattern.STATE_DEMO;
		this.patternTimer.delay = 1000;
		this.patternTimer.addEventListener(TimerEvent.TIMER, this.onDemoTimer);
	    } else {
		this.state = Pattern.STATE_RUNNING;
		this.patternTimer.delay = 25;
		this.clearDecrement = this.patternTimer.delay + (this.level*(this.difficulty));
		this.patternTimer.addEventListener(TimerEvent.TIMER, this.onRunningTimer);
	    }
	    this.patternTimer.start(); 
	    this.playCount += 1;
            this.curIndex = 0;
	}

	/*
	 * stop()
	 * 
	 * Stop all logic/running status on the pattern
	 * 
	 * arguments: none
	 * 
	 * Returns : none
	 */
	public function stop()
	{
	    if ( this.patternTimer ) {
		this.patternTimer.removeEventListener(TimerEvent.TIMER, this.onDemoTimer);
		this.patternTimer.removeEventListener(TimerEvent.TIMER, this.onRunningTimer);
	    }
	    this.curIndex = -1;
	}
	
	/*
	 * getIndex()
         *
	 * Gets the current value is curIndex
	 * 
	 * arguments: none
	 * 
	 * Returns : none
	 */

	public function getIndex()
	{
	    return this.curIndex;
	}

	/*
         * getActive()
	 * 
	 * OBSOLETE - gets the currecntly active color. This isn't as useful since the input checking method changed around v0.12.
	 *
	 * arguments: none
	 * Returns : Number, -1 on failure, >= 0 on success
	 */
	public function getActive()
	{
	    if ( (this.curIndex < this.pattern.length) && (this.curIndex >= 0) ) {
		return this.pattern[this.curIndex];
	    }
	    return -1;
	}

	/*
	 * resetLights()
	 *
	 * This function makes sure the ratio of red:green lights in the progress lights is correct
	 * according to the value of curIndex
	 *
	 * arguments: none
	 *
	 * Returns: none
	 */
	public function resetLights()
	{
	    var preloader:Preloader = Preloader.getInstance();
	    var newLight:Bitmap;
	    for ( var i:Number = 0; i <= this.curIndex ; i++ ) {
		// remove any existing red lights and replace them with green lights
		// if they're at an index < curIndex
		this.removeChild(this.progressLights[i]);
		newLight = preloader.getBitmap("gfx_progress_green");
		newLight.x = this.progressLights[i].x;
		newLight.y = this.progressLights[i].y;
		this.progressLights[i] = newLight;
		this.addChild(this.progressLights[i]);
	    }
	}

	/*
	 * colorActive(color)
	 * 
	 * Checks to see if the given color is the one currently active on the pattern.
	 * Also updates the current index, modifies state, etc, depending on the result.
	 *
	 * arguments:
	 *    @color:Number, the Pattern.COLOR_XXX color you want checked
	 * 
	 * Returns: Boolean (Always returns false on a stopped pattern)
	 */
	public function colorActive(color:Number):Boolean
	{
	    if ( this.curIndex == -1 ) {
		return false;
	    }
	    if ( (this.curIndex < this.pattern.length) && (this.pattern[this.curIndex] == color) ) {
		// dispatch a PowerupEvent if there is a powerup in this spot at the pattern
		if ( this.patternPowerups[this.curIndex] != null ) {
		    this.dispatchEvent(new PowerupEvent(PowerupEvent.GOT_POWERUP, this.patternPowerups[this.curIndex]));
		    this.patternPowerups[this.curIndex] = null;
		}
		this.resetLights();
		this.curIndex += 1;
		this.score += 5;
		if ( this.curIndex >= this.pattern.length ) {
		    this.curIndex = -1;
		    this.state = Pattern.STATE_CORRECT;
		    this.stop();
		}
		return true;
	    }
	    this.state = Pattern.STATE_FAILED;
	    this.stop();
	    return false;
	}

	/*
	 * onRunningTimer(evt)
	 * 
	 * Fires along w/ the runningTimer to check pattern logic
	 *
	 * arguments:
	 *    @evt:Event, event firing this function
	 * 
	 * Returns : none
	 */ 
	 
	public function onRunningTimer(evt:TimerEvent)
	{
	    if ( (!evt) || (evt.target != this.patternTimer) ) 
		return;
	    this.clearTime -= this.clearDecrement;
	    if ( this.clearTime < 0 ) {
		this.clearTime = 0;
		this.state = Pattern.STATE_FAILED;
		this.stop();
	    }
	}

	/*
	 * onDemoTimer(evt)
	 *
	 * Runs every time the Demo timer fires, lighting the buttons in sequence at the right times
	 *
	 * arguments:
	 *    @evt:Event, the event firing this function
	 * 
	 * Returns : none
	 */

	public function onDemoTimer(evt:TimerEvent)
	{
	    if ( (!evt) || (evt.target != this.patternTimer) || (!this.simon) )
		return;
	    if ( this.curIndex >= this.pattern.length ) {
		this.state = Pattern.STATE_STOPPED;
		this.stop();
		return;
	    } 
	    this.simon.lightButton(this.pattern[curIndex], this.patternTimer.delay/2);
	    this.curIndex += 1;
	}

	/*
	 * onUsedPowerup(evt)
	 *
	 * This function fires whenever a PowerupEvent filters down from the Mastermind, which originally
	 * filtered up from the Player. It processes and applies the effects of any powerups used by the player.
	 *
	 * arguments: 
	 *    @evt:PowerupEvent, the event firing this function
	 *
	 * Returns: none
	 */
	public function onUsedPowerup(evt:PowerupEvent)
	{
	    var pwup:Powerup = evt.pwup;
	    if ( pwup.pType == Powerup.PTYPE_FORGIVENESS ) {
		// we don't actually have to *do* anything with a forgiveness ...
		return;
	    } else if ( pwup.pType == Powerup.PTYPE_SLOWDOWN ) {
		this.clearDecrement = 1;
	    } else if ( pwup.pType == Powerup.PTYPE_SKIP ) {
		this.state = Pattern.STATE_CORRECT;
		this.stop();
		this.resetLights();
	    } else if ( pwup.pType == Powerup.PTYPE_DOUBLE ) {
		this.scoreMultiplier = 2;
	    }
	    return;
	}
    }
}	

