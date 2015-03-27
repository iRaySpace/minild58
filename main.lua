--[[

	WANTS :

1. Screen effects (bloom)
2. Awesome Tweening
3. Camera effects(shaking, rotation -> new idea)
4.1 > If rotation, why not have a special ball that could rotate or like that
5. Awesome categorization of the enemies
5.1 > Normal, Medium, Large?

	NEEDS :

1. Sounds

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
_ Basic UI --> Graphics
/ Main Menu
/ Game Over
_ Scoreboards (Local) --> SICK?
/ Damaging System of the Deflector
> / It might probably have a buy-to-repair system. Yes.
	-- I just treat like a whole.

	PROBLEMS:
/ Recycling of the balls -> when you remove it doesn't work well. it loses track.

	OBJECTIVE:

	Just like radial pong, the ball will respawn at the middle.
	All you have to do is to stop the ball from getting out, or else
	the main system would die
	
	ADDITIONAL:

- Color Scheme

https://color.adobe.com/light-to-dark-color-theme-852520/edit/?copy=true&base=2&rule=Custom&selected=0&name=Copy%20of%20light%20to%20dark&mode=rgb&rgbvalues=0.94902,0.862745,0.701961,0.85098,0.47451,0.015686,0.45098,0.12549,0.007843,0.25098,0.023529,0.003922,0.14902,0.003922,0.003922&swatchOrder=0,1,2,3,4

- VERSION -
+   0.8   *
-----------
--> Haven't kept a changelog ever since. Umm no.

CHANGELOG (03-27-15 -- 0.8):

1. Added main menus
2. Added pause
3. Added game over
4. Added health system 

]]--

-- debugging purposes
lick = require "lick"
lick.reset = true

-- middleclass (credits to Kikito)
local class = require "middleclass"

-- hump library
local game_state = require "gamestate"
local timer_lib = require "timer"

-- Game States
local menu = {}
local game = {}
local pause = {}
local over = {}

-- State transition timer
local transition = {}
	  transition.black = 0
	  transition.HOW_LONG = 1

-- shorthand, references to library
local g = love.graphics
local w = love.window

----------------------------------------------------
-- Classes
----------------------------------------------------

-- Ball
Ball = class('Ball')

function Ball:initialize(x, y)

	-- Initialization
	self.x = x
	self.y = y

	-- Declaration
	self.angle = 0
	self.speed = 0
	self.velocity = {}
	self.velocity.x = 0
	self.velocity.y = 0
	self.alive = false
	self.radius = 10
	self.damage = 10

end

----------------------------------------------------
	-- MAIN MENU functions
----------------------------------------------------

function menu:draw()

	-- offer
	g.setColor(255, 255, 255, 255)
	g.print("Welcome to my game!", 10, 10)
	g.print("Press Enter to continue", 10, 25)

	-- black screen overlay
	g.setColor(0, 0, 0, transition.black)
	g.rectangle("fill", 0, 0, GAME_WIDTH, GAME_HEIGHT)

end

function menu:update(dt)

	-- update the tween
	timer_lib.update(dt)

end

function menu:keyreleased(key, code)

	if key == "return" 
	then timer_lib.tween(transition.HOW_LONG, transition, { black = 255 }, 'in-out-quad', function() game_state.switch(game) end)
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

	-- calling the helper function
	newGameOrReset()

end

function game:update(dt)

	-- timer
	respawnTimer = respawnTimer - dt

	if(respawnTimer <= 0) then 
		respawnTimer = math.random(5) -- maximum of 5 seconds
		createNewBall() -- calling the helper function
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

			if(collideWith(paddle.x, paddle.y, paddle.width, paddle.height, ball.x, ball.y, ball.radius, ball.radius)
			and paddle.active and ball.alive) then 
				ball.alive = false
				life = life - ((math.random(100) / 100) * ball.damage)
				score = score + SCORE_PER_HIT
			end

		end
	end

	-- if life is ...
	if(life <= 0)
	then game_state.switch(over)
	end

end

function game:draw()

	-- paddles
	for _, paddle in ipairs(paddles) do

		g.setColor(242, 220, 179, paddle.opacity)
		g.rectangle("fill", paddle.x, paddle.y, paddle.width, paddle.height)

	end

	-- balls
	for _, ball in ipairs(balls) do

		if(ball.alive) then
			g.setColor(242, 220, 179, 255)
			g.circle("fill", ball.x, ball.y, ball.radius)
		end

	end

	-- timer
	g.setColor(255, 255, 255, 255)
	g.print("Respawn in: " .. respawnTimer, 10, 10)
	g.print("Score: " .. score, 10, 30)
	g.print("Life: " .. life, 10, 50)

end

function game:keypressed(key, code)

	-- up
	if key == "up" and getNumOfActivePaddles() < maxActive then 
		top.opacity = 255
		top.active = true 
	end

	-- down
	if key == "down" and getNumOfActivePaddles() < maxActive then 
		bot.opacity = 255
		bot.active = true
	end

	-- left
	if key == "left" and getNumOfActivePaddles() < maxActive then 
		left.opacity = 255
		left.active = true
	end

	-- right
	if key == "right" and getNumOfActivePaddles() < maxActive then 
		right.opacity = 255
		right.active = true
	end

	--------------
	-- Upgrades --
	--------------

	-- fadeOut
	if key == "1" and score >= SHOP.FADE_OUT_COST then
		fadeOut = fadeOut + 25
		score = score - SHOP.FADE_OUT_COST
	end

	-- maxActive
	if key == "2" and score >= SHOP.MAX_ACTIVE_COST then
		maxActive = maxActive + 1
		score = score - SHOP.MAX_ACTIVE_COST
	end

	-- pause
	if key == "p" or key == "escape"
	then game_state.push(pause)
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

	-- get an instance of the game state
	self.from = from

end

function pause:draw()

	-- draw previous game state
	self.from:draw()

	-- overlay with pause
	g.print("PAUSE.", centerX, centerY)

end

function pause:keypressed(key)

	-- stop the pause
	if key == "p" or key == "escape"
	then game_state.pop()
	end

end

----------------------------------------------------
	-- GAME OVER functions
----------------------------------------------------

function over:enter(from)

	-- get an instance of the game state
	self.from = from

end

function over:draw()

	-- draw previous game state
	self.from:draw()

	-- overlay with message
	g.print("GAME OVER.", centerX, centerY)
	g.print("Press Enter to Continue.", centerX, centerY + 20)

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

end
----------------------------------------------------
	-- LOVE functions
----------------------------------------------------

-- Pre-game
function love.load()
	
	-- set resolution
	w.setMode(640, 480)

	-- set background
	g.setBackgroundColor(38, 1, 1)

	-- randomizer
	math.randomseed(os.time())
	math.random(); math.random(); math.random()

	-- distance from the center
	dist = 150

	-- middle x and middle y
	GAME_WIDTH, GAME_HEIGHT = love.graphics.getDimensions()
	centerX = GAME_WIDTH / 2
	centerY = GAME_HEIGHT / 2

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

	-- scoring system
	SCORE_PER_HIT = 25

	-- upgrades -> improvise
	SHOP = {}
	SHOP.FADE_OUT_COST = 250
	SHOP.MAX_ACTIVE_COST = 250

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
	maxActive = 2
	score = 0
	life = 100

	-- balls
	respawnTimer = 5

end

-- bounding box collision detection
function collideWith(x1, y1, w1, h1, x2, y2, w2, h2)

	return x1 < x2 + w2 and
		   x2 < x1 + w1 and
		   y1 < y2 + h2 and
		   y2 < y1 + h1

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

-- create new ball
function createNewBall()

	-- get first dead ball
	local isDead = getFirstDeadBall()

	-- local instance
	local ball = nil

	if(isDead ~= nil) 
	then ball = isDead
	else ball = Ball:new(0, 0)
	end

	-- initialize
	ball.x = centerX
	ball.y = centerY

	ball.alive = true
	ball.speed = 100
	ball.angle = math.rad(math.random(360))

	ball.velocity.x = math.cos(ball.angle) * ball.speed
	ball.velocity.y = math.sin(ball.angle) * ball.speed

	-- adding ball into the balls array
	if(isDead == nil) 
	then table.insert(balls, ball) 
	end

end