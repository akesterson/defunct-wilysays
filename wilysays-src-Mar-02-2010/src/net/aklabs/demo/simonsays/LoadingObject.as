package net.aklabs.demo.simonsays {

    /*
     * Class LoadingObject
     *
     * This class is used to represent a content asset while it is going through the process of being loaded
     * by the Preloader class.
     */
    public class LoadingObject {
	public static var STATE_READY:Number = 0; // Object has been loaded and is ready 
	public static var STATE_LOADING:Number = 1; // Object is currently loading, not ready yet
	public static var STATE_NOTFOUND:Number = 2; // Object wasn't found in the cache
	public var handle:String; // Text handle for this object
	public var state:Number; // State value
	public var bytesRead:Number; // the amount of bytes currently read in to this object over the net
	public var bytesTotal:Number; // the total byte size of this object
	
	/*
	 * LoadingObject()
	 * 
	 * Default constructor
	 * 
	 * arguments : none
	 * 
	 * Returns : LoadingObject
	 */
	public function LoadingObject() {
	    this.handle = "";
	    this.state = LoadingObject.STATE_NOTFOUND;
	    this.bytesRead = 0;
	    this.bytesTotal = 0;
	}
    }
}		