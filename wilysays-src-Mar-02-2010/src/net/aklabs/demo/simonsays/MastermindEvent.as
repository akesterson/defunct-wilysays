package net.aklabs.demo.simonsays 
{
    import flash.events.Event;

    /*
     * Class : MastermindEvent
     * 
     * This class basically just defines a custom event that will let the mastermind send up
     * a clicked event w/ a color.
     */
    public class MastermindEvent extends Event
    {
	public static var BTN_CLICKED:String = "MASTERMIND_BUTTON_CLICKED";
	public var colorClicked:Number;

	public function MastermindEvent(evtType:String)
	{
	    super(evtType);
	}
    }
}

