-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()
-- include Corona's "widget" library
local widget = require "widget"

-- include Corona's "physics" library
local physics = require "physics"
physics.start(); physics.pause()

--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW, halfH = display.contentWidth, display.contentHeight, display.contentWidth*0.5, display.contentHeight*0.5
local screenTop = display.screenOriginY
local screenBottom = display.viewableContentHeight + display.screenOriginY
local screenLeft = display.screenOriginX
local screenRight = display.viewableContentWidth + display.screenOriginX
local player;
-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once,
--		 unless storyboard.removeScene() is called.
-- 
-----------------------------------------------------------------------------------------
local scoreTextField
local liveTextField
local messageTextField
local mainMenuBtn
local pauseResumeBtn
local pauseResumeFlag = "Pause";

local health = 100
local lives = 3
local score=0
local scoreToNextLevel= 20
local itemGenerateDelay=200
local player
-- move collector magic power helper
local moveCollector
local bouceCollector

local itemGenerateTimer
local itemGroup
local enemyGroup
local beamGroup
local staticItemGroup
local lancerGroup
local lancerTimer
local axeGroup
local axeTimer

function animate(event)
	if moveCollector then
		bounceInBound(moveCollector)
	end
	if bounceCollector then
		bounceInBound(bounceCollector)
	end
end

function createAxeGroup()
		axeGroup = display.newGroup()
		createAxe()
		--axeTimer = timer.performWithDelay(1000, createAxe, 1)
end

function createLancerGroup()
		lancerGroup = display.newGroup()
		createLancer()
		lancerTimer = timer.performWithDelay( 1000, createLancer, -1 )
end 

-- creat lancer at y randomly half vertical to full vertial range
-- move the  horizontally
function  createLancer()
		print "inside createLancer";
		local lancer = display.newImage("images/weapon/spear1.png", 200, 30)
		lancer.x = -100
		lancer.y = math.random(0, screenH/2) 
		lancer.tag = "enemy"
	    lancer.postCollision=enemyCollisionHandler
	    lancer:addEventListener("postCollision", lancer)
	    lancerGroup:insert(lancer)
		physics.addBody(lancer, {density=1.0, friction=0.2})
		transition.to(lancer, {time=3000, x=2*screenW, transition = easing.inQuad})
end

function  createAxe()
		print "inside createAxe";
		local axe = display.newImage("images/weapon/axe.png", 50, 30)
		axe.x = halfW
		axe.y = 0 
		axe.tag = "enemy"
		axe:setReferencePoint( display.TopCenterReferencePoint )
		--axe.rotation = 90
	    axe.postCollision=enemyCollisionHandler
	    axe:addEventListener("postCollision", axe)
	    axeGroup:insert(axe)
		--physics.addBody(axe, {density=1.0, friction=0.2})
		transition.to(lancer, {time=3000,rotaion=360, transition = easing.inoutQuad})
end

-- helper function to bound the given item mc within  rectangle window
function bounceInBound(mc) 
    --print "inside bounceInBound"
    if mc then
    else
         print "mc is null"
        return
    end
	mc.x1 = mc.x1 + mc.vx * mc.xdir;
	mc.y1 = mc.y1+ mc.vy * mc.ydir

	if ( mc.x1 > screenRight - mc.radius or mc.x1 < screenLeft + mc.radius ) then
		mc.xdir = mc.xdir * -1;
	end
	if ( mc.y1 > screenBottom - mc.radius or mc.y1 < screenTop + mc.radius ) then
		mc.ydir = mc.ydir* -1;
	end

	mc:translate( mc.x1 - mc.x, mc.y1 - mc.y)
end

Runtime:addEventListener( "enterFrame", animate );
-- pause the game
local function pauseGame()
 		print "pausing"
 		pauseResumeFlag = "Resume"
 		pauseResumeBtn.text = "Resume"
 		physics.pause()
 		if itemGenerateTime then
 			timer.pause(itemGenerateTimer)
 		end
 		if lancerTime then
 			timer.pause(lancerTimer)
 		end
 		Runtime:removeEventListener( "enterFrame", animate );
end

--resume the game
local function resumeGame()
 	    print "Resuming"
 	    pauseResumeFlag = "Pause"
 	    pauseResumeBtn.text = "Pause"
 	    physics.start()
 	    if itemGenerateTimer then
 	    	timer.resume(itemGenerateTimer)	
 	    end
 	    if lancerTimer then
 	    	timer.resume(lancerTimer)
 	    end
 	    Runtime:addEventListener( "enterFrame", animate );
 end
--pause the item generate timer
local function onPauseResumeBtnRelease()
	 if pauseResumeBtn then
	 	print( "button text" .. pauseResumeFlag)
	 	if pauseResumeFlag == "Pause" then
			pauseGame()
	 	else
			resumeGame()
	 	end
	 end
	return true	-- indicates successful touch
end

-- go to the main menu
local function gotoMainMenuScene() 
		storyboard.gotoScene( "menu", "fade", 500 )
end
-- level complete
local function levelComplete(gameState)
	pauseGame()
	--mainMenuBtn.label ="Main Menu"
	if gameState == "Success" then
		messageTextField.text = "Level Completed"
	else
		messageTextField.text = "Try again"
	end
	messageTextField.isVisible  = true
	mainMenuBtn.isVisible = true
end
-- main menu button handler
local function onMainMenuBtnRelease() 
		gotoMainMenuScene()
end

-- add beam slant
local function addBeam1()
	local beam = display.newImage( "images/obstacles/beam.png" )
	beam.x = 20; beam.y = 250; beam.rotation = -40
	beamGroup:insert(beam)
	physics.addBody( beam, "static", { friction=0.5 } )
end

-- add beam 2 straight
local function addBeam2()
	local beam = display.newImage( "images/obstacles/beam_long.png" )
	beam.x = 280; beam.y = 150
	beamGroup:insert(beam)
	physics.addBody( beam, "static", { friction=0.5 } )	
end

-- add beam group
local function addBeamGroup()
	beamGroup = display.newGroup()
	addBeam1()
	addBeam2()
end

local function destroyItemOnCollsion( self, event )
	if event.other.tag =="player" or event.other.tag =="land" or event.other.tag == "collector"  then
	 	self:removeSelf()
	 	--print ("event other tag:" .. event.other.tag);
	 	if(event.other.tag =="collector") then
	 		--print "collector collide"
	 	end
	 	if event.other.tag == "player" or event.other.tag == "collector"  then
		 	score = score + 1
		 	if scoreTextField then
		 		scoreTextField.text="score:"..score
		 	end
		 	if score >=scoreToNextLevel then
					levelComplete("Success")
		 	end
	 	end
	end
end
	
local function createNormalItem()
	local item = display.newImageRect("images/fruit/star_fruit.png",50,50)
	item.y=-100
	item.x = 50+math.random( screenW )
	item.tag="item"
	item.postCollision=destroyItemOnCollsion
	item:addEventListener("postCollision", item)
	if itemGroup then
	itemGroup:insert(item)
	else 
	itemGroup = display.newGroup()
	itemGroup:insert(item)
	end

	physics.addBody( item ,  "dynamic", { density=1.0, friction=0.7, bounce=0.0 } )
end

-- this will create horizontal move collector at the floor
-- which go forth and back , collect the  item it touches
local function createMoveCollector()
	moveCollector = display.newImageRect("images/obstacles/crateB.png", 50, 50)
	moveCollector.vx = 1
	moveCollector.vy = 0
	moveCollector.xdir = 1
	moveCollector.ydir = 1
	moveCollector.radius = 5
	moveCollector.x1 = halfW
	moveCollector.y1 = halfH+100
	moveCollector.x, moveCollector.y = halfW, halfH
	moveCollector.tag = "collector"
	physics.addBody( moveCollector ,  { density=1.0, friction=0.7, bounce=0.0 } )
end

local function createBounceCollector()
	print "inside createBounceCollector"
    bounceCollector = display.newImageRect("images/seed/coconut1.png", 50, 50)
	bounceCollector.vx = 1
	bounceCollector.vy = 1
	bounceCollector.xdir = 1
	bounceCollector.ydir = 1
	bounceCollector.radius = 5
	bounceCollector.x1 = halfW
	bounceCollector.y1 = halfH
	bounceCollector.x, bounceCollector.y = halfW, halfH
	bounceCollector.tag = "collector"
	physics.addBody( bounceCollector ,  { density=1.0, friction=0.7, bounce=0.0 } )
end


-- decrease player health by noLiveToTake
-- if lives <=0 it will will display No Life message , Main Menu Button
local function decreaseLife(noLivesToTake)
	if lives >0 then
		lives = lives - 1
		 if liveTextField then
		 	liveTextField.text="live:"..lives
		 end
	end
 	if lives <= 0 then
 		print "No life, pleae try again"
 		levelComplete("No Life")
 	end
end

function enemyCollisionHandler( self, event )
	if event.other.tag == "player" or event.other.tag == "land"  then
	 	self:removeSelf()
	 	if event.other.tag == "player"  then
		 	decreaseLife(1)
	 	end
	end
end
local function createEnemyItem()
	local enemy = display.newImageRect("images/insect/honey_bee2.png",50,50)
	enemy.y=-100
	enemy.x = 50+math.random( screenW )
	enemy.tag="enemy"
	enemy.postCollision=enemyCollisionHandler
	enemy:addEventListener("postCollision", enemy)
	
	enemyGroup:insert(enemy)
	
	physics.addBody( enemy ,  "dynamic", { density=1.0, friction=0.7, bounce=0.0 } )
end

local function itemFall(event)
	 local rval = math.random(10)
	 if rval < 9 then
	 	createNormalItem()
	 else
	 	createEnemyItem()
	 end
end 



-- Called when the scene's view does not exist:
-- A basic function for dragging physics objects
local function startDrag( event )
	local t = event.target

	local phase = event.phase
	if "began" == phase then
		display.getCurrentStage():setFocus( t )
		t.isFocus = true

		-- Store initial position
		t.x0 = event.x - t.x
		t.y0 = event.y - t.y
		
		-- Make body type temporarily "kinematic" (to avoid gravitional forces)
		event.target.bodyType = "kinematic"
		
		-- Stop current motion, if any
		if event.target then
			--event.target:setLinearVelocity( 0, 0 )
			--event.target.angularVelocity = 0
		end

	elseif t.isFocus then
		if "moved" == phase then
			t.x = event.x - t.x0
			t.y = event.y - t.y0

		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
			
			-- Switch body type back to "dynamic", unless we've marked this sprite as a platform
			if ( not event.target.isPlatform ) then
				event.target.bodyType = "dynamic"
			end

		end
	end

	-- Stop further propagation of touch event!
	return true
end
function scene:createScene( event )
	local group = self.view
		print( "create scene" )
	-- create a grey rectangle as the backdrop
	local background = display.newRect( 0, 0, screenW, screenH )
	background:setFillColor( 128 )
	
	--pause resume button
	pauseResumeBtn = widget.newButton{
		label="Pause",
		labelColor = { default={255}, over={128} },
		--defaultFile="button.png",
		--overFile="button-over.png",
		width=100, height=40,
		onRelease = onPauseResumeBtnRelease	-- event listener function
	}
	
	pauseResumeBtn:setReferencePoint( display.CenterReferencePoint )
	pauseResumeBtn.x = display.contentWidth*0.80
	pauseResumeBtn.y = 50

	--player
	player = display.newImageRect( "images/character/player_monkey.png",50,50 )
	player.x = 80; player.y = screenH-100
	player.tag="player"
	physics.addBody( player, "kinematic", { friction=0.7 } )
	player.isPlatform = true -- custom flag, used in drag function above
	player:addEventListener( "touch", startDrag )
	
	--score text field
	scoreTextField = display.newText("Score:"..score, 15, 30, native.systemFont, 14)
    scoreTextField:setTextColor( 255, 255, 255 );    
    
    --live text field
	liveTextField = display.newText("Live:"..lives, 150, 30, native.systemFont, 14)
    liveTextField:setTextColor( 255, 255, 255 );    
    
    --message text field
    messageTextField = display.newText("Start", halfW, halfH-50, native.systemFont, 16)
    messageTextField:setTextColor( 255, 255, 255 );    
    messageTextField.isVisible = false
    
    -- main menu button
	mainMenuBtn = widget.newButton{
		label="Main Menu",
		labelColor = { default={255}, over={128} },
		--defaultFile="button.png",
		--overFile="button-over.png",
		width=150, height=50,
		onRelease = onMainMenuBtnRelease	-- event listener function
	}
	
	mainMenuBtn:setReferencePoint( display.CenterReferencePoint )
	mainMenuBtn.x = halfW
	mainMenuBtn.y = halfH + 50
    
	-- create a grass object and add physics (with custom shape)
	local grass = display.newImageRect( "grass.png", screenW, 82 )
	grass:setReferencePoint( display.BottomLeftReferencePoint )
	grass.x, grass.y = 0, display.contentHeight
	grass.tag = "land"
	
	-- define a shape that's slightly shorter than image bounds (set draw mode to "hybrid" or "debug" to see)
	local grassShape = { -halfW,-34, halfW,-34, halfW,34, -halfW,34 }
	physics.addBody( grass, "static", { friction=0.3, shape=grassShape } )
	
	-- all display objects must be inserted into group
	group:insert( background )
	group:insert( grass)
	--group:insert(player)
	--

	enemyGroup = display.newGroup()
	--addBeamGroup()
	--createBounceCollector()
	--createMoveCollector()
	--createLancerGroup()
	--createAxeGroup()
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view
	    -- score 
    score = 0
     print( "entering scene" )
    print "creating itemGenerateTimer"
	itemGenerateTimer = timer.performWithDelay( itemGenerateDelay, itemFall, -1 )
	itemGroup = display.newGroup()
	group:insert(itemGroup)
	physics.start()
	pauseResumeBtn.isVisible = true
    player.isVisible = true
	scoreTextField.isVisible = true
	live = 3
	liveTextField.text = "Live:" .. live
	liveTextField.isVisible = true
	messageTextField.isVisible = false
	mainMenuBtn.isVisible  = false
	itemGroup.isVisible = true
	enemyGroup.isVisible = true
	if beamGroup then
		beamGroup.isVisible = true
	end
    if moveCollector then
	 	moveCollector.isVisible = true
	 end
	 if bounceCollector then
	 	bounceCollector.isVisible = true
	 end
	 if lancerGroup then
	 	 lancerGroup.isVisible = true;
	 end
	 if axeGroup then
	 	 axeGroup.isVisible = true;
	 end
	print "resuming the itemGenerateTimer"
	--timer.resume( itemGenerateTimer )
	print "after resuming the itemGeneratTimer"
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	local group = self.view
	print( "exit scene" )
	player.isVisible = false
	scoreTextField.text="Score:0"
	scoreTextField.isVisible = false
	liveTextField.isVisible = false
	messageTextField.isVisible = false
	mainMenuBtn.isVisible = false
	 if itemGroup then
	 	itemGroup:removeSelf()
	 	itemGroup = nil
	 end
	 enemyGroup.isVisible = false
	 if beamGroup then
	 	beamGroup.isVisible = false
	 end
	 if moveCollector then
	 	moveCollector.isVisible = false
	 end
	 if bounceCollector then
	 	bounceCollector.isVisible = false
	 end
	 
	 if lancerGroup then
	 	 lancerGroup.isVisible = false;
	 end
	 if axeGroup then
	 	 axeGroup.isVisible = false;
	 end
	pauseResumeBtn.isVisible = false
	
	print "stopping physics, pausing itemGenerator timer"
	--physics.stop()
	--timer.pause( itemGenerateTimer )
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	local group = self.view
	print( "destroy scene" )

	if itemGenerateTimer then
		timer.cancel(itemGenerateTimer)
		itemGenerateTimer = nil
	end
	if scoreTextField then
		scoreTextField:removeSelf()
		scoreTextField = nil
	end
	
	if liveTextField then
		liveTextField:removeSelf()
		liveTextField = nil
	end
	
	if messageTextField then
		messageTextField:removeSelf()
		messageTextField = nil
	end
	
	if  mainMenuBtn then
		mainMenuBtn:removeSelf()
		mainMenuBtn = nil
	end
	
	if enemyGroup then
		enemyGroup:removeSelf()
		enemyGroup = nil
	end
	
	if itemGroup then
		itemGroup:removeSelf()
		itemGroup = nil
	end
	
	if  beamGroup then
		beamGroup:removeSelf()
		beamGroup = nil
	end
    if lancerGroup then
	 	 lancerGroup.removeSelf()
	 	 lancerGroup = nil
	 end
	if axeGroup then
		axeGroup:removeSelf()
		axeGroup=nil
	end
	
	if player then
		player:removeSelf()
		player=nil
	end

	package.loaded[physics] = nil
	physics = nil
end

-----------------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
-----------------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched whenever before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )


-----------------------------------------------------------------------------------------

return scene;
