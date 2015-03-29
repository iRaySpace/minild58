--[[

	WANTS :

1. Awesome Tweening --> just for the next version

	NEEDS :

Yay!!! Thank you Lord!

	CHECKLIST:

_ --- Incomplete
x --- Ongoing
/ --- Complete
> --- Sub checklist

/ Ball
/ Rectangle
/ Collision
/ Two timer 
> / Must activate one paddle at a given time
/ Score points
/ Upgrades
/ Basic UI --> Graphics
/ Main Menu
/ Game Over
/ Scoreboards (Local) --> SICK?
	-- I just use Tserial
/ Damaging System of the Deflector
> / It might probably have a buy-to-repair system. Yes.
	-- I just treat like a whole.
/ Awesome categorization of the enemies
> / Normal, Medium, Large?
/ Camera effects(shaking, rotation -> new idea)
> / If rotation, why not have a special ball that could rotate or like that
  -- only shaking (huhu)
/ Screen effects (bloom)
/ Sounds 

_ PUBLISH!!!

	PROBLEMS:
/ Recycling of the balls -> when you remove it doesn't work well. it loses track.
/ Bug on balls to generate random

	OBJECTIVE:

	Just like radial pong, the ball will respawn at the middle.
	All you have to do is to stop the ball from getting out, or else
	the main system would die
	
	ADDITIONAL:

- Color Scheme

https://color.adobe.com/light-to-dark-color-theme-852520/edit/?copy=true&base=2&rule=Custom&selected=0&name=Copy%20of%20light%20to%20dark&mode=rgb&rgbvalues=0.94902,0.862745,0.701961,0.85098,0.47451,0.015686,0.45098,0.12549,0.007843,0.25098,0.023529,0.003922,0.14902,0.003922,0.003922&swatchOrder=0,1,2,3,4

- VERSION -
+   1.0   *
-----------
--> Haven't kept a changelog ever since. Umm no.

CHANGELOG (03-27-15 -- 0.8):

1. Added main menus
2. Added pause
3. Added game over
4. Added health system 

CHANGELOG (03-29-15 -- 1.0?):

1. Added Graphics and Fonts
2. Screen shaking?
3. Added upgrades
4. High Score
5. and lots...

]]--

-- bloom
require "bloom"

-- TSerial
require "Tserial"

-- debugging purposes
lick = require "lick"
lick.reset = true

-- kikito's library
local class = require "middleclass"
local stateful = require "stateful"

-- hump library
local game_state = require "gamestate"
local timer_lib = require "timer"
local camera = require "camera"

-- Game States
local menu = {}
local game = {}
local pause = {}
local over = {}

-- State transition timer
local transition = {}
	  transition.black = 0
	  transition.HOW_LONG = 1

-- SAVE FILE
local FILE_SAVE = "player.sav"

-- Player
local player = { highScore = 0 }

-- shorthand, references to library
local g = love.graphics
local w = love.window

----------------------------------------------------
-- Classes
----------------------------------------------------

-- Ball
local Ball = class('Ball')
Ball:include(stateful)

-- normal ball
function Ball:initialize(x, y)

	-- Initialization
	self.x = x
	self.y = y

	-- Declaration
	self.angle = 0
	self.speed = 100
	self.velocity = {}
	self.velocity.x = 0
	self.velocity.y = 0
	self.alive = false
	self.radius = 10
	self.damage = 10
	self.type = 1

end

function Ball:setStats()

	-- to normal (redundant)
	self.speed = 100
	self.damage = 10
	self.type = 1

end

-- Fast Ball
local fast = Ball:addState('fast')

function fast:setStats()

	-- fast ball!
	self.speed = 200
	self.damage = 10
	self.type = 2

end

-- Hard Ball
local hard = Ball:addState('hard')

function hard:setStats()

	-- hard ball!
	self.speed = 100
	self.damage = 20
	self.type = 3

end

-- hybrid
local hybrid = Ball:addState('hybrid')

function hybrid:setStats()

	-- hybrid ball!
	self.speed = 150
	self.damage = 15
	self.type = 4

end

----------------------------------------------------
	-- MAIN MENU functions
----------------------------------------------------

function menu:draw()

	-- offer
	g.setColor(255, 255, 255, 175)

	g.setFont(GAME_FONT_TITLE)
	g.printf("Ayaw Pong Buot", centerX - 375 / 2, 100, 375, "center")

	-- overlay with black under score
	g.setColor(0, 0, 0, 100)
	g.rectangle("fill", 0, GAME_HEIGHT - 100, GAME_WIDTH, centerY / 4)
	
	g.setColor(255, 255, 255, 175)

	g.setFont(GAME_FONT_NORMAL)
	g.printf("Press ENTER to start playing", centerX - 300 / 2, GAME_HEIGHT - 150, 300, "center")
	g.printf("Highest score is " .. player.highScore, centerX - 300 / 2, GAME_HEIGHT - 85, 300, "center")
	
	-- black screen overlay
	g.setColor(0, 0, 0, transition.black)
	g.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

end

function menu:update(dt)

	-- update the tween
	timer_lib.update(dt)

end

function menu:keyreleased(key, code)

	if key == "return" then
	 
		local start_sfx = love.audio.newSource("start.wav", "static")
		timer_lib.tween(transition.HOW_LONG, transition, { black = 255 }, 'in-out-quad', function() game_state.switch(game) end) 
		start_sfx:play()

	end

end

function menu:leave()

	-- opacity of overlayed transitioning layer
	transition.black = 0

end

----------------------------------------------------
	-- MAIN GAME functions
----------------------------------------------------

function game:enter()

	-- set the sound
	soundtrack_sfx:setVolume(0.25)

	-- calling the helper function
	newGameOrReset()

end

function game:update(dt)

	-- timer
	respawnTimer = respawnTimer - dt

	-- RELEASED DA BOLS
	if(respawnTimer <= 0) then 

		respawnTimer = math.random(5) -- maximum of 5 seconds

		-- number of balls to be summoned
		local numberOfBalls = math.ceil(math.random(BALLS_PER_WAVE) * (currentWave * (math.random(100) / 100)))

		-- start
		for i = 1, numberOfBalls do 	
			createNewBall() -- calling the helper function
		end

		-- current wave
		currentWave = currentWave + 1

	end

	-- opacity down
	for _, paddle in ipairs(paddles) do

		if(paddle.opacity > 25) 
		then paddle.opacity = paddle.opacity - (dt * fadeOut)
		else paddle.active = false
		end

	end

	-- ball movement
	for _, ball in ipairs(balls) do

		if(ball.alive) then
			ball.x = ball.x + (ball.velocity.x * dt)
			ball.y = ball.y + (ball.velocity.y * dt)
		end

	end

	-- check collision
	for _, paddle in ipairs(paddles) do
		for _, ball in ipairs(balls) do

			if(collideWith(paddle.x, paddle.y, paddle.width, paddle.height, ball.x - ball.radius, ball.y - ball.radius, ball.radius * 2, ball.radius * 2)
			and paddle.active and ball.alive) then 

				local explode_sfx = love.audio.newSource("explode.wav", "static")

				ball.alive = false
				life = math.floor(life - ((math.random(100) / 100) * ball.damage))
				score = score + SCORE_PER_HIT
				destroyedBalls = destroyedBalls + 1
				shakeCamera(0.5, 20)

				explode_sfx:play()

			end

		end
	end

	-- check if out of bounds
	for _, ball in ipairs(balls) do

		if(isOutOfTheScreen(ball.x - ball.radius, ball.y - ball.radius, ball.radius * 2, ball.radius * 2) and ball.alive) then
			
			local explode_sfx = love.audio.newSource("explode.wav", "static")

			ball.alive = false
			life = math.floor(life - ((math.random(100) / 100) * ball.damage) * 2)
			destroyedBalls = destroyedBalls + 1
			shakeCamera(1, 10)

			explode_sfx:play()

		end

	end

	-- if life is ...
	if(life <= 0)
	then game_state.switch(over)
	end

	-- update
	timer_lib.update(dt)

end

function game:draw()

	-- camera awesome
	cam:attach()

	-- paddles
	for _, paddle in ipairs(paddles) do

		g.setColor(242, 220, 179, paddle.opacity)
		g.rectangle("fill", paddle.x, paddle.y, paddle.width, paddle.height)

	end

	-- balls
	for _, ball in ipairs(balls) do

		if(ball.alive) then
			
			-- normal
			g.setColor(242, 220, 179)

			-- if the ball is so special
			if(ball.type == 2 or ball.type == 3) then g.setColor(115, 32, 2)
			elseif(ball.type == 4) then g.setColor(217, 121, 4) end

			-- print the ball
			g.circle("fill", ball.x, ball.y, ball.radius)

		end

	end

	-- guis
	cam:detach()

	-- timer
	g.setColor(255, 255, 255, 175)
	g.print("Score: " .. score, 30, GAME_HEIGHT - 50)

	-- life indicator
	if(life > 50) then g.setColor(242, 220, 179, 175)
	elseif(life > 25) then g.setColor(217, 121, 4, 175)
	else g.setColor(115, 32, 2, 175) end
	g.rectangle("fill", 0, 0, GAME_WIDTH * (life / 100), 15)

	-- ui
	g.setColor(255, 255, 255, 175)
	g.print("Upgrades(cost 3)", GAME_WIDTH - 200, GAME_HEIGHT - 115)

	g.draw(FAST_UPGRADE_IMG, GAME_WIDTH - 225, GAME_HEIGHT - 75)
	g.print("1", GAME_WIDTH - 230, GAME_HEIGHT - 85)
	g.print("" .. fadeOutLevel, GAME_WIDTH - 170, GAME_HEIGHT - 30)

	g.draw(ACTIVE_UPGRADE_IMG, GAME_WIDTH - 150, GAME_HEIGHT - 75)
	g.print("2", GAME_WIDTH - 155, GAME_HEIGHT - 85)
	g.print("" .. maxActiveLevel, GAME_WIDTH - 95, GAME_HEIGHT - 30)

	g.draw(HEART_UPGRADE_IMG, GAME_WIDTH - 75, GAME_HEIGHT - 75)
	g.print("3", GAME_WIDTH - 80, GAME_HEIGHT - 85)

end

function game:keypressed(key, code)

	-- up
	if key == "up" and getNumOfActivePaddles() < maxActive then 

		local activate_sfx = love.audio.newSource("activate.ogg", "static")

		top.opacity = 255
		top.active = true 

		activate_sfx:play()

	end

	-- down
	if key == "down" and getNumOfActivePaddles() < maxActive then 

		local activate_sfx = love.audio.newSource("activate.ogg", "static")

		bot.opacity = 255
		bot.active = true

		activate_sfx:play()

	end

	-- left
	if key == "left" and getNumOfActivePaddles() < maxActive then 

		local activate_sfx = love.audio.newSource("activate.ogg", "static")

		left.opacity = 255
		left.active = true

		activate_sfx:play()

	end

	-- right
	if key == "right" and getNumOfActivePaddles() < maxActive then 

		local activate_sfx = love.audio.newSource("activate.ogg", "static")

		right.opacity = 255
		right.active = true

		activate_sfx:play()

	end

	--------------
	-- Upgrades --
	--------------

	-- fadeOut
	if key == "1" and score >= SHOP.FADE_OUT_COST and fadeOutLevel < 8 then

		local upgrade_sfx = love.audio.newSource("upgrade.wav", "static")

		fadeOut = fadeOut + 25
		fadeOutLevel = fadeOutLevel + 1
		score = score - SHOP.FADE_OUT_COST

		upgrade_sfx:play()

	end

	-- maxActive
	if key == "2" and score >= SHOP.MAX_ACTIVE_COST and maxActiveLevel < 2 then

		local upgrade_sfx = love.audio.newSource("upgrade.wav", "static")

		maxActive = maxActive + 1
		maxActiveLevel = maxActiveLevel + 1
		score = score - SHOP.MAX_ACTIVE_COST

		upgrade_sfx:play()

	end

	-- health
	if key == "3" and score >= SHOP.TOTAL_HEALTH_COST then

		local upgrade_sfx = love.audio.newSource("upgrade.wav", "static")

		life = 100
		score = score - SHOP.TOTAL_HEALTH_COST

		upgrade_sfx:play()

	end

	-- pause
	if key == "p" or key == "escape" then

		local pause_sfx = love.audio.newSource("next.wav", "static") 
		game_state.push(pause)
		pause_sfx:play()

	end

end

function game:leave()

	-- paddles -> set back to normal
	top.opacity = 25
	top.active = false

	bot.opacity = 25
	bot.active = false

	left.opacity = 25
	left.active = false

	right.opacity = 25
	right.active = false

end

----------------------------------------------------
	-- PAUSE GAME functions
----------------------------------------------------

function pause:enter(from)

	-- oh yeah! sounds
	soundtrack_sfx:setVolume(0.5)

	-- get an instance of the game state
	self.from = from

end

function pause:draw()

	-- we have bloom
	bloom:predraw()
	bloom:enabledrawtobloom()

	-- draw previous game state
	self.from:draw()

	-- stop the bloom here
	bloom:postdraw()

	-- overlay with pause
	g.setColor(0, 0, 0, 100)
	g.rectangle("fill", 0, centerY / 1.33, GAME_WIDTH, centerY / 2)
	
	g.setColor(255, 255, 255, 175)

	g.setFont(GAME_FONT_NOTIFY)
	g.printf("Pause", centerX - 200 / 2, centerY - 55, 200, "center")

	g.setFont(GAME_FONT_NORMAL)
	g.printf("Press P or Esc to continue playing", centerX - 500 / 2, centerY + 15, 500, "center")

end

function pause:keypressed(key)

	-- stop the pause
	if key == "p" or key == "escape" then 

		local unpause_sfx = love.audio.newSource("back.wav", "static")
		game_state.pop()
		unpause_sfx:play()
		soundtrack_sfx:setVolume(0.25)

	end

end

----------------------------------------------------
	-- GAME OVER functions
----------------------------------------------------

function over:enter(from)

	-- sounds!
	soundtrack_sfx:setVolume(0.5)

	-- get an instance of the game state
	self.from = from

	-- set high score
	if(player.highScore < score) then 
		player.highScore = score 
		love.filesystem.write(FILE_SAVE, Tserial.pack(player))
	end

end

function over:draw()

	-- yay! bloom
	bloom:predraw()
	bloom:enabledrawtobloom()

	-- draw previous game state
	self.from:draw()

	-- remove
	bloom:postdraw()

	-- overlay with message
	g.setColor(0, 0, 0, 100)
	g.rectangle("fill", 0, centerY - 120, GAME_WIDTH, centerY)

	g.setColor(255, 255, 255, 175)

	g.setFont(GAME_FONT_NOTIFY)
	g.printf("GAME OVER", centerX - 350 / 2, centerY - 100, 350, "center")

	g.setFont(GAME_FONT_NORMAL)

	-- score
	g.printf("Your score is " .. score, centerX - 300 / 2, centerY - 15, 300, "center")
	g.printf("Highest score is " .. player.highScore, centerX - 300 / 2, centerY + 15, 300, "center")

	-- next
	g.printf("Press Enter to continue", centerX - 300 / 2, centerY + 75, 300, "center")

	-- overlay transitioning layer
	g.setColor(0, 0, 0, transition.black)
	g.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

end

function over:update(dt)

	-- update the tween
	timer_lib.update(dt)

end

function over:keyreleased(key)

	-- go back
	if key == "return" 
	then timer_lib.tween(transition.HOW_LONG, transition, { black = 255 }, 'in-out-quad', function() game_state.switch(menu) end)
	end

end

function over:leave()

	-- reset transitioning opacity
	transition.black = 0

	-- balls -> dead
	for _, ball in ipairs(balls) do

		if(ball.alive)
		then ball.alive = false
		end
		
	end

end
----------------------------------------------------
	-- LOVE functions
----------------------------------------------------

-- Pre-game
function love.load()
	
	-- MUSIC!
	soundtrack_sfx = love.audio.newSource("soundtrack.ogg")
	soundtrack_sfx:setVolume(0.5)
	soundtrack_sfx:setLooping(true)

	-- set resolution
	w.setMode(640, 480)

	-- set background
	g.setBackgroundColor(38, 1, 1)

	-- width and height of the game constants
	GAME_WIDTH, GAME_HEIGHT = g.getDimensions()
	
	-- middle x and middle y
	centerX = GAME_WIDTH / 2
	centerY = GAME_HEIGHT / 2

	-- camera
	cam = camera(centerX, centerY)

	-- awesome
	bloom = CreateBloomEffect(GAME_WIDTH / 4, GAME_HEIGHT / 4)

	-- font
	GAME_FONT_NOTIFY = g.newFont("MotionControl-Bold.otf", 64)
	GAME_FONT_TITLE = g.newFont("MotionControl-Bold.otf", 48)
	GAME_FONT_NORMAL = g.newFont("MotionControl-Bold.otf", 28)

	-- simple images
	FAST_UPGRADE_IMG = g.newImage("fastupgrade.png")
	ACTIVE_UPGRADE_IMG = g.newImage("activeupgrade.png")
	HEART_UPGRADE_IMG = g.newImage("heartupgrade.png")

	-- randomizer
	math.randomseed(os.time())
	math.random(); math.random(); math.random()

	-- distance from the center
	dist = 150

	-- top paddle
	top = {}
	top.width = 130
	top.height = 15
	top.x = centerX - (top.width / 2)
	top.y = (centerY - (dist / 2)) - top.height
	top.opacity = 25
	top.active = false

	-- bottom paddle
	bot = {}
	bot.height = 15
	bot.width = 130
	bot.x = centerX - (bot.width / 2)
	bot.y = centerY + (dist / 2)
	bot.opacity = 25
	bot.active = false

	-- left paddle
	left = {}
	left.width = 15
	left.height = 130
	left.x = (centerX - (dist / 2)) - left.width
	left.y = centerY - (left.height / 2)
	left.opacity = 25
	left.active = false

	-- right paddle
	right = {}
	right.width = 15
	right.height = 130
	right.x = centerX + (dist / 2)
	right.y = centerY - (right.height / 2)
	right.opacity = 25
	right.active = false

	-- paddles table
	paddles = {}
	table.insert(paddles, top)
	table.insert(paddles, bot)
	table.insert(paddles, left)
	table.insert(paddles, right)

	-- balls table
	balls = {}

	-- balls per wave
	BALLS_PER_WAVE = 2

	-- scoring system
	SCORE_PER_HIT = 1

	-- high score load
	if(love.filesystem.exists(FILE_SAVE)) 
	then player = Tserial.unpack(love.filesystem.read(FILE_SAVE))
	end

	-- upgrades -> improvise
	SHOP = {}
	SHOP.FADE_OUT_COST = 3
	SHOP.MAX_ACTIVE_COST = 3
	SHOP.TOTAL_HEALTH_COST = 3

	-- play the music
	soundtrack_sfx:play()

	-- Start the game with menu
	game_state.registerEvents()
	game_state.switch(menu)

end

----------------------------------------------------
-- Helper functions
----------------------------------------------------

-- new game or reset
function newGameOrReset()

	-- player stats
	fadeOut = 100
	fadeOutLevel = 0
	maxActive = 2
	maxActiveLevel = 0
	score = 0
	life = 100

	-- balls
	respawnTimer = 5
	destroyedBalls = 0
	currentWave = 1

end

-- shake the camera
function shakeCamera(secs, ints)

	-- original location of the camera
	local orig_x, orig_y = cam:pos()

	-- do the shake
	timer_lib.do_for(secs, 
	function() cam:lookAt(orig_x + math.random(-ints, ints), orig_y + math.random(-ints, ints)) end,
	function() cam:lookAt(centerX, centerY) end)

end

-- bounding box collision detection
function collideWith(x1, y1, w1, h1, x2, y2, w2, h2)

	return x1 < x2 + w2 and
		   x2 < x1 + w1 and
		   y1 < y2 + h2 and
		   y2 < y1 + h1

end

-- out of bounds detection
function isOutOfTheScreen(x1, y1, w1, h1)

	-- horizontally
	if(x1 < 0) then return true
	elseif(x1 + w1 > GAME_WIDTH) then return true

	-- vertically
	elseif(y1 < 0) then return true
	elseif(y1 + h1 > GAME_HEIGHT) then return true

	else return false end

end

-- get number of active paddles
function getNumOfActivePaddles()

	-- declare
	local active = 0

	-- paddle
	for _, paddle in ipairs(paddles) do
		
		if(paddle.active)
		then active = active + 1
		end

	end

	return active

end

-- get first alive ball
function getFirstDeadBall()

	-- declare
	local deadBall = nil

	-- iterate over balls
	for _, ball in ipairs(balls) do

		if(not ball.alive)
		then deadBall = ball
		break
		end

	end

	return deadBall

end

-- randomize type of the ball
function randomizeTypeOfBall(ball)

	-- set the type
	local ballType = math.random(4)

	-- let's have it match
	if(ballType == 1) then ball:gotoState(nil)
	elseif(ballType == 2) then ball:gotoState('fast')
	elseif(ballType == 3) then ball:gotoState('hard')
	else ball:gotoState('hybrid')
	end

	-- setting the stats
	ball:setStats()

end

-- create new ball
function createNewBall()

	-- get first dead ball
	local isDead = getFirstDeadBall()

	-- local instance
	local ball = nil

	-- dead ball or new ball
	if(isDead ~= nil) 
	then ball = isDead
	else ball = Ball:new(0, 0)
	end

	-- random ball
	randomizeTypeOfBall(ball)

	-- initialize
	ball.x = centerX
	ball.y = centerY

	ball.alive = true
	ball.angle = math.rad(math.random(360))

	ball.velocity.x = math.cos(ball.angle) * ball.speed
	ball.velocity.y = math.sin(ball.angle) * ball.speed

	-- adding ball into the balls array
	if(isDead == nil) 
	then table.insert(balls, ball) 
	end

end