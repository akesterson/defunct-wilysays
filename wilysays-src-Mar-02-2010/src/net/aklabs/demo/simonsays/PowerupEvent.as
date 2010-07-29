package net.aklabs.demo.simonsays {
    import flash.events.Event;
    import net.aklabs.demo.simonsays.Powerup;

    /*
     * Class PowerupEvent 
     * 
     * An event specifically made for actions taken regarding powerups 
     */
    public class PowerupEvent extends Event {
	public static var GOT_POWERUP:String = "SIMONSAYS_GOT_POWERUP"; // Type for events when a powerup was received
	public static var USED_POWERUP:String = "SIMONSAYS_USED_POWERUP"; // Type for events when a powerup was used
	public var pwup:Powerup; // the powerup (rather than the target) of this event

	/*
	 * PowerupEvent()
	 * 
	 * Default Constructor
	 *
	 * arguments:
	 *    @evtType:String, the type of this event (GOT_POWERUP or USED_POWERUP)
	 *    @tgt:Powerup, the Powerup object that's being affected by this event
	 *
	 * returns: none
	 */
	public function PowerupEvent(evtType:String, tgt:Powerup = null)
	{
	    super(evtType);
	    this.pwup = tgt;
	}
    }
}
