-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------
-- TODO: Disallow darker colored generated objects OR change background color
-- TODO: Add non-bar obstacles
-- TODO: Add ads

-- TODO: Restarting the game too quickly after a gameover causes a runtime error with physics

-- TODO: set some temporary speed so that the difficulty returns to it instead
-- 		of starting from the beginning
--  In order to do this, convert generateObstacle into a function that takes params
--    generationDelay, gameSpeed should be params




local score = require("score")
local screen = require("screen")
-- local physics = require("physics")
local composer = require( "composer" )
local scene = composer.newScene()

-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX

function scene:create( event )
	local physics = require ("physics")

	-- Called when the scene's view does not exist.

	local sceneGroup = self.view

	physics.start()
	physics.pause()

  physics.setGravity( 0, 0 )
  physics.setReportCollisionsInContentCoordinates( true )

	local ballXPos = display.contentCenterX / 4
	local wiggleRoom = 15

	local ballRadius = 10
	local ball1 = display.newCircle(ballXPos, display.contentCenterY, ballRadius)
	ball1:setFillColor(1,0,0)
	local ball2 = display.newCircle(ballXPos, display.contentCenterY, ballRadius)


	physics.addBody( ball1, 'static' )
	physics.addBody( ball2, 'static' )


	local scoreBoard = display.newText({text = "0", x = display.contentCenterX, y = 0})

  local best = score.getCurBest()
  local bestScore = display.newText({text = "best: "..best, x = 40, y = 0})

  local gameSpeed = 200

  -- higher sensitivity = more balls movement per finger travel
  local sensitivity = 2.0

  local startY = 0
  local touchInterval = 0

  -- super mode will be activated by an item that allows ball to break through obstacles
  local superMode = false

  -- stores individual obstacle objects for garbage collection
  local obstaclesList = {}

  local itemsList = {}



  local gameover = false

  -- time elapsed between obstacles
  local generationDelay = 1000

  -- how far obstacles need to travel outside the screen to be deleted
  local buffer = 20

  -- width for the bar-like obstacles
  local rectangularObstacleWidth = 20

  local invincibilityChance = 1
	local invincibilityDelay = 1000

	local xCenter = display.contentCenterX
	local yCenter = display.contentCenterY



	local function moveBallsTo(ball1To, ball2To)
		-- time = 0  for instant feedback
		transition.to(ball1, {y = ball1To, time = 0})
		transition.to(ball2, {y = ball2To, time = 0})
	end


  -- handles player movement
  local function touchListener(event)
    if (event.phase == "began") then
      startY = event.y
    elseif (event.phase == "moved") then
      touchInterval = event.y - startY

      -- if the balls are past the middle line, move them back to the middle and
			--  only allow outward movement
      if (ball1.y > display.contentCenterY) then
				moveBallsTo(yCenter, yCenter)
        if (touchInterval < 0) then
					moveBallsTo(ball1.y + touchInterval * sensitivity, ball2.y - touchInterval * sensitivity)
        end
      -- if the balls go outside the screen, move them back inside
      elseif (ball1.y < 0) then
				moveBallsTo(0, display.contentHeight)
      -- If the balls are at the edge of the screen, only allow inward movement
      elseif (ball1.y == 0) then
        if (touchInterval > 0) then
					moveBallsTo(ball1.y + touchInterval * sensitivity, ball2.y - touchInterval * sensitivity)
        end
      -- if balls are in the center, only allow outward movement
			elseif (ball1.y == yCenter) then
        if (touchInterval < 0) then
					moveBallsTo(ball1.y + touchInterval * sensitivity, ball2.y - touchInterval * sensitivity)
        end
			-- in the typical case, upswipe == outward, downswipe = inward
      else
				moveBallsTo(ball1.y + touchInterval * sensitivity, ball2.y - touchInterval * sensitivity)
      end
      startY = event.y
    end
  end

  -- deletes off-screen obstacles from physics space and display space
  local function collectGarbageObstacles()
    -- set out-of-bounds area
    local minX = 0 - buffer
    local maxX = display.contentWidth + buffer
    local minY = 0 - buffer
    local maxY = display.contentHeight + buffer

    local indicesToDelete = {}
    -- if obstacles is out of bounds, delete all of its components
    local shouldBeRemoved = false
    for i = 1, table.getn(obstaclesList) do
      if screen.isOutOfBounds(minX, maxX, minY, maxY, obstaclesList[i]) then
        for j = 1, table.getn(obstaclesList[i]) do
          physics.removeBody(obstaclesList[i][j])
          display.remove( obstaclesList[i][j] )
          shouldBeRemoved = true
        end
      end
      if shouldBeRemoved then
        table.insert( indicesToDelete, i )
        shouldBeRemoved = false
      end
    end

		-- remove objects from the end to prevent deleting non-garbage obstacles
    for i = #indicesToDelete, 1, -1 do
      table.remove( obstaclesList, indicesToDelete[i] )
    end
  end


	local function colorCycle(obj, curcolor)
		-- local newR = curcolor[1] + 0.1
		-- local newG = curcolor[2] + 0.2
		-- local newB = curcolor[3] + 0.3
		-- if newR > 1 then
		-- 	newR = 1 - newR
		-- end
		-- if newG > 1 then
		-- 	newG = 1- newG
		-- end
		-- if newB > 1 then
		-- 	newB = 1 - newB
		-- end
		-- obj:setFillColor(newR, newG, newB)
		obj:setFillColor(math.random(), math.random(), math.random())
		local colorClosure = function() return colorCycle(obj, {newR, newG, newB}) end
		timer.performWithDelay(100, colorClosure)
	end


	-- creates pulsing effect for objects (used for items)
	-- @param obj object in question
	-- @param isGrowing boolean for indicating if the next call should shrink or grow
	local function pulse(obj, isGrowing)
		if isGrowing then
			transition.to(obj, {xScale = 1.2, yScale = 1.2, time = 200})
			local closure = function() return pulse(obj, false) end
			timer.performWithDelay(200, closure)
		else
			transition.to(obj, {xScale = 0.8, yScale = 0.8, time = 200})
			local closure = function() return pulse(obj, true) end
			timer.performWithDelay(200, closure)
		end
	end



  -- function to generate the invincibility item
  local function generateInvincibility()
		-- only generate invincibility if not already invincible
		if not superMode then
	    if (math.random() < invincibilityChance) then
	      -- local item = display.newRect(display.contentWidth + 10, math.random(0, display.contentHeight), 20, 20)
				local item = display.newCircle( display.contentWidth + 10, math.random(0, display.contentHeight), 10)
	      physics.addBody(item, "dynamic")
	      item:setLinearVelocity( -gameSpeed, 0)
				local curcolor = {math.random(), math.random(), math.random()}
				item:setFillColor(unpack(curcolor))
				item.isSensor = true

				table.insert(itemsList, item)
				local closure = function() return pulse(item, false) end
				timer.performWithDelay(200, closure, curcolor)

				local colorClosure = function() return colorCycle(item, curcolor) end
				timer.performWithDelay(100, colorClosure)
	    end
		end
		if not gameover then
			invincibilityGenerationTimer = timer.performWithDelay( invincibilityDelay, generateInvincibility)
		end
  end


  -- generates the obstacles. could be composed of up to 3 parts (for two balls)
  local function generateObstacle(delay, speed)
    collectGarbageObstacles()
    if not gameover then
			-- lines made up of obstacles of equal length. Between 10 and 50 obstacles
			-- Breaking through these should be satisfying
      if superMode then
				local numSubLines = math.random(10, 35)
        local line = {}
        local subLineLength = display.contentHeight / numSubLines
        for i = 1, numSubLines do
          table.insert(line, display.newRect(display.contentWidth - 10, (subLineLength / 2) * ((2 * i) - 1), 10, subLineLength))
          line[i]:setFillColor((math.random() + 1) / 2,(math.random() + 1) / 2,(math.random() + 1 / 2))
          physics.addBody( line[i])
          line[i]:setLinearVelocity(-speed, 0)
        end
        table.insert( obstaclesList, line )
      else
        if (math.random() < .3) then
          -- 30% chance of generating single-hole obstacles
          -- generate obstacles from outside the screen to the right
          local top = display.newRect(display.contentWidth - 10, display.contentCenterY / 2  - ballRadius - wiggleRoom, rectangularObstacleWidth, display.contentHeight / 2)
          local bottom = display.newRect(display.contentWidth - 10, display.contentCenterY / 2 * 3 + ballRadius + wiggleRoom, rectangularObstacleWidth, display.contentHeight / 2)

          top:setFillColor((math.random() + 1) / 2,(math.random() + 1) / 2,(math.random() + 1 / 2))
          bottom:setFillColor((math.random() + 1) / 2,(math.random() + 1) / 2,(math.random() + 1 / 2))

          physics.addBody(top)
          physics.addBody(bottom)

          top:setLinearVelocity(-speed, 0)
          bottom:setLinearVelocity(-speed, 0)

          -- removes either top or bottom obstacle with 50% chance
					if (math.random() < 0.1) then
						if (math.random() < 0.5) then
							physics.removeBody( top )
	            display.remove(top)
	            table.insert( obstaclesList,  {bottom})
						else
							physics.removeBody( bottom )
	            display.remove(bottom)
	            table.insert(obstaclesList, {top})
						end
					else
						table.insert(obstaclesList, {top, bottom})
					end
        else
          -- 70% chance of generating double-hole obstacles
					local obstacleOriginX = display.contentWidth - 10
          local distanceBetweenBalls = math.random(100, display.contentHeight - 100)
          local upDownHeights = (display.contentHeight - (2 * (2 * ballRadius + 2 * wiggleRoom)) + (2 * ballRadius) - distanceBetweenBalls) / 2
          local middleHeight = distanceBetweenBalls - (2 * ballRadius)

          local top = display.newRect(obstacleOriginX, upDownHeights / 2, rectangularObstacleWidth, upDownHeights)
          local middle = display.newRect(obstacleOriginX, display.contentCenterY, rectangularObstacleWidth, middleHeight)
          local bottom = display.newRect(obstacleOriginX, display.contentHeight - upDownHeights / 2, rectangularObstacleWidth, upDownHeights)

          top:setFillColor((math.random() + 1) / 2,(math.random() + 1) / 2,(math.random() + 1 / 2))
          middle:setFillColor((math.random() + 1) / 2,(math.random() + 1) / 2,(math.random() + 1 / 2))
          bottom:setFillColor((math.random() + 1) / 2,(math.random() + 1) / 2,(math.random() + 1 / 2))

          physics.addBody(top)
          physics.addBody(middle)
          physics.addBody(bottom)

          top:setLinearVelocity(-speed,0)
          middle:setLinearVelocity(-speed,0)
          bottom:setLinearVelocity(-speed,0)

          -- TODO: this is a sloppy way of adding variety. Change it
          if (math.random() < .1) then
            physics.removeBody( top )
            display.remove(top)
            table.insert( obstaclesList,  {middle, bottom})
          elseif (math.random() < .2) then
            physics.removeBody( bottom )
            display.remove(bottom)
            table.insert(obstaclesList, {top, middle})
          elseif (math.random() < .3) then
            physics.removeBody( middle )
            display.remove(middle)
            table.insert(obstaclesList, {top, bottom})
          else
            table.insert(obstaclesList, {top, middle, bottom})
          end
        end
      end
    end

    if not gameover then
			-- delay - 1 narrows gaps between obstaclesList
			-- gameSpeed + 1 makes them slightly faster than before
			local closure = function() return generateObstacle(delay - 1, gameSpeed + 1) end
			obstacleGenerationTimer = timer.performWithDelay(delay, closure)
    end
    if not superMode then
			-- TODO: should probably handle this in the layer that calls this function
      generationDelay = generationDelay - 1
    end

    rectangularObstacleWidth =  math.random(10, 50)
  end


  -- helper function to check object membership in a list
  local function contains(item, list)
    for i = 1, table.getn(list) do
      if item == list[i] then
        return true
      end
    end
    return false
  end

	-- manually applies a force on all obstacles in the obstaclesList. Called
	--  after invincibility sequence to clear screen of stray obstacles
  local function applyForceOnAll(magnitude)
    for i = 1, table.getn(obstaclesList) do
      for j = 1, table.getn(obstaclesList[i]) do
        -- local xComp = obstaclesList[i][j].x - display.contentCenterX
        -- local xComp = obstaclesList[i][j].x - ballXPos
        local xComp = obstaclesList[i][j].x - ball1.x

        -- local yComp = obstaclesList[i][j].y - display.contentCenterY
        -- local yComp = obstaclesList[i][j].y - display.contentCenterY
        local yComp = obstaclesList[i][j].y - ball1.y
        local length = math.sqrt(xComp * xComp + yComp * yComp)
        xComp = xComp / length
        yComp = yComp / length

        obstaclesList[i][j]:applyForce(xComp * magnitude, yComp * magnitude, 0, 0)

        xComp = obstaclesList[i][j].x - ball2.x
        yComp = obstaclesList[i][j].y - ball2.y
        length = math.sqrt(xComp * xComp + yComp * yComp)
        xComp = xComp / length
        yComp = yComp / length
        obstaclesList[i][j]:applyForce(xComp * magnitude, yComp * magnitude, 0, 0)
      end
    end
  end

  local timesCalled = 0
  local function disableInvincibility()
    timer.cancel( obstacleGenerationTimer )
		-- moves the balls back to their original x position
		transition.to(ball1, {x = ballXPos, time = 1200})
		transition.to(ball2, {x = ballXPos, time = 1200})
    if table.getn(obstaclesList) == 0 then
      generationDelay = 1000
      gameSpeed = 200
			local closure = function() return generateObstacle(generationDelay, gameSpeed) end
      obstacleGenerationTimer = timer.performWithDelay(generationDelay, closure)
      superMode = false
    else
      if timesCalled > 2 then
        timer.performWithDelay(500, applyForceOnAll(10))
        timesCalled = 0
      end
      timesCalled = timesCalled + 1
      timer.performWithDelay( 500, disableInvincibility )
    end
  end

  local function enableInvincibility()
		-- move the balls towards the center a little to indicate activation to player
		transition.to(ball1, {x = ballXPos * 4, time = 1000})
		transition.to(ball2, {x = ballXPos * 4, time = 1000})

		-- reset obstacle params.
		timer.cancel(obstacleGenerationTimer)
    generationDelay = 100
    gameSpeed = 1000
    superMode = true
		local closure = function() return generateObstacle(generationDelay, gameSpeed) end
		timer.performWithDelay( generationDelay, closure )
    timer.performWithDelay( 5000, disableInvincibility)
  end


	local function emptyObstaclesList()
		for i = 1, table.getn(obstaclesList) do
			for j = 1, table.getn(obstaclesList[i]) do
				physics.removeBody(obstaclesList[i][j])
				display.remove(obstaclesList[i][j])
			end
		end
		obstaclesList = {}
	end

	local function emptyItemsList()
		for i = 1, table.getn(itemsList) do
			print("in emptyItemsList "..table.getn(itemsList))
			if itemsList[i] then
				physics.removeBody( itemsList[i] )
				display.remove( itemsList[i] )
			end
		end
		itemsList = {}
	end

	local function onBackButtonTap()
		emptyItemsList()
		emptyObstaclesList()
		composer.removeScene( "level1", false )
		composer.gotoScene( "menu" )
	end

  local collisionVisualizer
  local obstacleGenerationTimer
  local invincibilityGenerationTimer
  local gameOverMessage
  local replayMessage
	local onTap
	local replayButton
	local backButton

  -- use collisions to end game
  local function collisionEvent(event)
    -- handling item-getting
    if (contains(event.object1, itemsList)) then
      if ((event.object2 == ball1) or (event.object2 == ball2)) then
        if not gameover then
          -- display.remove(event.object1)
          event.object1.isVisible = false
          enableInvincibility()
        end
      end
    -- more handling item-getting
    elseif (contains(event.object2, itemsList)) then
      if ((event.object1 == ball1) or (event.object1 == ball2)) then
        if not gameover then
          -- display.remove(event.object2)
          event.object2.isVisible = false
          enableInvincibility()
        end
      end
    -- typical case for collision
    else
      if superMode then
        -- do nothing?
      else
        --
        if not gameover then -- end the game
          timer.cancel( obstacleGenerationTimer )
          timer.cancel( invincibilityGenerationTimer)
          gameOverMessage = display.newText({text = "Game Over", x = display.contentCenterX, y = display.contentCenterY, fontSize = 12})
          transition.to(gameOverMessage, {xScale = 2, yScale = 2, time = 2000})
					sceneGroup:insert(gameOverMessage)



					replayButton = display.newImageRect("retry.png", 64, 64)
					replayButton.x = display.contentCenterX - 32
					replayButton.y = display.contentCenterY + 50
					replayButton:addEventListener("tap", onTap)
					sceneGroup:insert(replayButton)

					backButton = display.newImageRect("back-to-menu.png", 64, 64)
					backButton.x = display.contentCenterX + 32
					backButton.y = display.contentCenterY + 50
					backButton:addEventListener("tap", onBackButtonTap)
					sceneGroup:insert(backButton)

          superMode = false

          score.updateBest(tonumber( scoreBoard.text))
          bestScore.text = "best: "..score.getCurBest()
          gameover = true

          -- displays a point of contact between the ball and the obstacle that
          --  caused the game to end
          if (event.phase == "began") then
            print("x, y: ", event.x,", ", event.y )
            collisionVisualizer = display.newCircle( event.x, event.y, 10 )
            collisionVisualizer:setFillColor(1, 0, 0, .5)
            transition.to(collisionVisualizer, {xScale = 100, yScale = 100, time = 3000})

						sceneGroup:insert(collisionVisualizer)
          else
            print(event.phase)
          end
        end
      end
    end
  end

  -- utility function for scorekeeping
  local function incrementScore()
    scoreBoard.text = tonumber(scoreBoard.text) + 1
  end


  local function onEnterFrameTest()
    collectGarbageObstacles()
    if gameover then
      gameOverMessage:toFront()
			replayButton:toFront()
			backButton:toFront()
      -- replayMessage:toFront()
      timer.cancel( obstacleGenerationTimer )
    end
    for i = 1, table.getn(obstaclesList) do
      if math.abs(obstaclesList[i][1].x - ballXPos) < 1 then
        if not gameover then
          incrementScore()
        end
      end
    end
  end



  -- handler for restarting on tap if gameover
  -- local function onTap()
	onTap = function()
    -- restarting the game
    if gameover then
      -- scoreBoard.text = "0"
      emptyObstaclesList()
      emptyItemsList()
      display.remove(collisionVisualizer)
      display.remove(gameOverMessage)
      display.remove(replayMessage)
      superMode = false
      gameover = false
			physics.stop()
      -- obstacleGenerationTimer = timer.performWithDelay( generationDelay * 3, generateObstacle, 1)
      -- invincibilityGenerationTimer = timer.performWithDelay( 1000, generateInvincibility, 1)


			Runtime:removeEventListener("touch", touchListener)
			Runtime:removeEventListener("collision", collisionEvent)
		  Runtime:removeEventListener("tap", onTap)
		  Runtime:removeEventListener("enterFrame", onEnterFrameTest)
			composer.removeScene( "level1", false )
			composer.gotoScene( "level1", "fade", 1000)
			-- composer.gotoScene( "menu" )
    else
      -- applyForceOnAll(10)
    end
  end



  -- use 'touch' event to detect motion of the user touch input
  Runtime:addEventListener("touch", touchListener)
  Runtime:addEventListener("collision", collisionEvent)
  -- Runtime:addEventListener("tap", onTap)
  Runtime:addEventListener("enterFrame", onEnterFrameTest)
  -- Runtime:addEventListener("enterFrame", onEnterFrame)
  -- obstacleGenerationTimer = timer.performWithDelay( generationDelay, generateObstacle, -1)

	local closure = function() return generateObstacle(generationDelay, gameSpeed) end
  obstacleGenerationTimer = timer.performWithDelay( generationDelay, closure)
  invincibilityGenerationTimer = timer.performWithDelay( 1000, generateInvincibility, 1)


	-- all display objects must be inserted into group
	sceneGroup:insert(ball1)
	sceneGroup:insert(ball2)
	sceneGroup:insert(scoreBoard)
	sceneGroup:insert(bestScore)
end


function scene:show( event )
	local sceneGroup = self.view
	local phase = event.phase

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		--
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		physics.start()
	end
end

function scene:hide( event )
	local sceneGroup = self.view

	local phase = event.phase

	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		physics.stop()
	elseif phase == "did" then
		-- Called when the scene is now off screen
	end

end

function scene:destroy( event )

	-- Called prior to the removal of scene's "view" (sceneGroup)
	--
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	local sceneGroup = self.view

	-- package.loaded[physics] = nil
	-- physics = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene
