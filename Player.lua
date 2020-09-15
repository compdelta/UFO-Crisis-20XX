--[[ 
    Player Class
]]

Player = Class{}

--[[ 
    Init called at start when Player first created.
    All variables should be set up here.
]]

function Player:init()
    self.x = 110
    self.y = 270
    self.width = 21
    self.height = 30
    self.speed = 170
    self.dx = 0
    self.dy = 0
    self.texture = love.graphics.newImage('graphics/ship.png')
  
end

function Player:update(dt)

    -- If game over (i.e. all lives lost)
    if playerLives == 0 then
        bossMode = 0
        gameState = 'gameover'
        scrollSpeed = 0
        -- Remove all bullets and enemies from screen
        bullets = {}
        enemies = {}
    end

    -- If players loses a life
    if not isAlive then
        -- Remove all bullets and enemies from screen
        bullets = {}
        enemies = {}
    
        -- Reset timers
        canShootTimer = canShootTimerMax
        createEnemyTimer = createEnemyTimerMax
    
        -- Make player 'alive' again
        isAlive = true
    end

end

-- Render player if game is in 'play' or 'boss' modes
function Player:render()
    if gameState == 'play' or gameState == 'boss' then
        love.graphics.draw(self.texture, math.floor(self.x), math.floor(self.y))
    end
end
