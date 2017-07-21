-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------
-- TODO: Disallow darker colored generated objects OR change background color
-- TODO: Add non-bar obstacles
-- TODO: Add ads
-- TODO: Add click to start

-- things to load into sceneGroup:
--- scoreBoard
--- bestScore
--- ball1
--- ball2
--- gameOverMessage
--- replayMessage



local score = require("score")
local screen = require("screen")
local physics = require("physics")
local composer = require( "composer" )
local scene = composer.newScene()

-- local function playGame()
--   -- local physics = require("physics")
--   physics.start()
--   physics.setGravity( 0, 0 )
--   physics.setReportCollisionsInContentCoordinates( true )
--
--   -- space between rectangular obstacles
--
--   local ballXPos = display.contentCenterX / 4
--   local wiggleRoom = 15
--
--   local ballRadius = 10
--   local ball1 = display.newCircle(ballXPos, display.contentCenterY, ballRadius)
--   ball1:setFillColor(1,0,0)
--   local ball2 = display.newCircle(ballXPos, display.contentCenterY, ballRadius)
--
--   physics.addBody( ball1, 'static' )
--   physics.addBody( ball2, 'static' )
--
--   local scoreBoard = display.newText({text = "0", x = display.contentCenterX, y = 0})
--
--   local best = score.getCurBest()
--   local bestScore = display.newText({text = "best: "..best, x = 40, y = 0})
--
--   local gameSpeed = 200
--
--   -- higher sensitivity = more balls movement per finger travel
--   local sensitivity = 2.0
--
--   local startY = 0
--   local touchInterval = 0
--
--   -- super mode will be activated by an item that allows ball to break through obstacles
--   local superMode = false
--
--   -- stores individual obstacle objects for garbage collection
--   local obstaclesList = {}
--
--   local itemsList = {}
--
--
--   local gameover = false
--
--   -- time elapsed between obstacles
--   local generationDelay = 1000
--
--   -- how far obstacles need to travel outside the screen to be deleted
--   local buffer = 20
--
--   -- width for the bar-like obstacles
--   local rectangularObstacleWidth = 20
--
--   invincibilityChance = 1
--
--   -- handles player movement
--   local function touchListener(event)
--     if (event.phase == "began") then
--       startY = event.y
--     elseif (event.phase == "moved") then
--       touchInterval = event.y - startY
--
--       -- if the balls are past the middle line, only allow upward movement
--       if (ball1.y > display.contentCenterY) then
--         transition.to(ball1, {y = display.contentCenterY, time = 0})
--         transition.to(ball2, {y = display.contentCenterY, time = 0})
--         if (touchInterval < 0) then
--           transition.to(ball1, {y = ball1.y + touchInterval * sensitivity, time = 0})
--           transition.to(ball2, {y = ball2.y - touchInterval * sensitivity, time = 0})
--         end
--       -- boundary to keep balls in screen
--       elseif (ball1.y < 0) then
--         transition.to(ball1, {y = 0, time = 0})
--         transition.to(ball2, {y = display.contentHeight, time = 0})
--       -- boundary to keep
--       elseif (ball1.y == 0) then
--         if (touchInterval > 0) then
--           transition.to(ball1, {y = ball1.y + touchInterval * sensitivity, time = 0})
--           transition.to(ball2, {y = ball2.y - touchInterval * sensitivity, time = 0})
--         end
--       -- if ball is right at the y-center, only allow up-swipe
--       elseif (ball1.y == display.contentCenterY) then
--         if (touchInterval < 0) then
--           transition.to(ball1, {y = ball1.y + touchInterval * sensitivity, time = 0})
--           transition.to(ball2, {y = ball2.y - touchInterval * sensitivity, time = 0})
--         end
--       else
--         transition.to(ball1, {y = ball1.y + touchInterval * sensitivity, time = 0})
--         transition.to(ball2, {y = ball2.y - touchInterval * sensitivity, time = 0})
--       end
--       startY = event.y
--     elseif(event.phase == "ended") then
--       -- transition.to(player, {xScale = 1.0, yScale = 1.0})
--     end
--   end
--
--   -- checks if an obstacle, made of a list of objects, is out of bounds
--   -- it is out of bounds only if all components are out of bounds
--
--
--   -- deletes off-screen obstacles from physics space and display space
--   local function collectGarbageObstacles()
--     -- set out-of-bounds area
--     local minX = 0 - buffer
--     local maxX = display.contentWidth + buffer
--     local minY = 0 - buffer
--     local maxY = display.contentHeight + buffer
--
--     local indicesToDelete = {}
--     -- if obstacles is out of bounds, delete all of its components
--     local shouldBeRemoved = false
--     for i = 1, table.getn(obstaclesList) do
--       if screen.isOutOfBounds(minX, maxX, minY, maxY, obstaclesList[i]) then
--         for j = 1, table.getn(obstaclesList[i]) do
--           physics.removeBody(obstaclesList[i][j])
--           display.remove( obstaclesList[i][j] )
--           shouldBeRemoved = true
--         end
--       end
--       if shouldBeRemoved then
--         table.insert( indicesToDelete, i )
--         shouldBeRemoved = false
--       end
--     end
--
--     for i = #indicesToDelete, 1, -1 do
--       table.remove( obstaclesList, indicesToDelete[i] )
--     end
--   end
--
--   -- function to generate the invincibility item
--   local function generateInvincibility()
--     print("invincibility")
--     if (math.random() < invincibilityChance) then
--       local item = display.newRect(display.contentWidth + 10, math.random(0, display.contentHeight), 20, 20)
--       physics.addBody(item, "dynamic")
--       item:setLinearVelocity( -gameSpeed, 0)
--       item.isSensor = true;
--
--       table.insert( itemsList, item )
--       -- transition.to(item, {x = -10, time = (display.contentWidth + 20) / generationDelay})
--     end
--     if not gameover then
--       invincibilityGenerationTimer = timer.performWithDelay( 1000, generateInvincibility, 1 )
--     end
--   end
--
--
--   -- generates the obstacles. could be composed of up to 3 parts (for two balls)
--   local function generateObstacle()
--     collectGarbageObstacles()
--     if not gameover then
--       if (superMode) then
--         local line = {}
--         local subLineLength = display.contentHeight / 20
--         for i = 1, 20 do
--           table.insert(line, display.newRect(display.contentWidth - 10, (subLineLength / 2) * ((2 * i) - 1), 10, subLineLength))
--           line[i]:setFillColor(math.random(), math.random(), math.random())
--           physics.addBody( line[i])
--           line[i]:setLinearVelocity(-gameSpeed, 0)
--         end
--         table.insert( obstaclesList, line )
--       else
--         if (math.random() < .3) then
--           -- 30% chance of generating single-hole obstacles
--           -- generate obstacles from outside the screen to the right
--           local top = display.newRect(display.contentWidth - 10, display.contentCenterY / 2  - ballRadius - wiggleRoom, rectangularObstacleWidth, display.contentHeight / 2)
--           local bottom = display.newRect(display.contentWidth - 10, display.contentCenterY / 2 * 3 + ballRadius + wiggleRoom, rectangularObstacleWidth, display.contentHeight / 2)
--
--           top:setFillColor(math.random(),math.random(),math.random())
--           bottom:setFillColor(math.random(),math.random(),math.random())
--
--           physics.addBody(top)
--           physics.addBody(bottom)
--
--           top:setLinearVelocity(-gameSpeed, 0)
--           bottom:setLinearVelocity(-gameSpeed, 0)
--
--           -- TODO: this is a sloppy way of adding variety. Change it
--           if (math.random() < .2) then
--             physics.removeBody( top )
--             display.remove(top)
--             table.insert( obstaclesList,  {bottom})
--           elseif (math.random() < .4) then
--             physics.removeBody( bottom )
--             display.remove(bottom)
--             table.insert(obstaclesList, {top})
--           else
--             table.insert(obstaclesList, {top, bottom})
--           end
--         else
--           -- 70% chance of generating double-hole obstacles
--           local distanceBetweenBalls = math.random(100, display.contentHeight - 100)
--           local upDownHeights = (display.contentHeight - (2 * (2 * ballRadius + 2 * wiggleRoom)) + (2 * ballRadius) - distanceBetweenBalls) / 2
--           local middleHeight = distanceBetweenBalls - (2 * ballRadius)
--
--           local top = display.newRect(display.contentWidth - 10, upDownHeights / 2, rectangularObstacleWidth, upDownHeights)
--           local middle = display.newRect(display.contentWidth - 10, display.contentCenterY, rectangularObstacleWidth, middleHeight)
--           local bottom = display.newRect(display.contentWidth - 10, display.contentHeight - upDownHeights / 2, rectangularObstacleWidth, upDownHeights)
--
--           top:setFillColor(math.random(),math.random(),math.random())
--           middle:setFillColor(math.random(),math.random(),math.random())
--           bottom:setFillColor(math.random(),math.random(),math.random())
--
--           physics.addBody(top)
--           physics.addBody(middle)
--           physics.addBody(bottom)
--
--           top:setLinearVelocity(-gameSpeed,0)
--           middle:setLinearVelocity(-gameSpeed,0)
--           bottom:setLinearVelocity(-gameSpeed,0)
--
--           -- TODO: this is a sloppy way of adding variety. Change it
--           if (math.random() < .1) then
--             physics.removeBody( top )
--             display.remove(top)
--             table.insert( obstaclesList,  {middle, bottom})
--           elseif (math.random() < .2) then
--             physics.removeBody( bottom )
--             display.remove(bottom)
--             table.insert(obstaclesList, {top, middle})
--           elseif (math.random() < .3) then
--             physics.removeBody( middle )
--             display.remove(middle)
--             table.insert(obstaclesList, {top, bottom})
--           else
--             table.insert(obstaclesList, {top, middle, bottom})
--           end
--         end
--       end
--     end
--
--     if not gameover then
--       obstacleGenerationTimer = timer.performWithDelay( generationDelay, generateObstacle, 1)
--     end
--     if not superMode then
--       generationDelay = generationDelay - 1
--     end
--
--     rectangularObstacleWidth =  math.random(10, 50)
--   end
--
--
--   -- helper function to check object membership in a list
--   local function contains(item, list)
--     for i = 1, table.getn(list) do
--       if item == list[i] then
--         return true
--       end
--     end
--     return false
--   end
--
--   local function applyForceOnAll(magnitude)
--     for i = 1, table.getn(obstaclesList) do
--       for j = 1, table.getn(obstaclesList[i]) do
--         -- local xComp = obstaclesList[i][j].x - display.contentCenterX
--         -- local xComp = obstaclesList[i][j].x - ballXPos
--         local xComp = obstaclesList[i][j].x - ball1.x
--
--         -- local yComp = obstaclesList[i][j].y - display.contentCenterY
--         -- local yComp = obstaclesList[i][j].y - display.contentCenterY
--         local yComp = obstaclesList[i][j].y - ball1.y
--         local length = math.sqrt(xComp * xComp + yComp * yComp)
--         xComp = xComp / length
--         yComp = yComp / length
--
--         obstaclesList[i][j]:applyForce(xComp * magnitude, yComp * magnitude, 0, 0)
--
--         xComp = obstaclesList[i][j].x - ball2.x
--         yComp = obstaclesList[i][j].y - ball2.y
--         length = math.sqrt(xComp * xComp + yComp * yComp)
--         xComp = xComp / length
--         yComp = yComp / length
--         obstaclesList[i][j]:applyForce(xComp * magnitude, yComp * magnitude, 0, 0)
--       end
--     end
--   end
--
--   local timesCalled = 0
--   local function disableInvincibility()
--     print("there")
--     timer.cancel( obstacleGenerationTimer )
--     if table.getn(obstaclesList) == 0 then
--       print("here")
--       generationDelay = 1000
--       gameSpeed = 200
--       obstacleGenerationTimer = timer.performWithDelay(generationDelay, generateObstacle)
--       superMode = false
--     else
--       if timesCalled > 2 then
--         applyForceOnAll(10)
--         timesCalled = 0
--       end
--       timesCalled = timesCalled + 1
--       print(table.getn(obstaclesList))
--       timer.performWithDelay( 1000, disableInvincibility )
--     end
--   end
--
--   local function enableInvincibility()
--     generationDelay = 100
--     gameSpeed = 1000
--     superMode = true
--     timer.performWithDelay( 5000, disableInvincibility)
--   end
--
--
--   local collisionVisualizer
--   local obstacleGenerationTimer
--   local invincibilityGenerationTimer
--   local gameOverMessage
--   local replayMessage
--   -- use collisions to end game
--   local function collisionEvent(event)
--     -- handling item-getting
--     if (contains(event.object1, itemsList)) then
--       if ((event.object2 == ball1) or (event.object2 == ball2)) then
--         if not gameover then
--           -- display.remove(event.object1)
--           event.object1.isVisible = false
--           enableInvincibility()
--         end
--       end
--     -- more handling item-getting
--     elseif (contains(event.object2, itemsList)) then
--       if ((event.object1 == ball1) or (event.object1 == ball2)) then
--         if not gameover then
--           -- display.remove(event.object2)
--           event.object2.isVisible = false
--           enableInvincibility()
--         end
--       end
--     -- typical case for collision
--     else
--       if superMode then
--         -- do nothing?
--       else
--         --
--         if not gameover then -- end the game
--           timer.cancel( obstacleGenerationTimer )
--           timer.cancel( invincibilityGenerationTimer)
--           gameOverMessage = display.newText({text = "Game Over", x = display.contentCenterX, y = display.contentCenterY, fontSize = 12})
--           replayMessage = display.newText({text = "Tap to try again", x = display.contentCenterX, y = display.contentCenterY + 50, fontSize = 8})
--           transition.to(gameOverMessage, {xScale = 2, yScale = 2, time = 2000})
--
--
--
--           superMode = false
--
--           score.updateBest(tonumber( scoreBoard.text))
--           bestScore.text = "best: "..score.getCurBest()
--           gameover = true
--
--
--
--           -- displays a point of contact between the ball and the obstacle that
--           --  caused the game to end
--           if (event.phase == "began") then
--             print("x, y: ", event.x,", ", event.y )
--             collisionVisualizer = display.newCircle( event.x, event.y, 10 )
--             collisionVisualizer:setFillColor(1, 0, 0, .5)
--             transition.to(collisionVisualizer, {xScale = 100, yScale = 100, time = 3000})
--           else
--             print(event.phase)
--           end
--         end
--       end
--     end
--   end
--
--
--
--   -- utility function for scorekeeping
--   local function incrementScore()
--     scoreBoard.text = tonumber(scoreBoard.text) + 1
--   end
--
--
--   local function onEnterFrameTest()
--     collectGarbageObstacles()
--     if gameover then
--       gameOverMessage:toFront()
--       replayMessage:toFront()
--       timer.cancel( obstacleGenerationTimer )
--     end
--     for i = 1, table.getn(obstaclesList) do
--       if math.abs(obstaclesList[i][1].x - ballXPos) < 1 then
--         if not gameover then
--           incrementScore()
--         end
--       end
--     end
--   end
--
--   local function emptyObstaclesList()
--     for i = 1, table.getn(obstaclesList) do
--       for j = 1, table.getn(obstaclesList[i]) do
--         physics.removeBody(obstaclesList[i][j])
--         display.remove(obstaclesList[i][j])
--       end
--     end
--     obstaclesList = {}
--   end
--
--   local function emptyItemsList()
--     for i = 1, table.getn(itemsList) do
--       print("in emptyItemsList "..table.getn(itemsList))
--       if itemsList[i] then
--         physics.removeBody( itemsList[i] )
--         display.remove( itemsList[i] )
--       end
--     end
--     itemsList = {}
--   end
--
--   -- handler for restarting on tap if gameover
--   local function onTap()
--     -- restarting the game
--     if gameover then
--       scoreBoard.text = "0"
--       emptyObstaclesList()
--       emptyItemsList()
--       -- obstacleGenerationTimer = timer.performWithDelay( generationDelay, generateObstacle, -1)
--       display.remove(collisionVisualizer)
--       display.remove(gameOverMessage)
--       display.remove(replayMessage)
--       superMode = false
--       gameover = false
--       obstacleGenerationTimer = timer.performWithDelay( generationDelay * 3, generateObstacle, 1)
--       invincibilityGenerationTimer = timer.performWithDelay( 1000, generateInvincibility, 1)
--
--     else
--       -- applyForceOnAll(10)
--     end
--   end
--
--
--
--   -- use 'touch' event to detect motion of the user touch input
--   Runtime:addEventListener("touch", touchListener)
--   Runtime:addEventListener("collision", collisionEvent)
--   Runtime:addEventListener("tap", onTap)
--   Runtime:addEventListener("enterFrame", onEnterFrameTest)
--   -- Runtime:addEventListener("enterFrame", onEnterFrame)
--   -- obstacleGenerationTimer = timer.performWithDelay( generationDelay, generateObstacle, -1)
--
--   obstacleGenerationTimer = timer.performWithDelay( generationDelay, generateObstacle, 1)
--   invincibilityGenerationTimer = timer.performWithDelay( 1000, generateInvincibility, 1)
--
--
-- end



-- forward declarations and other locals
local screenW, screenH, halfW = display.actualContentWidth, display.actualContentHeight, display.contentCenterX

function scene:create( event )
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

  invincibilityChance = 1

  -- handles player movement
  local function touchListener(event)
    if (event.phase == "began") then
      startY = event.y
    elseif (event.phase == "moved") then
      touchInterval = event.y - startY

      -- if the balls are past the middle line, only allow upward movement
      if (ball1.y > display.contentCenterY) then
        transition.to(ball1, {y = display.contentCenterY, time = 0})
        transition.to(ball2, {y = display.contentCenterY, time = 0})
        if (touchInterval < 0) then
          transition.to(ball1, {y = ball1.y + touchInterval * sensitivity, time = 0})
          transition.to(ball2, {y = ball2.y - touchInterval * sensitivity, time = 0})
        end
      -- boundary to keep balls in screen
      elseif (ball1.y < 0) then
        transition.to(ball1, {y = 0, time = 0})
        transition.to(ball2, {y = display.contentHeight, time = 0})
      -- boundary to keep
      elseif (ball1.y == 0) then
        if (touchInterval > 0) then
          transition.to(ball1, {y = ball1.y + touchInterval * sensitivity, time = 0})
          transition.to(ball2, {y = ball2.y - touchInterval * sensitivity, time = 0})
        end
      -- if ball is right at the y-center, only allow up-swipe
      elseif (ball1.y == display.contentCenterY) then
        if (touchInterval < 0) then
          transition.to(ball1, {y = ball1.y + touchInterval * sensitivity, time = 0})
          transition.to(ball2, {y = ball2.y - touchInterval * sensitivity, time = 0})
        end
      else
        transition.to(ball1, {y = ball1.y + touchInterval * sensitivity, time = 0})
        transition.to(ball2, {y = ball2.y - touchInterval * sensitivity, time = 0})
      end
      startY = event.y
    elseif(event.phase == "ended") then
      -- transition.to(player, {xScale = 1.0, yScale = 1.0})
    end
  end

  -- checks if an obstacle, made of a list of objects, is out of bounds
  -- it is out of bounds only if all components are out of bounds


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

    for i = #indicesToDelete, 1, -1 do
      table.remove( obstaclesList, indicesToDelete[i] )
    end
  end

  -- function to generate the invincibility item
  local function generateInvincibility()
    print("invincibility")
    if (math.random() < invincibilityChance) then
      local item = display.newRect(display.contentWidth + 10, math.random(0, display.contentHeight), 20, 20)
      physics.addBody(item, "dynamic")
      item:setLinearVelocity( -gameSpeed, 0)
      item.isSensor = true;

      table.insert( itemsList, item )
      -- transition.to(item, {x = -10, time = (display.contentWidth + 20) / generationDelay})
    end
    if not gameover then
      invincibilityGenerationTimer = timer.performWithDelay( 1000, generateInvincibility, 1 )
    end
  end


  -- generates the obstacles. could be composed of up to 3 parts (for two balls)
  local function generateObstacle()
    collectGarbageObstacles()
    if not gameover then
      if (superMode) then
        local line = {}
        local subLineLength = display.contentHeight / 20
        for i = 1, 20 do
          table.insert(line, display.newRect(display.contentWidth - 10, (subLineLength / 2) * ((2 * i) - 1), 10, subLineLength))
          line[i]:setFillColor(math.random(), math.random(), math.random())
          physics.addBody( line[i])
          line[i]:setLinearVelocity(-gameSpeed, 0)
        end
        table.insert( obstaclesList, line )
      else
        if (math.random() < .3) then
          -- 30% chance of generating single-hole obstacles
          -- generate obstacles from outside the screen to the right
          local top = display.newRect(display.contentWidth - 10, display.contentCenterY / 2  - ballRadius - wiggleRoom, rectangularObstacleWidth, display.contentHeight / 2)
          local bottom = display.newRect(display.contentWidth - 10, display.contentCenterY / 2 * 3 + ballRadius + wiggleRoom, rectangularObstacleWidth, display.contentHeight / 2)

          top:setFillColor(math.random(),math.random(),math.random())
          bottom:setFillColor(math.random(),math.random(),math.random())

          physics.addBody(top)
          physics.addBody(bottom)

          top:setLinearVelocity(-gameSpeed, 0)
          bottom:setLinearVelocity(-gameSpeed, 0)

          -- TODO: this is a sloppy way of adding variety. Change it
          if (math.random() < .2) then
            physics.removeBody( top )
            display.remove(top)
            table.insert( obstaclesList,  {bottom})
          elseif (math.random() < .4) then
            physics.removeBody( bottom )
            display.remove(bottom)
            table.insert(obstaclesList, {top})
          else
            table.insert(obstaclesList, {top, bottom})
          end
        else
          -- 70% chance of generating double-hole obstacles
          local distanceBetweenBalls = math.random(100, display.contentHeight - 100)
          local upDownHeights = (display.contentHeight - (2 * (2 * ballRadius + 2 * wiggleRoom)) + (2 * ballRadius) - distanceBetweenBalls) / 2
          local middleHeight = distanceBetweenBalls - (2 * ballRadius)

          local top = display.newRect(display.contentWidth - 10, upDownHeights / 2, rectangularObstacleWidth, upDownHeights)
          local middle = display.newRect(display.contentWidth - 10, display.contentCenterY, rectangularObstacleWidth, middleHeight)
          local bottom = display.newRect(display.contentWidth - 10, display.contentHeight - upDownHeights / 2, rectangularObstacleWidth, upDownHeights)

          top:setFillColor(math.random(),math.random(),math.random())
          middle:setFillColor(math.random(),math.random(),math.random())
          bottom:setFillColor(math.random(),math.random(),math.random())

          physics.addBody(top)
          physics.addBody(middle)
          physics.addBody(bottom)

          top:setLinearVelocity(-gameSpeed,0)
          middle:setLinearVelocity(-gameSpeed,0)
          bottom:setLinearVelocity(-gameSpeed,0)

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
      obstacleGenerationTimer = timer.performWithDelay( generationDelay, generateObstacle, 1)
    end
    if not superMode then
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
    print("there")
    timer.cancel( obstacleGenerationTimer )
    if table.getn(obstaclesList) == 0 then
      print("here")
      generationDelay = 1000
      gameSpeed = 200
      obstacleGenerationTimer = timer.performWithDelay(generationDelay, generateObstacle)
      superMode = false
    else
      if timesCalled > 2 then
        applyForceOnAll(10)
        timesCalled = 0
      end
      timesCalled = timesCalled + 1
      print(table.getn(obstaclesList))
      timer.performWithDelay( 1000, disableInvincibility )
    end
  end

  local function enableInvincibility()
    generationDelay = 100
    gameSpeed = 1000
    superMode = true
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

					local replayButton = display.newImageRect("retry.png", 64, 64)
					replayButton.x = display.contentCenterX - 32
					replayButton.y = display.contentCenterY + 50
					replayButton:addEventListener("tap", onTap)
					sceneGroup:insert(replayButton)

					local backButton = display.newImageRect("back-to-menu.png", 64, 64)
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

  obstacleGenerationTimer = timer.performWithDelay( generationDelay, generateObstacle, 1)
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

	package.loaded[physics] = nil
	physics = nil
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )

-----------------------------------------------------------------------------------------

return scene
