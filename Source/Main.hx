package;

import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;

import openfl.text.Font;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

import openfl.Assets;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Mouse;
import openfl.ui.Keyboard;

import openfl.filters.BitmapFilter;
import openfl.filters.DropShadowFilter;

import openfl.display.Tilesheet;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import openfl.display.FPS;
import openfl.media.Sound;
import motion.easing.Quad;
import motion.Actuate;

import phidgets.PhidgetRfid;
import phidgets.event.RfidEvent;
import phidgets.event.RfidDataEvent;

class Main extends Sprite {
	
	private var priceformat:TextFormat;
	private var format:TextFormat;
    private var tfStatus:TextField;
 	private var priceTag:TextField;
 	private var bitmap:Bitmap;
 	private var cards:Array<Bitmap> = [];
 	private var currentCard:Bitmap;
 	private var cardContainer:Sprite;
 	
 	private var ScanSound:Sound;

 	private var lastCardID:Int;
	private var tags:Array<String> = ["2800b916b2","5800832e5f","28007c0906"];
	private var labels:Array<String> = ["Raspberry Pi 2","Raspberry Pi Touch Display","Phidget Rfid"];
	private var prices:Array<String> = ["€36,95","€74,95","€62,95"];

	public function new () {
		
		super ();
		
		ScanSound = Assets.getSound ("plonk");
		
		cardContainer = new Sprite();
		addChild(cardContainer);

		for (i in 1...tags.length+1){
			var card:Bitmap = new Bitmap (Assets.getBitmapData ("assets/item" + i +".png"));
			card.x = stage.stageWidth + 1;
			card.y = (stage.stageHeight - card.height)*.55;
			cards.push(card);
		}

		bitmap = new Bitmap (Assets.getBitmapData ("assets/openfl.png"));
		bitmap.x = 32;
		bitmap.y = 32;
		addChild( bitmap );

		addChild( cardContainer );

		var font = Assets.getFont ("fonts/SourceSansPro-Semibold.otf");
		priceformat = new TextFormat (font.fontName, 90, 0x222222);
		format = new TextFormat (font.fontName, 48, 0x24AfC4);
    	format.align = TextFormatAlign.CENTER;

        tfStatus = new TextField ();
        tfStatus.width = stage.stageWidth;
        tfStatus.defaultTextFormat = format;
        tfStatus.embedFonts = true;
        tfStatus.selectable = false;
        
        tfStatus.x = 0;
        tfStatus.y = stage.stageHeight - format.size - 16;
        tfStatus.text = "Waiting for RFID Device";

		addChild (tfStatus);

		priceTag = new TextField ();
		priceTag.width = 320;
		priceTag.height = priceformat.size +16;
		priceTag.defaultTextFormat = priceformat;
        priceTag.embedFonts = false;
        priceTag.selectable = false;
		addChild (priceTag);

		PhidgetRfid.initialize();

		stage.addEventListener (KeyboardEvent.KEY_DOWN, stage_onKeyDown);
		stage.addEventListener(RfidEvent.DEVICE_ATTACH, handleDeviceFound);
		stage.addEventListener(RfidEvent.DEVICE_DETACH, handleDeviceLost);
		stage.addEventListener(RfidDataEvent.TAG_FOUD, handleTagFound);
		stage.addEventListener(RfidDataEvent.TAG_LOST, handleTagLost);
		
  		tfStatus.text = "Please scan your RFID tag";
		Mouse.hide();
	}

	private function stage_onKeyDown (event:KeyboardEvent):Void
	{	
		switch (event.keyCode) {
			
			case Keyboard.ESCAPE:
				openfl.system.System.exit(0); 
			
			case Keyboard.F4:
				openfl.system.System.exit(0);
		}
	}

   private function this_onMoveToComplete(){
		priceTag.y = currentCard.y - 8;
		Actuate.tween (priceTag, .5, { x: currentCard.x + currentCard.width + 32 , alpha:1 } ).ease (Quad.easeOut);
		priceTag.text = prices[lastCardID];
    }

    private function resetCard(id:Int):Void{
    	if( id > cards.length-1) return;
    	priceTag.text = "";
    	priceTag.x = stage.stageWidth + 8;
    	var targetCard:Bitmap = cards[id];
    	Actuate.stop(targetCard);
    	targetCard.x = stage.stageWidth +1;
    	targetCard.alpha = 1;
		cardContainer.removeChild(targetCard);
    }

	private function handleTagFound(e:RfidDataEvent) : Void{
		var cardID = tags.indexOf(e.data);
		
		if(cardID == -1)
		{
			tfStatus.text = "unknown tag: " + e.data;
		}else
		{
			tfStatus.text = labels[cardID];
			if(currentCard!=null){
				resetCard(lastCardID);
			}
			lastCardID 		= cardID;
			currentCard 		= cards[cardID];
			currentCard.x 		= stage.stageWidth +1;
			currentCard.alpha 	= 1;
			cardContainer.addChild(cards[cardID]);
			var tx :Float = (stage.stageWidth - currentCard.width) *.5;
			Actuate.tween (currentCard, .5, { x: tx , alpha:1 } ).ease (Quad.easeOut).onComplete (this_onMoveToComplete);
			ScanSound.play();
		}
    }

 

    private function handleTagLost(e:RfidDataEvent) : Void{
    	tfStatus.text = "Please scan your RFID tag";
    	var cardID = tags.indexOf(e.data);
    	if(cardID!=-1){
    		var target = cards[cardID];
    		if(target !=null){
				Actuate.tween (target, .2, { x: -1*stage.stageWidth, alpha: 0 } ).ease (Quad.easeOut).onComplete ( function(){
					resetCard(cardID);
				});
			}
		}
    }

    private function handleDeviceFound(e:RfidEvent) : Void{
		trace("> Device Found:" +e.serialno);
		tfStatus.text = "Device Found:" +e.serialno;
    }

    private function handleDeviceLost(e:RfidEvent) : Void{
		trace("> Device Lost:" +e.serialno);
		tfStatus.text = "Device Lost:" +e.serialno;
    }
}
