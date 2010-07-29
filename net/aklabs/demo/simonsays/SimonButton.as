package net.aklabs.demo.simonsays {

    import flash.events.MouseEvent;
    import flash.display.Bitmap;
    import flash.display.Sprite;

    /*
     * class SimonButton
     *
     * This is just a custom button class that is pixel-accurate, because the Mastermin/Simon Says
     * buttons are an extremely odd shape, so I needed something that could detect mouse hits in/
     * outside of the alpha color areas.
     *
     * Most of this class is really self explanatory, so I'm not going to bother documenting all of it. Only the parts that don't make immediate sense.
     */
    public class SimonButton extends Sprite
    {
	protected var imgDown:Bitmap; // bitmap for when the button is pressed
	protected var imgUp:Bitmap; // bitmap for when the button is released
	protected var curImg:Bitmap; // the bitmap currently being displayed on the button
	protected var magicColor:Number; // the magic color (e.g. "magic pink"), if any (otherwise alpha is used for hit detection)

	public function SimonButton(imgDown:Bitmap = null, imgUp:Bitmap = null, magicColor = 0x00000000)
	{
	    super();
	    this.imgDown = imgDown;
	    this.imgUp = imgUp;
	    this.curImg = null;
	    this.magicColor = magicColor;
	    this.addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
	    this.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
	    this.addEventListener(MouseEvent.CLICK, this.onMouseClick);
	}

	public function setMagicColor(color:Number)
	{
	    this.magicColor = color;
	}

	public function setBtnDown(obj:Bitmap)
	{
	    if ( obj ) {
		this.imgDown = obj;
	    }
	}

	public function setBtnUp(obj:Bitmap)
	{
	    if ( obj ) {
		this.imgUp = obj;
	    }
	}

	public function onMouseDown(obj:MouseEvent)
	{
	    if ( (obj) && (! this.hitTestPoint(obj.localX, obj.localY)) ) {
		obj.stopImmediatePropagation();
		return;
	    }
	    if ( this.curImg ) {
		this.removeChild(this.curImg);
	    }
	    if ( this.imgDown ) {
		this.addChild(this.imgDown);
		this.curImg = this.imgDown;
	    }
	}

	public function onMouseUp(obj:MouseEvent)
	{
	    if ( (obj) && (!this.hitTestPoint(obj.localX, obj.localY)) ) {
		obj.stopImmediatePropagation();
		return;
	    }
	    if ( this.curImg ) {
		this.removeChild(this.curImg);
	    }
	    if ( this.imgUp ) {
		this.addChild(this.imgUp);
		this.curImg = this.imgUp;
	    }
	}

	public function onMouseClick(obj:MouseEvent)
	{
	    if ( ! this.hitTestPoint(obj.localX, obj.localY) ) {
		obj.stopImmediatePropagation();
	    }
	}

	/*
	 * hitTestPoint(x, y, shapeFlag)
	 *
	 * An overriden version of hitTestPoint that is pixel-accurate. If the value at (x, y) is either A: of the value
	 * in the "magic color", or B: containing an alpha value of zero, then the hit is POSITIVE. Otherwise it is false.
	 *
	 * arguments:
	 *    @x:Number, the X location of the hit relative to the origin of the object
	 *    @y:Number, the Y location of the hit relative to the origin of the object
	 *    @shapeFlag:Boolean, not used, just here for compatibility
	 *
	 * returns: Boolean (true if the hit is positive, false if it's negative)
	 */
	public override function hitTestPoint(x:Number, y:Number, shapeFlag:Boolean = false):Boolean
	{
	    var color:uint;
	    var rgb:uint;
	    var a:uint;

	    if ( this.curImg && this.curImg.bitmapData ) {
		color = this.curImg.bitmapData.getPixel32(x, y);
		a = ((color >> 24) & 0xFF);
		rgb = (color & 0xFFFFFF00);
		//trace("Alpha : " + a + " RGB " + rgb + " magic color " + this.magicColor);
		if ( this.magicColor == rgb || a == 0 ) {
		    return false;
		}
		return true;
	    }
	    return false;
	}
    }
}
