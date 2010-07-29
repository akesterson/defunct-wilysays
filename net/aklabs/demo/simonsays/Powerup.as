package net.aklabs.demo.simonsays {
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import net.aklabs.demo.simonsays.PowerupEvent;

    /*
     * Class Powerup
     * 
     * This class just represents a powerup in the game.
     * This is more a data structure than a class, but I don't think
     * AS 3.0 has just bare structures. Silly ECMA language...
     */
    public class Powerup extends Sprite
    {
	public static var PTYPE_SLOWDOWN:Number = 0; /* SLOWDOWN - Slows the pattern timer to a much lower rate */
	public static var PTYPE_FORGIVENESS:Number = 1; /* FORGIVENESS - If you have FORGIVENESSS in your inventory and you miss a pattern, it doesn't stop you */
	public static var PTYPE_SKIP:Number = 2; /* SKIP - Lets you "skip" a given pattern iteration, and you still get all the score for it. */
	public static var PTYPE_DOUBLE:Number = 3; /* DOUBLE - Score double points for the pattern on which you use this powerup. */
	public static var PTYPE_MAXVALUE:Number = 4;
	// POWERUP_IMAGES - these are the image handles (stored in an array where idx => PTYPE_XXX) for each of the powerup types
	public static var POWERUP_IMAGES = new Array("gfx_pwup_slowdown", "gfx_pwup_forgiveness", "gfx_pwup_exclamation", "gfx_pwup_pointdoubler");
	// POWERUP_SOUNDS - these are the sound handles (stored in an array where idx => PTYPE_XXX) for each of the powerup types
	public static var POWERUP_SOUNDS = new Array("sfx_slowdown", "sfx_forgiveness", "sfx_exclamation", "sfx_pointdoubler");
	public var imgHandle:String; // the handle for the image of this specific powerup
	public var sndHandle:String; // the handle for the sound of this specific powerup
	public var pType:Number; // the PTYPE_XXX of this powerup
    }
}
