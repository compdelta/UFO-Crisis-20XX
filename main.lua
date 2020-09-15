--[[

    CS50 Final Project
    'UFO CRISIS 20XX'

    Author: Michael Cox

    An old-school vertical-scrolling shoot 'em up. 
    Features keyboard controls, collision detection,
    background scrolling, score tracking & high score recording, 
    a seperate boss section at the end, a 'true final boss' that
    only appears if you meet certain requirements, and
    2 different endings.

    Soundtrack composed in Dezaemon SFC for authentic
    Super Nintendo vibes.

    Code could be tidier, but it's my first Lua & Love2D
    game, and it at least works (pretty much) as intended.

    Yes, that is my cat at the end.

]]

-- Using push library so that the game can be drawn at a virtual
-- resolution, for a retro aesthetic

push = require 'push'

-- Also using Class library so that all elements in game can
-- be represented as code

Class = require 'Class'

-- Include Player.lua (Class)
require 'Player'

-- Include Boss.lua (Class)
require 'Boss'

-- Define window height/width & virtual height/width
WINDOW_HEIGHT = 960
WINDOW_WIDTH = 720  

VIRTUAL_HEIGHT = 320
VIRTUAL_WIDTH = 240 

-- A range of variables related to the explosion animation
explode = 0

local exp_atlas
local exp_sprite

local fps = 12
local anim_timer = 1 / fps
local frame = 0
local num_frames = 6
local xoffset

-- Variable to check if player is alive
isAlive = true

-- Variables relating to background scrolling
scrollSpeed = 80

-- Variable allowing keyboard control of player while at 0
keys = 0

-- Variable to count number of enemies generated
enemiesOut = 0

-- Variables relating to Boss section at end
enemiesLimit = 80
bossMode = 0

-- Variable relating to 'true final boss' status
tfb = 0

-- All bullet variables here:
-- Bullet timers
canShoot = true
canShootTimerMax = 0.2 
canShootTimer = canShootTimerMax
-- Bullet images
bulletImg = nil
-- Bullet entity storage
bullets = {} -- array of current bullets being drawn and updated

-- Enemy variables here:
-- Enemy timers
createEnemyTimerMax = 0.2
createEnemyTimer = createEnemyTimerMax
-- Enemy images
enemyImg = nil
-- Enemy entity storage
enemies = {} -- array of current enemies on screen


-- Collision detection taken function from http://love2d.org/wiki/BoundingBox.lua,
-- Returns true if two boxes overlap, false if they don't.
-- x1,y1 are the left-top coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box
function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
  end


--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()

    -- Set Love's default filter to "nearest-neighbor", for pixel goodness
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- Set the title of our application window
    love.window.setTitle('UFO CRISIS 20XX')

    -- Seed the RNG for randomisation purposes
    math.randomseed(os.time())

    -- Initialize fonts
    titleFont = love.graphics.newFont('fonts/font1.ttf', 48)
    mainFont = love.graphics.newFont('fonts/font2.ttf', 16)
    love.graphics.setFont(mainFont)

    -- Load 'high' and 'p1' images
    highImg = love.graphics.newImage('graphics/high.png')
    p1Img = love.graphics.newImage('graphics/p1.png')

    -- Load copyright image
    copyImg = love.graphics.newImage('graphics/copyright.png')

    -- Set up level background details
    bgrndImg = love.graphics.newImage("graphics/bgrnd1.png")
    camera_x = 0
    camera_y = 0

    -- Load player shot image
    bulletImg = love.graphics.newImage('graphics/pShot.png')

    -- Load enemy image
    enemyImg = love.graphics.newImage('graphics/ufo1.png')

    -- Load 'lives' images (yes, it would be better to just have one and
    -- repeat it as needed, but I had enough headaches at that point)
    lives1 = love.graphics.newImage('graphics/life.png')
    lives2 = love.graphics.newImage('graphics/life2.png')

    -- Load boss warning image
    warningImg = love.graphics.newImage('graphics/warning.png')

    -- Create explosion atlas & quad
    exp_atlas = love.graphics.newImage('graphics/explosion.png')
    exp_sprite = love.graphics.newQuad(0, 0, 32, 32, exp_atlas:getDimensions())
 
    -- Set up our sound effects
    sounds = {
        ['death'] = love.audio.newSource('sounds/death.wav', 'static'),
        ['explosion'] = love.audio.newSource('sounds/explosion.wav', 'static'),
        ['miaow'] = love.audio.newSource('sounds/miaow.wav', 'static'),
        ['shoot'] = love.audio.newSource('sounds/shoot.wav', 'static'),
        ['bosswarning'] = love.audio.newSource('sounds/bosswarning.wav', 'static'),
        ['bossdeath'] = love.audio.newSource('sounds/bossdeath.wav', 'static')
    }

    -- Set up our music
    music = {
        ['bossM'] = love.audio.newSource('music/bossmusic.wav', 'stream'),
        ['endM'] = love.audio.newSource('music/endmusic.wav', 'stream'),
        ['gameoverM'] = love.audio.newSource('music/gameovermusic.wav', 'stream'),
        ['levelM'] = love.audio.newSource('music/levelmusic.wav', 'stream'),
        ['tfbM'] = love.audio.newSource('music/tfbmusic.wav', 'stream'),
        ['titleM'] = love.audio.newSource('music/titlemusic.wav', 'stream')
    }

    -- Initialize window with virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = true,
        vsync = true
    })
    
    -- initialize score & health variables
        hiScore = 10
        playerScore = 0
        playerLives = 3

    -- initialize player
    player = Player()

    -- initialise boss
    boss = Boss()

    gameState = 'title'

    -- Run music function
    playMusic()

end


-- Making it possible to resize screen, with virtual resolution maintained
function love.resize(w, h)
    push:resize(w, h)
end


function love.update(dt)
    --[[
     Setting keyboard inputs for player, with limits on vertical & horizontal
     movement to prevent going beyond screen bounds, and controls set to enable
     diagonal movement.

     In the case of diagonal movement, we check to see if 2 buttons are being held
     simultaneously and, if so, divide speed value with square root of 2 before
     applying to x & y positions, so as to keep speed constant.
     
     First of all setting variables to simplify code:
    ]]
    downUp = love.keyboard.isDown("down") or love.keyboard.isDown("up")
    leftRight = love.keyboard.isDown("left") or love.keyboard.isDown("right")
    speed = player.speed

    -- Now the keyboard input code itself, which will only work if
    -- keys = 0 (which means we can disable player control at a later point):

    if keys == 0 then
        if(downUp and leftRight) then
            speed = speed / math.sqrt(2)
        end

        if love.keyboard.isDown('down', 's') and player.y < VIRTUAL_HEIGHT - player.height then
            player.y = player.y + dt * speed
        elseif love.keyboard.isDown('up', 'w') and player.y > 0 then
            player.y = player.y - dt * speed
        end
        
        if love.keyboard.isDown('right', 'd') and player.x < VIRTUAL_WIDTH - player.width then
            player.x = player.x + dt * speed
        elseif love.keyboard.isDown('left', 'a') and player.x > 0 then
            player.x = player.x - dt * speed
        end
    end

    -- Using a timer to calculate time between permitted player shots
    canShootTimer = canShootTimer - (1 * dt)
    if canShootTimer < 0 then
    canShoot = true
    end

    -- If gameState is play and 'space' pressed and timer allows...
    if gameState == 'play' or gameState == 'boss' and keys == 0 then
        if love.keyboard.isDown('space', 'z') and canShoot then
            -- Play 'shoot' sound effect, with cloning for
            -- repeating sound
            local clone_shoot = sounds['shoot']:clone()
            clone_shoot:play()
            -- Create bullets
            newBullet = { x = player.x + (player.width / 2 - 2), y = player.y, img = bulletImg }
            table.insert(bullets, newBullet)
            canShoot = false
            canShootTimer = canShootTimerMax
        end
    end

    -- Update positions of bullets
    for i, bullet in ipairs(bullets) do
        bullet.y = bullet.y - (270 * dt)
    
          if bullet.y < 0 then -- Remove bullets when they pass off the screen
            table.remove(bullets, i)
        end
    end

    -- If game state is 'play', start creating enemies:
    if gameState == 'play' then
        if enemiesOut < enemiesLimit and bossMode == 0 then
        -- Timer for enemy creation
            createEnemyTimer = createEnemyTimer - (1 * dt)
            if createEnemyTimer < 0 then
	            createEnemyTimer = createEnemyTimerMax

	            -- Create an enemy
	            randomNumber = math.random(10, VIRTUAL_WIDTH - 10)
                newEnemy = { x = randomNumber, y = -10, img = enemyImg }
                -- Update number of enemies that have been created overall ('enemiesOut')
                -- Further on, once this reaches a set limit, the game state will change
                -- to 'boss', thereby stopping this process from running.
                enemiesOut = enemiesOut + 1
	            table.insert(enemies, newEnemy)
            end
        end
        -- Update enemy positions
        for i, enemy in ipairs(enemies) do
            -- Set speed speed of enemy
	        enemy.y = enemy.y + (210 * dt)

	        if enemy.y > 350 then -- Remove enemies when they pass off the screen
		        table.remove(enemies, i)
	        end
        end


        -- Collision detection
        -- First check enemies, then bullets
        for i, enemy in ipairs(enemies) do
	        for j, bullet in ipairs(bullets) do
		        if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
                    table.remove(bullets, j)
                    -- Take note of hit enemy X & Y for explosion use
                    expX = enemy.x
                    expY = enemy.y
                    -- Set 'explode' to 1 to trigger explosion
                    explode = 1
                    -- Play explosion sound effect using cloning for multiple instances
                    local clone_explosion = sounds['explosion']:clone()
                    clone_explosion:play()
                    table.remove(enemies, i)
			        playerScore = playerScore + 1
		        end
	        end
            -- Also need to check if enemies hit player
	        if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), player.x + 3, player.y + 3, player.width - 6, player.height - 6) 
	        and isAlive then
                table.remove(enemies, i)
                plaX = player.x - 6
                plaY = player.y
                -- Set 'explode' to 2 to trigger explosion at player position
                explode = 2
                sounds['death']:play()
                playerLives = playerLives - 1
		        isAlive = false
	        end
        end
    end

    -- Collision detection for boss
    -- First for bullets:
    if gameState == 'boss' and boss.health > 0 then
        for j, bullet in ipairs(bullets) do
            if CheckCollision(boss.x, boss.y, 93, 83, bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
                table.remove(bullets, j)
                boss.health = boss.health - 1
                if boss.health == 0 then
                    expX = boss.x + 100
                    expY = boss.y + 85
                    explode = 3
                end
                local clone_miaow = sounds['miaow']:clone()
                clone_miaow:play()
                playerScore = playerScore + 1
            end
        end
    end
    -- Now to check if boss collides with player:
    if gameState == 'boss' and boss.health > 0 then
        if CheckCollision(boss.x, boss.y, 93, 83, player.x + 6, player.y + 6, player.width - 12, player.height - 12) 
	        and isAlive then
                plaX = player.x - 6
                plaY = player.y
                explode = 2
                local clone_death = sounds['death']:clone()
                clone_death:play()
                playerLives = playerLives - 1
                isAlive = false
                -- Move boss out of the way, depending on player's position,
                -- so that they aren't immediately killed again!
                if player.y < boss.y then
                    boss.y = boss.y + 60
                else
                    boss.y = boss.y - 60
                end
                if player.x < boss.x then
                    boss.x = boss.x + 60
                else
                    boss.x = boss.x - 60
                end
            end
        end

    -- Change 'bossMode' variable to 1, based on how many enemies have already been released
    -- (note, see above enemy spawning function where same limit has been used)
    if enemiesOut == enemiesLimit then
        bossMode = 1
        enemiesOut = 0
    end
    
    -- Call playMusic function if gameState is 'end'
    if gameState == 'end' then
        playMusic()
    end

    -- This relates to background scrolling, needs to be in 'update'
    camera_y = camera_y + scrollSpeed * dt

    -- Update player & boss
    player:update(dt)
    boss:update(dt)

end


--  Keyboard handling, called by LÖVE2D each frame
function love.keypressed(key)

    -- Pressing 'escape' quits the game
    if key == 'escape' then
        love.event.quit()

    -- Pressing 'return' does various things depending on what game state is!
    elseif key == 'enter' or key == 'return' then
        if gameState == 'title' then
            gameState = 'play'
            playMusic()
        elseif gameState == 'gameover' or gameState == 'end' then
            if playerScore > hiScore then
                hiScore = playerScore
            end
            gameState = 'title'
            playerLives = 3
            playerScore = 0
            enemiesOut = 0
            keys = 0
            playMusic()
            player:init()
            boss:init()
            scrollSpeed = 80
        end
    end
    
end



function love.draw()

    push:apply('start')

    -- Clear the screen with black background
    if gameState == 'title' then
        love.graphics.clear(0, 0, 0, 0)
        love.graphics.draw(copyImg, 186, 306)
    end

    -- If state is 'title' then print title screen text
    if gameState == 'title' then
        love.graphics.setFont(titleFont)
        love.graphics.printf('UFO CRISIS\n20XX', 0, VIRTUAL_HEIGHT / 2 - 60, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(mainFont)
        love.graphics.printf('PRESS ENTER TO START', 0, VIRTUAL_HEIGHT / 2 + 40, VIRTUAL_WIDTH, 'center')
    end

 
    -- If state is anything other than 'title' or 'end', draw level background
    if gameState == 'play' or gameState == 'gameover' or gameState == 'boss' then
        local w, h = bgrndImg:getDimensions()
        local start_x = (camera_x % w) - w
        local start_y = (camera_y % h) - h
        local tile_x = math.ceil(love.graphics.getWidth() / w)
        local tile_y = math.ceil(love.graphics.getHeight() / h)
        for i=0,tile_x do
            for j=0,tile_y do
                love.graphics.draw(bgrndImg, start_x + i * w, start_y + j * h)
            end
        end
    end

    -- Run score functions / display score headers
    -- These will be on display constantly, regardless of state
    displayScore()
    displayHiScore()
    love.graphics.draw(highImg, 90, 6)
    love.graphics.draw(p1Img, 190, 6)

    -- Print 'game over' messages if that's the game state
    if gameState == 'gameover' then
        playMusic()
        if playerScore > hiScore then
            love.graphics.printf('NEW HIGH SCORE!', 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, 'center')
        end
        love.graphics.printf('GAME  OVER', 0, VIRTUAL_HEIGHT / 2 - 30, VIRTUAL_WIDTH, 'center')
    end

    -- Print end sequence messages at state 'end', depending on conditions
    if gameState == 'end' and boss.tfb == 0 then
        love.graphics.print('The UFO threat is countered\nand justice made manifest.\n\nBut can we ever know peace?\n\nThrough smoke and tears, you\ndream of an end to this\npitiless war of the future.', 45, 90)
    elseif gameState == 'end' and boss.tfb == 1 then
        love.graphics.print('The storm of tears & sweat\nis abated. An eternal peace\nbelongs to you and your\ndescendants.\n\nThe wreckage of the true\n"UFO Crisis" must fade to\ntime as if a dream.\n\nOnly in your heart will\nthis survive.\n\nThanks for playing.', 45, 90)
    end

    -- If state is 'boss', call playMusic function & render boss
    if gameState == 'boss' then
        playMusic()
        boss:render()
    end

    -- If state is 'play' or 'boss' then render player
    if gameState == 'play' or gameState == 'boss' then
        player:render()
    end

    -- If state is 'play' or 'boss', draw bullets
    if gameState == 'play' or gameState == 'boss' then
        for i, bullet in ipairs(bullets) do
            love.graphics.draw(bullet.img, bullet.x, bullet.y)
        end
    end

    -- Draw enemies
    -- Checking for gameState first, so we don't have enemies appearing where they're not wanted!
    if gameState == 'play' then
        for i, enemy in ipairs(enemies) do
            love.graphics.draw(enemy.img, enemy.x, enemy.y)
        end
    end

    -- Slightly janky animation process for explosions when
    -- enemy takes a hit
    if explode == 1 then
        love.graphics.draw(exp_atlas, exp_sprite, expX, expY)
        anim_timer = anim_timer - 0.05
        if anim_timer <= 0 then
            anim_timer = 1 / fps
            frame = frame + 1
            if frame > num_frames then
                explode = 0
                anim_timer = 1 / fps
                frame = 0
            end
            xoffset = 32 * frame
            exp_sprite:setViewport(xoffset, 0, 32, 32)
        end
    end

        -- Slightly janky animation process for explosions when
    -- player takes a hit
    if explode == 2 then
        love.graphics.draw(exp_atlas, exp_sprite, plaX, plaY)
        anim_timer = anim_timer - 0.05
        if anim_timer <= 0 then
            anim_timer = 1 / fps
            frame = frame + 1
            if frame > num_frames then
                explode = 0
                anim_timer = 1 / fps
                frame = 0
            end
            xoffset = 32 * frame
            exp_sprite:setViewport(xoffset, 0, 32, 32)
        end
    end

    -- Slightly janky animation process for explosion when
    -- boss dies
    if explode == 3 then
        love.graphics.draw(exp_atlas, exp_sprite, expX, expY, 3, 3)
        anim_timer = anim_timer - 0.05
        if anim_timer <= 0 then
            anim_timer = 1 / fps
            frame = frame + 1
            if frame > num_frames then
                explode = 0
                anim_timer = 1 / fps
                frame = 0
            end
            xoffset = 32 * frame
            exp_sprite:setViewport(xoffset, 0, 32, 32)
        end
    end

    -- Draw lives indicator
    if gameState == 'play' or gameState == 'boss' then
        if playerLives == 3 then
            love.graphics.draw(lives2, 10, 5)
        elseif playerLives == 2 then
            love.graphics.draw(lives1, 10, 5)
        end
    end


    -- A couple of 'ifs' to make Boss warning music play...
    if bossMode == 1 then
        love.audio.stop()
        sounds['bosswarning']:play()
        bossMode = 2
    end
    -- And to display the 'warning' message while the music is playing.
    if sounds['bosswarning']:isPlaying() then
        love.graphics.draw(warningImg, VIRTUAL_WIDTH / 2 - 60, VIRTUAL_HEIGHT / 2 - 40)
    end

    if bossMode == 2 and sounds['bosswarning']:isPlaying() == false then
        gameState = 'boss'
    end


    push:apply('end')

end


function displayScore()
    -- Draw score at the top center of the screen, padding with zeros as needed
    if playerScore < 10 then
        love.graphics.print("0000" .. tostring(playerScore) .. "00", VIRTUAL_WIDTH - 50, 10)
    elseif playerScore >=10 then
        if playerScore < 100 then
            love.graphics.print("000" .. tostring(playerScore) .. "00", VIRTUAL_WIDTH - 50, 10)
        elseif playerScore >= 100 then
            love.graphics.print("00" .. tostring(playerScore) .. "00", VIRTUAL_WIDTH - 50, 10)
        end
    end
end

-- Display high score, padding with zeros as needed
function displayHiScore()
    if hiScore >=10 then
        if hiScore < 100 then
            love.graphics.print("000" .. tostring(hiScore) .. "00", VIRTUAL_WIDTH / 2 - 30, 10)
        elseif hiScore >= 100 then
            love.graphics.print("00" .. tostring(hiScore) .. "00", VIRTUAL_WIDTH / 2 - 30, 10)
        end
    end
end

-- This controls what music is playing when, stopping
-- & starting as needed
function playMusic()
    if gameState == 'title' then
        love.audio.stop()
        music['titleM']:setLooping(true)
        music['titleM']:play()
    elseif gameState == 'play' then
        love.audio.stop()
        music['levelM']:setLooping(true)
        music['levelM']:play()
    elseif gameState == 'gameover' then
        if music['levelM']:isPlaying() then
            music['levelM']:stop()
        elseif music['bossM']:isPlaying() then
            music['bossM']:stop()
        elseif music['tfbM']:isPlaying() then
            music['tfbM']:stop()            
        end
        music['gameoverM']:setLooping(true)
        music['gameoverM']:play()
    elseif gameState == 'boss' and boss.health > 0 and boss.tfb == 0 then
        music['bossM']:setLooping(true)
        music['bossM']:play()
    elseif gameState == 'boss' and boss.health > 0 and boss.tfb == 1 then
        music['tfbM']:setLooping(true)
        music['tfbM']:play()
    end

    if boss.health == 0 then
        if music['bossM']:isPlaying() then
        music['bossM']:stop()
        elseif music['tfbM']:isPlaying() then
        music['tfbM']:stop()
        end
    end

    if gameState == 'end' then
        music['endM']:setLooping(true)
        music['endM']:play()
    end
end

-- Function to be called to check if true final boss requirements met
function checkTFB()
    if playerLives == 3 and playerScore >= 90 then
    return true
    else
        return false
end

end