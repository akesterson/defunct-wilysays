/*
 * MEGA MAN : "Wily Says"
 * Demo for Zynga Games
 * (C) Andrew Kesterson 2010 andrew@aklabs.net
 *
 */

// - TODO : Implement proper layering! Quit this *!@# of adding/removing children in the right order.

package {
	import flash.display.MovieClip; 
	import flash.display.SimpleButton;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFieldAutoSize;
	import flash.text.AntiAliasType;
	import flash.filters.GlowFilter;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.utils.Timer;
	import flash.utils.Dictionary;
	import flash.media.SoundChannel;
	import flash.net.*;
	import net.aklabs.demo.simonsays.Preloader;
	import net.aklabs.demo.simonsays.Pattern;
	import net.aklabs.demo.simonsays.Mastermind;
	import net.aklabs.demo.simonsays.LoadingObject;
	import net.aklabs.demo.simonsays.Player;
	import net.aklabs.demo.simonsays.Powerup;
	import net.aklabs.demo.simonsays.PowerupEvent;
	import net.aklabs.demo.simonsays.MastermindEvent;

	/* Class : Game
	 * 
	 * Main application class. Handles player input, logic, etc.
	 */
	 
	public class Game extends MovieClip {

		protected var preloader:Preloader; // preloader content manager
		protected var gameTimer:Timer; // timer for the game logic
		protected var bgMusicChannel:SoundChannel; // channel on which background music is playing - TODO: Allow bgmusic/sfx turned ON/OFF
		protected var curLevel:Number; // the level of the current number, from 1-10
		protected var player:Player; // Object representing the player
		protected var curPattern:Pattern; // The currently active "Pattern" object being played out
		protected var simon:Mastermind; // The "Simon Says" ("Mastermind")
		protected var cutscenes:Dictionary; // A dictionary of instantiated and prepared SWF-cloned cutscenes
		protected var difficulty:Number;   // An integer from 0-n setting the difficulty of the game
		public static var STATE_PLAYING:Number = 0; // STATE : Game is currently PLAYING (e.g., not in menu/cinematic/highscore/credits/etc)
		public static var STATE_MENU:Number = 1; // STATE: Game is currently sitting at the main menu waiting for player to start the game 
		public static var STATE_HELP:Number = 2; // STATE : Game is currently on the HELP screen (currently unused) - TODO : Add "Help" screen beyond tutorial
		public static var STATE_PASSWORD:Number = 3; /* STATE : Game is currently on the password input screen to resume a game (currently unused)
		    TODO : Get rid of this, password system was never implemented and doesn't make sense for this game */
		public static var STATE_GAMEOVER:Number = 4; // STATE : Player has lost the game and is dead
		public static var STATE_PLAYING_PLAYBACK:Number = 5; /* STATE : Substate of STATE_PLAYING. Used while the Mastermind is playing back the currently
		    exposed portions of the currently playing pattern */									    
		public static var STATE_PLAYING_INPUT:Number = 6; // STATE : Substate of STATE_PLAYING. Used while the Mastermind is accepting input from the player.
		public static var STATE_PLAYING_FLASHING:Number = 7; // STATE : Substate of STATE_PLAYING. Used while the Mastermind is flashing all its lights for a second.
		public static var STATE_PLAYING_EXPLODING:Number = 8; // STATE : Substate of STATE_PLAYING. Used after the player loses, and while the screen is exploding.
		public static var STATE_PLAYING_WAITING:Number = 9; /* STATE : Substate of STATE_PLAYING. When the explosion timer has fired, this substate is used while
		    waiting for the explosions to finish their animation before going to STATE_HIGHSCORE. */
		public static var STATE_PLAYING_WINLEVEL:Number = 10; /* STATE : Substate of STATE_PLAYING. Used when the player has completed all iterations of the
		    current pattern. Implies that the level number is scrolling past, etc.*/
		public static var STATE_WINGAME:Number = 11; // STATE : Used when the player has completed all patterns and has won the game.
		public static var STATE_TUTORIAL = 12; // STATE : Game is currently running the tutorial/intro
		public static var STATE_HIGHSCORE = 13; // STATE : Game is currently awaiting input on the high score screen
		protected var primaryState:Number; // Stores the game's current primary state value 
		protected var secondaryState:Number; // Stores any applicable substate for the game, if any
		protected var buttonSounds:Dictionary; // Stores references to the loaded sounds in the preloader for each of the Mastermind buttons
		protected var timerLabel:TextField; // Text label for the timer display (upper right)
		protected var scoreLabel:TextField; // Text label for the score display (upper left)
		protected var levelLabel:TextField; // Text label for the "LEVEL" that scrolls across the screen after beating a pattern
		protected var levelNumberLabel:TextField; // Text label for the level number (e.g., the "12" in "LEVEL 12") that scrolls after beating a pattern
		protected var explosionTimer:Timer; // Timer that runs long enough to generate a bunch of sparse explosions when the player loses.
		protected var explosions:Array; /* An array containing to references to all the currently running explosions on the screen 
		    (used so that they can all be safely cleaned up & removed from the screen after Game Over and before moving to the High Score screen) */
		protected var maxLevel:Number; // maximum level number achievable before winning the game
		protected var levelClearTime:Number; // The time in which a given pattern/level was cleared; currently unused. TODO - Implement this and put it in the high scores
		protected var labelPauseTimer:Timer; // the timer that lets the "Level X" label pause in the center of the screen briefly

		public static var KEY_NUM1:Number = 97;
		public static var KEY_NUM3:Number = 99;
		public static var KEY_NUM7:Number = 103;
		public static var KEY_NUM9:Number = 105;
		public static var KEY_COMMA:Number = 188;
		public static var KEY_BACKSLASH:Number = 191;
		public static var KEY_K:Number = 75;
		public static var KEY_APOSTROPHE = 222;
		public static var KEY_0:Number = 48;
		public static var KEY_1:Number = 49;
		public static var KEY_2:Number = 50;
		public static var KEY_3:Number = 51;
		public static var KEY_4:Number = 52;
		public static var KEY_5:Number = 53;
		public static var KEY_6:Number = 54;
		public static var KEY_7:Number = 55;
		public static var KEY_8:Number = 56;
		public static var KEY_9:Number = 57;
		public static var KEY_SPACE:Number = 32;

		/*
		 * Game()
		 *
                 * Default constructor for Game class
		 *
		 * arguments: none
		 *
		 * returns : Game
		 */
		public function Game()
		{
		    // -- setup the preloader and start it downloading
		    var assets = new Array(    new Array("sounds", "music_background", "sfx/BACKGROUND.mp3"),
					       new Array("sounds", "sfx_explosion", "sfx/EXPLOSION.mp3"),
					       new Array("sounds", "sfx_btn_blue", "sfx/BLUE.mp3"),
					       new Array("sounds", "sfx_btn_green", "sfx/GREEN.mp3"),
					       new Array("sounds", "sfx_btn_red", "sfx/RED.mp3"),
					       new Array("sounds", "sfx_btn_yellow", "sfx/YELLOW.mp3"),
					       new Array("sounds", "sfx_slowdown", "sfx/SLOWDOWN.mp3"),
					       new Array("sounds", "sfx_shortcircuit", "sfx/SHORTCIRCUIT.mp3"),
					       new Array("sounds", "sfx_pointdoubler", "sfx/POINTDOUBLER.mp3"),
					       new Array("sounds", "sfx_exclamation", "sfx/EXCLAMATION.mp3"),
					       new Array("sounds", "sfx_forgiveness", "sfx/FORGIVENESS.mp3"), 
					       new Array("images", "gfx_btn_darkblue", "gfx/blue-dark.png"),
					       new Array("images", "gfx_btn_lightblue", "gfx/blue-light.png"),
					       new Array("images", "gfx_btn_darkgreen", "gfx/green-dark.png"),
					       new Array("images", "gfx_btn_lightgreen", "gfx/green-light.png"),
					       new Array("images", "gfx_btn_darkred", "gfx/red-dark.png"),
					       new Array("images", "gfx_btn_lightred", "gfx/red-light.png"),
					       new Array("images", "gfx_btn_darkyellow", "gfx/yellow-dark.png"),
					       new Array("images", "gfx_btn_lightyellow", "gfx/yellow-light.png"),
					       new Array("images", "gfx_mastermind", "gfx/whole.png"),
					       new Array("images", "gfx_background", "gfx/game_background.png"),
					       new Array("images", "gfx_circuitboard", "gfx/circuitboard.png"),
					       new Array("images", "gfx_pwup_exclamation", "gfx/EXCLAMATION.png"),
					       new Array("images", "gfx_pwup_forgiveness", "gfx/FORGIVENESS.png"),
					       new Array("images", "gfx_pwup_pointdoubler", "gfx/POINTDOUBLER.png"),
					       new Array("images", "gfx_pwup_shortcircuit", "gfx/SHORTCIRCUIT.png"),
					       new Array("images", "gfx_pwup_slowdown", "gfx/SLOWDOWN.png"),
					       new Array("images", "gfx_progress_red", "gfx/progress_red.png"),
					       new Array("images", "gfx_progress_green", "gfx/progress_green.png"),
					       new Array("images", "gfx_pwup_freelife", "gfx/LIFE.png"),
					       new Array("movies", "movie_endscreen", "gfx/cutscenes/endscreen.swf", ""),
					       new Array("movies", "movie_intro_menu", "gfx/cutscenes/intro-menu.swf", ""),
					       new Array("movies", "movie_tutorial", "gfx/cutscenes/tutorial.swf", ""),
					       new Array("movies", "movie_highscore", "gfx/cutscenes/highscore.swf", ""),
					       new Array("movies", "movie_difficultychooser", "gfx/cutscenes/difficultychooser.swf", ""),
					       new Array("movies", "movie_explosion", "gfx/explosion.swf", "SmallExplosion") );
		    this.preloader = new Preloader(assets);
		    this.preloader.x = 200;
		    this.preloader.y = 140;
		    this.addChild(this.preloader);
		    this.preloader.addEventListener(Event.COMPLETE, this.onPreloaderComplete);
		    this.preloader.loadAssets();
		    
                    this.buttonSounds = new Dictionary();
		    this.buttonSounds[0] = "sfx_btn_blue";
		    this.buttonSounds[1] = "sfx_btn_green";
		    this.buttonSounds[2] = "sfx_btn_red";
		    this.buttonSounds[3] = "sfx_btn_yellow";
		    
		    // -- set up all the timers
		    this.gameTimer = new Timer(25);
		    this.gameTimer.start();
		    this.explosionTimer = new Timer(5000);
		    stage.addEventListener(KeyboardEvent.KEY_UP, this.onKeyUp);
		    this.labelPauseTimer = new Timer(2000);
		    
		    // -- miscellanious stuff
		    this.player = new Player();
		    this.cutscenes = new Dictionary();
		    this.explosions = new Array();
		    this.curLevel = 1;
		    this.curPattern = null;
		    this.difficulty = 3;
		}

		/*
		 * onNonLoopEnterFrame(evt)
		 *
		 * This function serves as a trigger on sprites which should not loop their animations. There may be
		 * a simpler way to do this, but being pressed for time I knew this would stop it.
		 *
		 * arguments:
		 *    @evt : Event , event that triggered this function
		 * 
		 * Returns: none
		 */  
		public function onNonLoopEnterFrame(evt:Event)
		{
                    if ( evt.target.currentFrame == evt.target.totalFrames ) {
			evt.target.stop();
		    }
		}

		/*
		 * onKeyUp(evt)
		 *
		 * This function grabs the player's keyboard input and passes it off to the Player, Pattern objects, etc
		 *
		 * arguments:
		 *     @evt: Event, event that triggered this function
		 *
		 * Returns : none
		 */
		public function onKeyUp(evt:KeyboardEvent)
		{
		    var pwup:Powerup = null;

		    if ( this.primaryState == Game.STATE_PLAYING_INPUT ) {
			var colorPressed:Number = -1;
			if ( (( evt.keyCode == Game.KEY_NUM1) || (evt.keyCode == Game.KEY_COMMA)) ) {
			    colorPressed = Pattern.COLOR_YELLOW;
			} else if ( (( evt.keyCode == Game.KEY_NUM3) || (evt.keyCode == Game.KEY_BACKSLASH)) )  {
			    colorPressed = Pattern.COLOR_BLUE;
			} else if ( (( evt.keyCode == Game.KEY_NUM7) || (evt.keyCode == Game.KEY_K)) ) {
			    colorPressed = Pattern.COLOR_GREEN;
			} else if ( (( evt.keyCode == Game.KEY_NUM9) || (evt.keyCode == Game.KEY_APOSTROPHE)) ) {
			    colorPressed = Pattern.COLOR_RED;
			} else if ( ( evt.keyCode >= Game.KEY_0 && evt.keyCode <= Game.KEY_9) ) {
			    if ( evt.keyCode == Game.KEY_0 )
				evt.keyCode = Game.KEY_0 + 10; // trust me it makes sense (Key 0 is the player's last inventory slot to the right
                                                  // but it comes first in the keyCode sequence before 1, which is the far left, so we add 10 to it
			                          // because we're passing an index from 0 - 9 for the player's inventory)
			    this.player.usePowerupAt(evt.keyCode - 49);
			}
			
			if ( colorPressed != -1 )
			    this.checkColorHit(colorPressed);
		    } else if ( this.primaryState == Game.STATE_MENU ) {
			if ( evt.keyCode == Game.KEY_SPACE ) {
			    this.addChild(cutscenes["difficultychooser"]);
			}
		    } else if ( this.primaryState == Game.STATE_TUTORIAL ) {
			if ( evt.keyCode == Game.KEY_SPACE ) {
			    this.newGame();
			}
		    } else if ( this.primaryState == Game.STATE_WINGAME ) {
			if ( evt.keyCode == Game.KEY_SPACE ) {
			    this.primaryState = Game.STATE_HIGHSCORE;
			    this.secondaryState = Game.STATE_HIGHSCORE;
			    this.removeChild(this.cutscenes["endscreen"]);
			    this.addChild(this.cutscenes["highscores"]);
			    this.cutscenes["highscores"].play();
			}
		    }
		} 
		
		/*
		 * onPreloaderComplete(evt)
		 *
		 * This function is fired whenever the Preloader fires an event signifying that all items
		 * in the asset list have been successfully loaded.
		 * 
		 * arguments:
		 *    @evt : Event, the event firing this function
		 *
		 * Returns: none
		 */

		public function onPreloaderComplete(evt:Event)
		{
		    if ( evt.target == this.preloader ){
			this.removeChild(this.preloader);
			// -- setup the cutscenes so they're ready to use
			this.cutscenes["intro_menu"] = this.preloader.getObject("movie_intro_menu");
			this.cutscenes["intro_menu"].x = 0;
			this.cutscenes["intro_menu"].y = 0;
			this.cutscenes["intro_menu"].addEventListener(Event.ENTER_FRAME, this.onNonLoopEnterFrame);
			this.cutscenes["tutorial"] = this.preloader.getObject("movie_tutorial");
			this.cutscenes["tutorial"].x = 0;
			this.cutscenes["tutorial"].y = 0;
			this.cutscenes["tutorial"].addEventListener(Event.ENTER_FRAME, this.onNonLoopEnterFrame);
			this.cutscenes["highscores"] = this.preloader.getObject("movie_highscore");
			this.cutscenes["highscores"].x = 0;
			this.cutscenes["highscores"].y = 0;
			this.cutscenes["highscores"].addEventListener(Event.ENTER_FRAME, this.onNonLoopEnterFrame);
			this.cutscenes["highscores"].highScorePostBtn.addEventListener(MouseEvent.CLICK, this.onHighScoreEntry);
			this.cutscenes["highscores"].highScoreCancelBtn.addEventListener(MouseEvent.CLICK, this.onHighScoreEntry);
			this.cutscenes["highscores"].viewScoreBtn.addEventListener(MouseEvent.CLICK, this.onHighScoreEntry);
			this.cutscenes["difficultychooser"] = this.preloader.getObject("movie_difficultychooser");
			this.cutscenes["difficultychooser"].x = 300;
			this.cutscenes["difficultychooser"].y = 200;
			this.cutscenes["difficultychooser"].easyBtn.addEventListener(MouseEvent.CLICK, this.onDifficultySelected);
			this.cutscenes["difficultychooser"].normalBtn.addEventListener(MouseEvent.CLICK, this.onDifficultySelected);
			this.cutscenes["difficultychooser"].hardBtn.addEventListener(MouseEvent.CLICK, this.onDifficultySelected);
			this.cutscenes["difficultychooser"].wilyBtn.addEventListener(MouseEvent.CLICK, this.onDifficultySelected);
			this.cutscenes["endscreen"] = this.preloader.getObject("movie_endscreen");
			this.cutscenes["endscreen"].x = 0;
			this.cutscenes["endscreen"].y = 0;
			
			this.addChild(this.cutscenes["intro_menu"]);

			this.gameTimer.removeEventListener(TimerEvent.TIMER, this.onPreloaderComplete);
			this.gameTimer.addEventListener(TimerEvent.TIMER, this.onGameTimer);
			
			this.simon = new Mastermind();
			this.simon.x = (640-(this.simon.width))/2;
			this.simon.y = 20;
			this.simon.addEventListener(MastermindEvent.BTN_CLICKED, this.onMastermindClicked);
			
			this.timerLabel = new TextField();
			this.timerLabel.background = false;
			this.timerLabel.autoSize = TextFieldAutoSize.LEFT;
			var timerLabelFormat = new TextFormat();
			timerLabelFormat.font = "Courier New";
			timerLabelFormat.bold = false;
			timerLabelFormat.color = 0xF12B2B;
			timerLabelFormat.size = 36;
			this.timerLabel.defaultTextFormat = timerLabelFormat;
			this.timerLabel.text = "00000";
			this.timerLabel.x = 504;
			this.timerLabel.y = 34;
			
			this.scoreLabel = new TextField();
			this.scoreLabel.background = false;
			this.scoreLabel.autoSize = TextFieldAutoSize.LEFT;
			this.scoreLabel.defaultTextFormat = timerLabelFormat;
			this.scoreLabel.text = "000000";
			this.scoreLabel.x = 12;
			this.scoreLabel.y = 34;
			
			this.levelLabel = new TextField();
			this.levelLabel.background = false;
			this.levelLabel.autoSize = TextFieldAutoSize.LEFT;
			this.levelNumberLabel = new TextField();
			this.levelNumberLabel.background = false;
			this.levelNumberLabel.autoSize = TextFieldAutoSize.LEFT;
			var levelLabelFormat = new TextFormat();
			levelLabelFormat.font = "Helvetica";
			levelLabelFormat.bold = true;
			levelLabelFormat.color = 0xF12B2B;
			levelLabelFormat.size = 72;
			this.levelLabel.defaultTextFormat = levelLabelFormat;
			this.levelNumberLabel.defaultTextFormat = levelLabelFormat;
			this.levelLabel.antiAliasType = AntiAliasType.ADVANCED;
			this.levelNumberLabel.antiAliasType = AntiAliasType.ADVANCED;
			this.levelLabel.filters = [new GlowFilter(0x000000, 1.0, 4, 4, 300)];
			this.levelNumberLabel.filters = [new GlowFilter(0x000000, 1.0, 4, 4, 300)];
			this.levelLabel.x = 150;
			this.levelLabel.y = 500;
			this.levelNumberLabel.x = 400;
			this.levelNumberLabel.y = -150;
			this.levelLabel.text = "LEVEL";
			
			this.player.addEventListener(PowerupEvent.USED_POWERUP, this.onUsedPowerup);
			this.playBackgroundMusic();
			this.primaryState = Game.STATE_MENU;
			this.secondaryState = Game.STATE_MENU;
			return;
		    }
		}

		/*
		 * onBackgroundMusicFinished(evt)
		 *
		 * This function just makes sure that the background music loops forever
		 * 
		 * arguments:
		 *    @evt: Event, event firing this function
		 *
		 * Returns: none
		 */
		public function onBackgroundMusicFinished(evt:Event)
		{
		    this.playBackgroundMusic();
		}


		/*
		 * playBackgroundMusic()
		 * 
		 * This function starts the background music playing
		 *
		 * arguments: none
		 * 
		 * Returns : none
		 */
		public function playBackgroundMusic()
		{
		    if ( this.bgMusicChannel )
			this.bgMusicChannel.stop();
		    var bgmusic = this.preloader.getObject("music_background");
		    if ( !bgmusic ) {
			return;
		    }
		    this.bgMusicChannel = bgmusic.play();               
		    this.bgMusicChannel.addEventListener(Event.SOUND_COMPLETE, this.onBackgroundMusicFinished);
		}

		/*
		 * onGetPowerup(evt)
		 *
		 * This function is fired whenever the Pattern is signifying that the player has gotten a powerup from the pattern
		 * 
		 * arguments:
		 *    @evt : Event, event firing this function
		 *
		 * Returns: none
		 */
		public function onGetPowerup(evt:PowerupEvent)
		{
		    if ( evt.pwup != null ) {
			var pwup = evt.pwup;
			pwup.addChild(this.preloader.getBitmap(pwup.imgHandle));
			this.player.addPowerup(pwup);
		    }
		}

	        /* 
		 * onGameTimer(evt)
		 * 
		 * Fires once every 25 ms to run the core game logic 
		 * 
		 * arguments:
		 *    @evt : Event, the event firing this function
		 * 
		 * Returns : none
		 */

		public function onGameTimer(evt:TimerEvent)
		{
		    var i:Number = 0;
		    
		    /* This state machine got just a little bit too complex, and I think alot of it could be probably get
		       done away with in favor of more events driving the show. However for right now, it works. The IF chains
		       check the primary state first, then go in and check secondary states and ancillary conditions. */

		    if ( (this.primaryState == Game.STATE_PLAYING) && (this.curPattern.state == Pattern.STATE_STOPPED) ) {
			if ( this.secondaryState == Game.STATE_PLAYING_FLASHING && (!this.simon.isLit) ) {
			    // we've flashed the Mastermind once, now let's play back the currently exposed portions of the pattern
			    this.curPattern.play(true);
			    this.primaryState = Game.STATE_PLAYING_PLAYBACK;
			    this.secondaryState = Game.STATE_PLAYING_PLAYBACK;
			} else if ( this.secondaryState == Game.STATE_PLAYING_EXPLODING ) {
			    // the player has died and we're still in the explosion timeframe, so blow some *!$% up
			    if ( Math.random() < 0.25 ) {
				var explosion = this.preloader.getMovieClip("movie_explosion");
				explosion.addEventListener(Event.ENTER_FRAME, this.onNonLoopEnterFrame);
				explosion.x = Math.random()*640;
				explosion.y = Math.random()*480;
				explosion.play();
				this.preloader.playSound("sfx_explosion");
				this.addChild(explosion);
				this.explosions.push(explosion);
			    }
			} else if ( this.secondaryState == Game.STATE_PLAYING_WINLEVEL ) {
			    // player just beat the pattern; scroll "LEVEL" down from the top, and the level number up from the bottom
			    this.levelNumberLabel.text = "" + this.curLevel;
			    if ( this.levelLabel.y == 175 && (!this.labelPauseTimer.running)) {
				this.labelPauseTimer.addEventListener(TimerEvent.TIMER, this.onLabelPauseTimer);
				this.labelPauseTimer.reset();
				this.labelPauseTimer.start();
			    } else if ( this.labelPauseTimer.running ) {
				// do nothing if the label pause timer is running
			    } else if ( this.levelLabel.y <= -120 ) {
				this.secondaryState = Game.STATE_PLAYING;
				this.levelLabel.y = 500;
				this.levelNumberLabel.y = -150;
			    } else {
				this.levelLabel.y -= 5;
				this.levelNumberLabel.y += 5;
			    }
			} else if ( this.secondaryState == Game.STATE_PLAYING ){
			    // flash the Mastermind once before playing back the portions currently exposed, so we have the player's
			    // attention
			    this.simon.flashAll(500);
			    this.secondaryState = Game.STATE_PLAYING_FLASHING;
			} 
		    } else if ( (this.primaryState == Game.STATE_PLAYING_PLAYBACK) ) {
			if ( (this.secondaryState == Game.STATE_PLAYING_FLASHING ) && (!this.simon.isLit) ) {
			    // okay we're done flashing around, let the player give input and start the timers
			    this.curPattern.play(false);
			    this.primaryState = Game.STATE_PLAYING_INPUT;
			    this.secondaryState = Game.STATE_PLAYING;
			} else if ( this.secondaryState == Game.STATE_PLAYING_PLAYBACK && this.curPattern.state == Pattern.STATE_STOPPED ) {
			    // flash the Mastermind a 2nd time to let the player know we're done running the pattern, and they need to start hitting buttons
			    this.simon.flashAll(500);
			    this.secondaryState = Game.STATE_PLAYING_FLASHING;
			}
		    } else if ( (this.primaryState == Game.STATE_PLAYING_INPUT) && (this.curPattern.state != Pattern.STATE_RUNNING ) ) {
			if ( this.curPattern.state == Pattern.STATE_CORRECT ) {
			    // player has repeated the pattern correctly
			    this.player.score += this.curPattern.score;
			    this.curPattern.complexify();
			    if ( this.curPattern.patternLength() > this.player.maxPattern )
				this.player.maxPattern = this.curPattern.patternLength();
			    // check the state again after complexifying it. If the player has reached the end of the pattern, we won't know 
			    // until we've ran .complexify() on it.
			    if ( this.curPattern.state == Pattern.STATE_COMPLETE ) {
				this.nextLevel();
				if ( this.curLevel >= this.maxLevel ) {
				    this.wonGame();
				    return;
				}
				return;
			    } 
			} else if ( this.curPattern.state == Pattern.STATE_FAILED ){
			    // Player irrevocably missed the pattern; deduct a life and either start a new pattern, or game over.
			    this.player.die();
			    if ( this.player.lives <= 0 ) {
				this.curPattern.stop()
				this.primaryState = Game.STATE_PLAYING;
				this.secondaryState = Game.STATE_PLAYING_EXPLODING;
				this.explosionTimer.addEventListener(TimerEvent.TIMER, this.onExplosionTimer);
				this.explosionTimer.start();
				this.curPattern.forceState(Pattern.STATE_STOPPED);
				return;
			    } else {
				this.newPattern();
			    }
			}
			// if we haven't returned out from a previous condition, it's safe to reset the primary/secondary state
			// to STATE_PLAYING so we'll flash and run the pattern normally
			this.primaryState = Game.STATE_PLAYING;
			this.secondaryState = Game.STATE_PLAYING;
			this.timerLabel.text = "00000";
		    } else if ( this.primaryState == Game.STATE_PLAYING_INPUT ) {
			// Player is running input, just update the timer text
			this.timerLabel.text = "" + this.curPattern.clearTime;
		    }
		    this.scoreLabel.text = "" + int(player.score);
		    return;
		}
		
		/*
		 * onLabelPauseTimer(evt)
		 * 
		 * This function is called when the label pause timer is up, so the Level labels will start moving again
		 *
		 * arguments:
		 *    @evt:TimerEvent, the event firing this function
		 *
		 * Returns: none
		 */

		public function onLabelPauseTimer(evt:TimerEvent)
		{
		    this.labelPauseTimer.removeEventListener(TimerEvent.TIMER, this.onLabelPauseTimer);
		    this.labelPauseTimer.stop();
		    // this bumps it past the pixel mark so we don't duplicate the onLabelPauseTimer call and it sits there forever
		    this.levelLabel.y -= 5;
		    this.levelNumberLabel.y == 5.
		}

		/*
		 * onDifficultySelected(evt)
		 *
		 * This function is called whenever the player selects a difficulty level from the main screen starting a new game
		 *
		 * arguments:
		 *    @evt : Event, the event firing this function
		 *
		 * Returns : none
		 */
		public function onDifficultySelected(evt:MouseEvent)
		{
		    var mapping:Dictionary = new Dictionary;
		    // -- this just saves me a long block of if () { ... } , and the use of one-line X ? Y : Z ... 
		    mapping[this.cutscenes["difficultychooser"].easyBtn] = 0;
		    mapping[this.cutscenes["difficultychooser"].normalBtn] = 1;
		    mapping[this.cutscenes["difficultychooser"].hardBtn] = 2;
		    mapping[this.cutscenes["difficultychooser"].wilyBtn] = 3;
		    this.difficulty = mapping[evt.target];

		    this.removeChild(this.cutscenes["difficultychooser"]);
		    this.removeChild(this.cutscenes["intro_menu"]);
		    this.primaryState = Game.STATE_TUTORIAL;
		    this.secondaryState = Game.STATE_TUTORIAL;
		    this.addChild(this.cutscenes["tutorial"]);
		    this.cutscenes["tutorial"].play();
		}

		/*
		 * onHighScoreEntry(evt)
		 * 
		 * This function fires whenever the user clicks any of the buttons on the High Score screen
		 * 
		 * arguments:
		 *    @evt : Event, the event firing this function
		 * 
		 * Returns: none
		 */
		public function onHighScoreEntry(evt:MouseEvent)
		{
		    if ( evt.target == this.cutscenes["highscores"].highScorePostBtn ) {
			// post up the user's high score and spin off a new browser window to the high score area
			var request:URLRequest = new URLRequest("http://atlanta.aklabs.net/~akesterson/wilysays/index.php");
			request.method = URLRequestMethod.POST;
			var variables:URLVariables = new URLVariables();
			variables.op = "store";
			variables.name = this.cutscenes["highscores"].highScoreName.text;
			variables.score = this.player.score;
			variables.maxpattern = this.player.maxPattern;
			request.data = variables;
			sendToURL(request);
			var request:URLRequest = new URLRequest("http://atlanta.aklabs.net/~akesterson/wilysays/index.php");
			navigateToURL(request, "_blank");
		    } else if ( evt.target == this.cutscenes["highscores"].viewScoreBtn) {
			// just send the user to the high scores and return, don't disable any of the buttons or change state
			var request:URLRequest = new URLRequest("http://atlanta.aklabs.net/~akesterson/wilysays/index.php");
			navigateToURL(request, "_blank");
			return;
		    }
		    // go back to the main menu
		    this.removeChild(this.cutscenes["highscores"]);
		    this.addChild(this.cutscenes["intro_menu"]);
		    this.primaryState = Game.STATE_MENU;
		    this.primaryState = Game.STATE_MENU;
		    this.cutscenes["intro_menu"].gotoAndPlay(0);
		}

		/*
		 * clearExplosions()
		 *
		 * This function is ran when the explosion timer is done, and right before the high score screen
		 * is fixing to come up, to make sure that all the explosions are gone from the screen.
		 * 
		 * arguments: none
		 *  
		 * Returns: none
		 */
		public function clearExplosions()
		{
		    var i:Number;
		    for ( i = 0; i < this.explosions.length ; i++ ) {
			this.removeChild(this.explosions[i]);
			this.explosions[i].stop();
			this.explosions.splice(i, 1);
		    }
		}

		/* 
		 * clearGameScreen()
		 *
		 * This function clears the game screen of all play elements (inventory, lives, Mastermind, etc)
		 *
		 * arguments : none
		 * 
		 * returns: none
		 */
		public function clearGameScreen()
		{
		    this.removeChild(this.preloader.getObject("gfx_circuitboard"));
		    this.removeChild(this.preloader.getObject("gfx_background"));
		    this.removeChild(this.simon);
		    this.removeChild(this.timerLabel);
		    this.removeChild(this.scoreLabel);
		    this.removeChild(this.levelLabel);
		    this.removeChild(this.levelNumberLabel);
		    if ( this.curPattern )
			this.removeChild(this.curPattern);
		    this.removeChild(this.player);
		    this.removeChild(this.player.lifeDisplay);
		    
		    this.player.clearInventory();
		    		    
		    this.explosionTimer.reset();
		    this.explosionTimer.delay = 5000;
		    this.explosionTimer.stop();

		}
		
		/*
		 * wonGame()
		 *
		 * This function is called when the player has beaten all 10 levels and therefore won the game
		 * 
		 * arguments: None
		 * 
		 * Returns: None
		 *
		 */  

		public function wonGame()
		{
		    this.clearGameScreen();
		    this.primaryState = Game.STATE_WINGAME;
		    this.secondaryState = Game.STATE_WINGAME;
		    this.addChild(this.cutscenes["endscreen"]);
		    this.cutscenes["endscreen"].play();
		}

		/* gameOver()
		 * 
		 * This function is called whenever the player has lost all of their lives, and achieved Game Over
		 * 
		 * arguments : None
		 * 
		 * Returns : none
		 */
		public function gameOver()
		{
		    this.clearGameScreen();
		    this.primaryState = Game.STATE_HIGHSCORE;
		    this.secondaryState = Game.STATE_HIGHSCORE;
		    this.addChild(this.cutscenes["highscores"]);
		    this.cutscenes["highscores"].play();		    
		}

		/*
		 * nextLevel()
		 * 
		 * This function runs to setup the next level above the previous one
		 * 
		 * arguments : none
		 * 
		 * Returns : none
		 */
		public function nextLevel()
		{
		    this.curLevel += 1;
		    this.levelLabel.y = 500;
		    this.levelNumberLabel.y = -150;
		    this.levelNumberLabel.text = "" + this.curLevel;
		    this.primaryState = Game.STATE_PLAYING;
		    this.secondaryState = Game.STATE_PLAYING_WINLEVEL;
		    this.player.score += this.curPattern.score;
		    this.timerLabel.text = "00000";
		    this.scoreLabel.text = "" + int(player.score);
		    this.newPattern();
		}

		/*
		 * newGame()
		 * 
		 * This function sets up a new game when the player starts a game from the main menu
		 * 
		 * arguments : none
		 * 
		 * Returns: none
		 */
		public function newGame()
		{
		    // difficulty just really changes how long the patterns are and how many levels you play
		    if ( this.difficulty > 1 ) {
			this.curLevel = 3*this.difficulty;
		    } else 
			this.curLevel = 0;
		    this.maxLevel = this.curLevel + (6+this.difficulty);
		    this.player.score = 0;
		    this.player.lives = 3;
		    this.cutscenes["tutorial"].stop();
		    this.cutscenes["highscores"].stop();
		    this.cutscenes["intro_menu"].stop();
		    
		    try {
			this.removeChild(this.cutscenes["tutorial"]);
		    } catch (error:Error) {
			// do nothing, it wasn't a child for some reason.. (I ran into this a couple times but not sure why)
		    }
		    
		    this.addChild(this.preloader.getObject("gfx_circuitboard"));
		    this.addChild(this.preloader.getObject("gfx_background"));
		    this.addChild(this.simon);
		    this.addChild(this.timerLabel);
		    this.addChild(this.scoreLabel);
		    this.addChild(player);
		    this.addChild(player.lifeDisplay);
		    this.addChild(this.levelLabel);
		    this.addChild(this.levelNumberLabel);
		    
		    this.player.x = 0;
		    this.player.y = 480-64;
		    player.lifeDisplay.x = 400;
		    player.lifeDisplay.y = 480-64;
		    this.player.resetLifePositions();
		    
		    this.primaryState = Game.STATE_PLAYING;
		    this.secondaryState = Game.STATE_PLAYING;
		    
		    this.newPattern();
		    this.nextLevel();
		}

		/* 
		 * onExplosionTimer(evt)
		 * 
		 * This function fires when the explosion timeframe is up
		 *
		 * arguments : 
		 *    @evt : Event, the event firing this function
		 *
		 * Returns : none
		 */
		public function onExplosionTimer(evt:TimerEvent)
		{
		    this.primaryState = Game.STATE_PLAYING;
		    this.secondaryState = Game.STATE_PLAYING_WAITING;
		    for ( var i:Number = 0; i < this.explosions.length; i++ ) {
			if ( this.explosions[i].currentFrame != this.explosions[i].totalFrames ) {
			    // some of the explosions aren't done yet, let them finish
			    this.explosionTimer.delay = 1000;
			    this.explosionTimer.start();
			    return;
			}
		    }
		    this.clearExplosions();
		    this.gameOver();
		}

		/* 
		 * onMastermindClicked(evt)
		 *
		 * This function fires whenever the player clicks the mouse on one of the mastermind buttons
		 *
		 * arguments:
		 *    @evt : Event, the event firing this function
		 *
		 * Returns : none
		 */
		public function onMastermindClicked(evt:MastermindEvent)
		{
		    this.checkColorHit(evt.colorClicked);
		}
		
	        /* 
		 * autoForgiveness()
		 * 
		 * This function checkes to see if the player has a Forgiveness powerup in his inventory,
		 * and if it does, it uses it to stop the pattern from blowing out one of the players' lives
		 *
		 * arguments : none
		 * 
		 * Returns : none
		 */ 
		public function autoForgiveness()
		{
		    var pwup:Powerup = null;
		    for ( var i:Number = 0; i < this.player.inventory.length ; i++ ) {
			pwup = this.player.inventory[i];
			if ( pwup.pType == Powerup.PTYPE_FORGIVENESS ) {
			    this.curPattern.forceState(Pattern.STATE_STOPPED);
			    this.player.usePowerupAt(i);
			    break;
			}
		    }
		}
	
		/*
		 * checkColorHit(colorPressed)
		 *
		 * arguments:
		 *    @colorPressed : Number, an integer (e.g. Pattern.COLOR_XXXX) specifying which color the player hit
		 *
		 * Returns: none
		 */  
		public function checkColorHit(colorPressed:Number)
		{
		    if ( this.curPattern.colorActive(colorPressed) == true ) {
			this.simon.lightButton(colorPressed, 100);
			this.preloader.playSound(this.buttonSounds[colorPressed]);
		    } else {
			this.autoForgiveness();
			this.curPattern.stop();
			return;
		    }
		}

		/*
		 * onUsedPowerup()
		 * 
		 * Fired whenever the player uses a powerup 
		 * 
		 * arguments:
		 *   @evt : Event, the event firing this function
		 * 
		 * Returns: none
		 */
		public function onUsedPowerup(evt:PowerupEvent)
		{
		    // the only time we get a powerupevent for used powerups
		    // is when it's the player dispatching one; we have to 
		    // then re-dispatch it so that the pattern will see it,
		    // since it's in the opposite direction for bubbling (things bubble up,
		    // never down). We never actually process them, all powerup handling is
		    // handled between the player & pattern. We just dispatch.
		    this.curPattern.onUsedPowerup(evt);
		}

		/*
		 * newPattern()
		 *
		 * Creates a new pattern object to challenge the player.
		 *
		 * arguments: none
		 * 
		 * Returns: none
		 */
		public function newPattern()
		{
		    try {
			this.removeChild(this.curPattern);
		    } catch (error:Error) {
			// do nothing, it wasn't in our child list yet
		    }
		    this.curPattern = new Pattern(this.curLevel, this.simon, this.difficulty);
		    this.curPattern.addEventListener(PowerupEvent.GOT_POWERUP, this.onGetPowerup);
		    this.curPattern.stop();
		    this.curPattern.forceState(Pattern.STATE_STOPPED);
		    this.curPattern.x = 602;
		    this.curPattern.y = 138;
		    this.addChild(this.curPattern);
		    trace("Finished newPattern()");
		}
	    }
    }