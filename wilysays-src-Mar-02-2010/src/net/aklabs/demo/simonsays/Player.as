package net.aklabs.demo.simonsays
{
    import net.aklabs.demo.simonsays.PowerupEvent;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import net.aklabs.demo.simonsays.Preloader;
    import flash.display.Bitmap;

    /*
     * Class Player
     * 
     * This class represents the player in the game.
     *
     * The class has two displayable objects in it: the Player object itself,
     * and Player.lifeDisplay. The Player object displays the inventory (64 pixels high, up to (64*5) pixels wide)
     * The Player.lifeDisplay object displays the remaining number of lives (64 pixels high, up to 64*3 pixels wide)
     *
     */
    public class Player extends Sprite {
	public var score:Number; // the player's current score
	public var lives:Number; // the number of lives the player currently has
	public var maxPattern:Number; // the largest pattern the player has completed
	public var inventory:Array; // the player's inventory
	public var lifeDisplay:Sprite; /* the parent sprite to which all the player life sprites are attached (number of remaining lives) ..
	    we have this parenting the rest of the images, so the Game class can just add this single child object, rather than tracking
	    and removing all the images in the individual lifeImages array */
	protected var lifeImages:Array; // an array of images holding all the images showing up in the player's life array
	protected var headExplosion;

	/*
	 * Player()
	 *
	 * Default constructor
	 * 
	 * arguments : none
	 * 
	 * Returns : none
	 */
	public function Player()
	{
	    this.score = 0;
	    this.lives = 3;
	    this.maxPattern = 0;
	    this.inventory = new Array();
	    this.lifeDisplay = new Sprite();
	    this.lifeImages = new Array();
	}

	/*
	 * addPowerup(pwup)
	 *
	 * Adds a new powerup to the player's inventory
	 *
	 * arguments: 
	 *    @pwup:Powerup, the powerup to be added
	 *
	 * Returns: none
	 */
	public function addPowerup(pwup:Powerup)
	{
	    if ( this.inventory.length >= 5 ) {
		return;
	    }
	    this.inventory.push(pwup);
	    this.resetPowerupPositions();
	    this.addChild(pwup);
	    pwup.addEventListener(MouseEvent.MOUSE_UP, this.onPowerupClicked);
	}

	/*
	 * resetPowerupPositions()
	 *
	 * This function goes through the player's inventory and makes sure the positions line up (mostly) with the background graphic for their slot
	 *
	 * arguments: none
	 *
	 * Returns: none
	 */
	protected function resetPowerupPositions()
	{
	    for ( var i = 0; i < this.inventory.length ; i++ ) {
		var pwup:Powerup = this.inventory[i];
		pwup.x = 2+(70*i);
		pwup.y = 0;
	    }
	}

	/*
	 * die()
	 * 
	 * This function is called whenever the player should die - lose a life
	 * 
	 * arguments: none
	 * 
	 * Returns: none
	 */
	public function die()
	{
	    // lose a life, and do it in style
	    var preloader:Preloader = Preloader.getInstance();
	    this.headExplosion = preloader.getMovieClip("movie_explosion");
	    this.headExplosion.addEventListener(Event.ENTER_FRAME, this.stopExplosion);
	    this.headExplosion.x = (this.lives * 64)-32;
	    this.headExplosion.y = 32;
	    this.lifeDisplay.addChild(this.headExplosion);
	    this.headExplosion.play();
	    preloader.playSound("sfx_explosion");
	    this.lives -= 1;
	    this.resetLifePositions();
	}

	/*
	 * stopExplosion(evt)
	 *
	 * This stops the head explosion animation from looping (much like Game.onNonLoopEnterFrame)
	 *
	 * arguments: 
	 *    @evt:Event, the event firing this function
	 *
	 * Returns: none
	 */
	public function stopExplosion(evt:Event)
	{
	    if ( evt.target.currentFrame == evt.target.totalFrames ) {
		this.headExplosion.stop();
		this.lifeDisplay.removeChild(this.headExplosion);
		this.headExplosion.removeEventListener(Event.ENTER_FRAME, this.stopExplosion);
		this.headExplosion = null;
	    }
	}

	/*
	 * resetLifePositions()
	 *
	 * This function arranges the images representing the number of remaining lives the player has
	 *
	 * arguments: none
	 *
	 * returns : none
	 */
	public function resetLifePositions()
	{
	    var i:Number = 0;
	    var preloader:Preloader = Preloader.getInstance();
	    if ( this.lifeImages.length < this.lives ) {
		for ( i = this.lifeImages.length; i < this.lives; i++ ) {
		    var img:Bitmap = preloader.getBitmap("gfx_pwup_freelife");
		    img.x = 64*i;
		    img.y = 0;
		    this.lifeImages.push(img);
		    this.lifeDisplay.addChild(img);
		}
	    } else {
		for ( var i = 0; i < this.lifeImages.length ; i++ ) {
		    if ( i >= this.lives ) {
			this.lifeDisplay.removeChild(this.lifeImages[i]);
			this.lifeImages.splice(i, 1);
		    }
		}
	    }
	    for ( var i = 0; i < this.lifeImages.length ; i++ ) {
		this.lifeImages[i].x = 64*i;
		this.lifeImages[i].y = 0;
	    }
	}

	/*
	 * usePowerupAt(index)
	 *
	 * See if there is a powerup at index 'index' in the inventory, use it, fire off any sounds associated with it,
	 * and dispatch a new PowerupEvent for it
	 *
	 * arguments:
	 *    @index:Number, the index in inventory from which the powerup should be drawn
	 *
	 * returns: none
	 */
	public function usePowerupAt(index:Number)
	{
	    if ( index < this.inventory.length ) {
		this.removeChild(this.inventory[index]);
		var preloader:Preloader = Preloader.getInstance();
		preloader.playSound(this.inventory[index].sndHandle);
		this.resetPowerupPositions();
		this.dispatchEvent(new PowerupEvent(PowerupEvent.USED_POWERUP, this.inventory[index]));
		this.inventory[index].removeEventListener(MouseEvent.MOUSE_UP, this.onPowerupClicked);
		this.inventory.splice(index, 1);
	    }
	}

	/*
	 * onPowerupClicked(evt)
	 *
	 * This function is fired whenever the player clicks the mouse on a powerup owned by the player
	 * 
	 * arguments:
	 *    @evt:MouseEvent, the event firing this function
	 *
	 * Returns: none
	 */
	public function onPowerupClicked(evt:MouseEvent)
	{
	    for ( var i:Number = 0 ; i < this.inventory.length ; i++ ) {
		if ( this.inventory[i] == evt.target ) {
		    this.usePowerupAt(i);
		}
	    }
	}

	/*
	 * clearInventory()
	 *
	 * Fairly obvious, this function just clears out the inventory
	 *
	 * arguments: none
	 *
	 * returns: none
	 */
	public function clearInventory()
	{
	    for ( var i:Number = 0; i < this.inventory.length ; i++ ) {
		this.removeChild(this.inventory[i]);
		this.inventory.splice(i, 1);
	    }
	}
    }
}
