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
local itemGenerateTimer
local itemGroup
local enemyGroup
local actorGroup
local guiGroup

-- pause the game
local function pauseGame()
 		print "pausing"
 		pauseResumeFlag = "Resume"
 		pauseResumeBtn.text = "Resume"
 		physics.pause()
 		if itemGenerateTimer then
 			timer.pause(itemGenerateTimer)
 		end
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
	    print "pressed main menu button"
		gotoMainMenuScene()
end

local function destroyItemOnCollsion( self, event )
	if event.other.tag =="player" or event.other.tag =="land"  then
	 	self:removeSelf()
	 	if event.other.tag == "player" then
		 	score = score + 1
			 updateScoreGui()
		 	if score >=scoreToNextLevel then
					levelComplete("Success")
		 	end
	 	end
	end
end
	
function  updateScoreGui()
	if scoreTextField then
		scoreTextField.text = "Score:" .. score
	end
end

function updateLiveGui()
    if liveTextField then
		liveTextField.text = "Live:" .. lives
    end
end

local function addToActorGroup(cgroup)
	if not actorGroup then
		actorGroup = display.newGroup()
		actorGroup:insert(cgroup)
	else
		actorGroup:insert(cgroup)
	end
end

local function addToItemGroup(item)
	if itemGroup then
		itemGroup:insert(item)
	else 
		itemGroup = display.newGroup()
		addToActorGroup(actorGroup)
		itemGroup:insert(item)
	end
end

local function addToGuiGroup(gui)
	  if guiGroup then
	  	guiGroup:insert(gui)
	  else
	      guiGroup = display.newGroup()
	      guiGroup:insert(gui)
	  end
end

local function createNormalItem()
	local item = display.newImageRect("images/fruit/star_fruit.png",50,50)
	item.y=-100
	item.x = 50+math.random( screenW )
	item.tag="item"
	item.postCollision=destroyItemOnCollsion
	item:addEventListener("postCollision", item)

    addToItemGroup(item)

	physics.addBody( item ,  "dynamic", { density=1.0, friction=0.7, bounce=0.0 } )
end

-- decrease player health by noLiveToTake
-- if lives <=0 it will will display No Life message , Main Menu Button
local function decreaseLife(noLivesToTake)
	if lives >0 then
		lives = lives - 1
		updateLiveGui()
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

local function addToEnemyGroup(enemy)
	 if  enemyGroup then
	 else
		enemyGroup = dispaly.newGroup()
		addToActorGroup(enemyGroup)
	end
	enemyGroup:insert(enemy)
end
local function createEnemyItem()
	local enemy = display.newImageRect("images/insect/honey_bee2.png",50,50)
	enemy.y=-100
	enemy.x = 50+math.random( screenW )
	enemy.tag="enemy"
	enemy.postCollision=enemyCollisionHandler
	enemy:addEventListener("postCollision", enemy)

	addToEnemyGroup(enemy)
	
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
		width=100, height=40,
		onRelease = onPauseResumeBtnRelease	-- event listener function
	}
	pauseResumeBtn:setReferencePoint( display.CenterReferencePoint )
	pauseResumeBtn.x = display.contentWidth*0.80
	pauseResumeBtn.y = 50
	addToGuiGroup(pauseResumeBtn)

	--player
	player = display.newImageRect( "images/character/player_monkey.png",50,50 )
	player.x = 80; player.y = screenH-100
	player.tag="player"
	physics.addBody( player, "kinematic", { friction=0.7 } )
	player.isPlatform = true -- custom flag, used in drag function above
	player:addEventListener( "touch", startDrag )
	addToActorGroup(player)
	
	--score text field
	scoreTextField = display.newText("", 30, 30, native.systemFont, 14)
    scoreTextField:setTextColor( 255, 255, 255 );  
    updateScoreGui()  
    addToGuiGroup(scoreTextField)
    
    --live text field
	liveTextField = display.newText("", 150, 30, native.systemFont, 14)
    liveTextField:setTextColor( 255, 255, 255 );    
    updateLiveGui()
    addToGuiGroup(liveTextField)
    
    --message text field
    messageTextField = display.newText("Start", halfW, halfH-50, native.systemFont, 16)
    messageTextField:setTextColor( 255, 255, 255 );    
    messageTextField.isVisible = false
    addToGuiGroup(messageTextField)
    
    -- main menu button
	mainMenuBtn = widget.newButton{
		label="Main Menu",
		labelColor = { default={255}, over={128} },
		width=150, height=50,
		onRelease = onMainMenuBtnRelease	-- event listener function
	}
	mainMenuBtn:setReferencePoint( display.CenterReferencePoint )
	mainMenuBtn.x = halfW
	mainMenuBtn.y = halfH + 50
    addToGuiGroup(mainMenuBtn)
    
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
	group:insert(actorGroup)
	group:insert(guiGroup)
	
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view
    print( "entering scene" )
    print "creating itemGenerateTimer"
	-- score 
    score = 0
    updateScoreGui()
    lives = 3
    updateLiveGui()
    player.x = 80; player.y = screenH-100
	itemGenerateTimer = timer.performWithDelay( itemGenerateDelay, itemFall, -1 )
	itemGroup = display.newGroup()
	group:insert(itemGroup)
	enemyGroup = display.newGroup()
	group:insert(enemyGroup)
	guiGroup = display.newGroup()
	group:insert(guiGroup)
	physics.start()
	guiGroup.isVisible = true
	messageTextField.isVisible = false
	mainMenuBtn.isVisible  = false
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	print( "exit scene" )
	local group = self.view
	if itemGenerateTimer then
	 	timer.cancel(itemGenerateTimer)
	 	itemGenerateTimer = nil
	 end
	 
	 if itemGroup then
	 	itemGroup:removeSelf()
	 	itemGroup = nil
	 end
	 if enemyGroup then
	 	enemyGroup:removeSelf()
	 	enemyGroup = nil
	 end
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	print( "destroy scene" )
	local group = self.view
	
	if player then
		player:removeSelf()
		player = nil
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
