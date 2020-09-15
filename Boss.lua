--[[ 
    Boss Class
]]

Boss = Class{}

--[[ 
    Init called at start when Player first created.
    All variables should be set up here.
]]

function Boss:init()
    self.x = 75
    self.y = -90
    self.texture = love.graphics.newImage('graphics/boss.png')
    self.TFBtexture = love.graphics.newImage('graphics/tfb.png')
    self.width = 93
    self.height = 83
    self.speed = 25
    self.health = 40
    self.tfb = 0
end

function Boss:update(dt)

    -- This controls movement of boss, having it follow the player around
    if gameState == 'boss' and self.health > 0 then
        if (self.x + 35) < player.x then 				    -- If boss is to the left of the player:
        self.x = self.x + (self.speed * 2.5 * dt)			-- boss moves right.
        end
     
        if (self.x + 35) > player.x then 					-- If boss is to the right of the player:
        self.x = self.x - (self.speed * 2.5 * dt) 			-- boss moves left.
        end
     
        if (self.y + 35) < player.y then 					-- If boss is above the player:
        self.y = self.y + (self.speed * 2.5 * dt)			-- boss moves downwards.
        end
     
        if (self.y + 35) > player.y then 					-- If boss is below the player:
        self.y = self.y - (self.speed * 2.5 * dt)           -- boss moves upwards.
        end
    end

    -- If boss is killed (health = 0) then starts end process
    if self.health == 0 then
        playMusic()
        sounds['bossdeath']:play()
        scrollSpeed = 0
        keys = 1
        player.y = player.y - dt * speed
    end


    --[[ 
        System in place so that:
        - if you defeat boss with 'true final boss' conditions in place,
        then after boss dies the TFB spawns (same boss, but different texture, 
        increased speed, and also different music playing)
        - if you defeat the TFB with TFB conditions STILL in place (i.e.
        you haven't lost a life yet) then a further TFB spawns at an 
        increased speed. This keeps going for as long as you can avoid
        losing a life!
        - If you die, you go to game over; if you defeat the normal boss
        then you get the normal ending; if you defeat the TFB you get a
        special ending.
    ]]
    if self.health == 0 and player.y < 0 and checkTFB() == false then
        gameState = 'end'
        bossMode = 0
        self.health = -1
    elseif self.health == 0 and player.y < 0 and checkTFB() == true then
        sounds['bossdeath']:stop()
        self.tfb = 1
        keys = 0
        scrollSpeed = 80
        self.x = 75
        self.y = 310
        self.health = 40
        self.speed = self.speed + 3
        end
    end

    -- Boss is rendered in one of 2 different ways, depending on TFB conditions.
function Boss:render()
    if gameState == 'boss' and self.health > 0 and self.tfb == 0 then
        love.graphics.draw(self.texture, self.x, self.y)
    elseif gameState == 'boss' and self.health > 0 and self.tfb == 1 then
        love.graphics.draw(self.TFBtexture, self.x, self.y)
    end
end