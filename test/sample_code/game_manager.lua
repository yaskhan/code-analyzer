-- Game State Management System
-- Demonstrates Lua tables, metatables, modules, and OOP patterns

local GameState = {}
local GameStateMT = { __index = GameState }

--- Game entity base class
local Entity = {}
local EntityMT = { __index = Entity }

--- Creates a new entity
--- @param name string Name of the entity
--- @param entityType string Type of entity
--- @return Entity
function Entity.new(name, entityType)
    local entity = {
        name = name,
        entityType = entityType,
        position = { x = 0, y = 0 },
        health = 100,
        maxHealth = 100,
        isAlive = true,
        components = {}
    }
    setmetatable(entity, EntityMT)
    return entity
end

--- Sets entity position
--- @param x number X coordinate
--- @param y number Y coordinate
function Entity:setPosition(x, y)
    self.position.x = x
    self.position.y = y
end

--- Gets entity position
--- @return table Position coordinates
function Entity:getPosition()
    return { x = self.position.x, y = self.position.y }
end

--- Takes damage
--- @param damage number Amount of damage
function Entity:takeDamage(damage)
    self.health = math.max(0, self.health - damage)
    if self.health <= 0 then
        self.isAlive = false
    end
end

--- Heals the entity
--- @param heal number Amount to heal
function Entity:heal(heal)
    self.health = math.min(self.maxHealth, self.health + heal)
    if self.health > 0 then
        self.isAlive = true
    end
end

--- Checks if entity is alive
--- @return boolean True if entity is alive
function Entity:isAlive()
    return self.isAlive
end

--- Adds a component to the entity
--- @param component table Component to add
function Entity:addComponent(component)
    self.components[component.type] = component
end

--- Gets a component by type
--- @param componentType string Type of component
--- @return table Component if found, nil otherwise
function Entity:getComponent(componentType)
    return self.components[componentType]
end

--- Player entity that extends Entity
local Player = setmetatable({}, EntityMT)
Player.__index = Player

--- Creates a new player
--- @param name string Player name
--- @return Player
function Player.new(name)
    local player = Entity.new(name, "Player")
    player.level = 1
    player.experience = 0
    player.experienceToNext = 100
    player.inventory = {}
    player.equipment = {
        weapon = nil,
        armor = nil,
        accessory = nil
    }
    setmetatable(player, Player)
    return player
end

--- Levels up the player
function Player:levelUp()
    self.level = self.level + 1
    self.maxHealth = self.maxHealth + 10
    self.health = self.maxHealth -- Full heal on level up
    self.experience = self.experience - self.experienceToNext
    self.experienceToNext = self.experienceToNext * 1.5
end

--- Adds experience points
--- @param amount number Experience to add
function Player:addExperience(amount)
    self.experience = self.experience + amount
    while self.experience >= self.experienceToNext do
        self:levelUp()
    end
end

--- Adds item to inventory
--- @param item table Item to add
function Player:addItem(item)
    table.insert(self.inventory, item)
end

--- Removes item from inventory
--- @param item table Item to remove
--- @return boolean True if item was found and removed
function Player:removeItem(item)
    for i, invItem in ipairs(self.inventory) do
        if invItem.id == item.id then
            table.remove(self.inventory, i)
            return true
        end
    end
    return false
end

--- Equips an item
--- @param item table Item to equip
--- @return boolean True if item was equipped
function Player:equipItem(item)
    if not self:removeItem(item) then
        return false -- Item not in inventory
    end
    
    -- Unequip current item if any
    if self.equipment[item.slot] then
        self:addItem(self.equipment[item.slot])
    end
    
    -- Equip new item
    self.equipment[item.slot] = item
    return true
end

--- Calculates total player stats
--- @return table Combined stats from base and equipment
function Player:getTotalStats()
    local stats = {
        health = self.maxHealth,
        attack = 10, -- Base attack
        defense = 5, -- Base defense
        speed = 8    -- Base speed
    }
    
    -- Add equipment bonuses
    for _, item in pairs(self.equipment) do
        if item and item.stats then
            for stat, value in pairs(item.stats) do
                stats[stat] = (stats[stat] or 0) + value
            end
        end
    end
    
    return stats
end

--- Enemy entity that extends Entity
local Enemy = setmetatable({}, EntityMT)
Enemy.__index = Enemy

--- Creates a new enemy
--- @param name string Enemy name
--- @param enemyType string Type of enemy
--- @return Enemy
function Enemy.new(name, enemyType)
    local enemy = Entity.new(name, "Enemy")
    enemy.attack = 15
    enemy.defense = 8
    enemy.experienceValue = 25
    enemy.lootTable = {}
    setmetatable(enemy, Enemy)
    return enemy
end

--- Attacks a target entity
--- @param target Entity Entity to attack
function Enemy:attack(target)
    if not self.isAlive or not target:isAlive() then
        return
    end
    
    local damage = math.max(1, self.attack - target.defense)
    target:takeDamage(damage)
    
    print(string.format("%s attacks %s for %d damage!", 
                       self.name, target.name, damage))
    
    if not target:isAlive() then
        print(string.format("%s has been defeated!", target.name))
    end
end

--- Drops loot when defeated
--- @return table Array of dropped items
function Enemy:dropLoot()
    local droppedItems = {}
    
    for _, lootItem in ipairs(self.lootTable) do
        if math.random() < lootItem.dropChance then
            table.insert(droppedItems, lootItem.item)
        end
    end
    
    return droppedItems
end

--- Game world that manages entities
local World = {}

--- Creates a new game world
--- @return World
function World.new()
    local world = {
        entities = {},
        players = {},
        enemies = {},
        width = 100,
        height = 100,
        timeOfDay = "day" -- day, night, dawn, dusk
    }
    return world
end

--- Adds an entity to the world
--- @param entity Entity Entity to add
function World:addEntity(entity)
    table.insert(self.entities, entity)
    
    if entity.entityType == "Player" then
        table.insert(self.players, entity)
    elseif entity.entityType == "Enemy" then
        table.insert(self.enemies, entity)
    end
end

--- Removes an entity from the world
--- @param entity Entity Entity to remove
--- @return boolean True if entity was removed
function World:removeEntity(entity)
    -- Remove from entities
    for i, ent in ipairs(self.entities) do
        if ent == entity then
            table.remove(self.entities, i)
            break
        end
    end
    
    -- Remove from players or enemies
    local list = entity.entityType == "Player" and self.players or self.enemies
    for i, plr in ipairs(list) do
        if plr == entity then
            table.remove(list, i)
            break
        end
    end
    
    return true
end

--- Updates all entities in the world
--- @param dt number Delta time
function World:update(dt)
    -- Update all entities
    for _, entity in ipairs(self.entities) do
        if entity.update then
            entity:update(dt)
        end
    end
    
    -- Clean up dead entities
    for i = #self.entities, 1, -1 do
        local entity = self.entities[i]
        if not entity:isAlive() then
            self:removeEntity(entity)
        end
    end
end

--- Finds entities within range
--- @param x number Center X coordinate
--- @param y number Center Y coordinate
--- @param range number Search range
--- @return table Array of nearby entities
function World:findEntitiesInRange(x, y, range)
    local nearby = {}
    local rangeSquared = range * range
    
    for _, entity in ipairs(self.entities) do
        local dx = entity.position.x - x
        local dy = entity.position.y - y
        local distanceSquared = dx * dx + dy * dy
        
        if distanceSquared <= rangeSquared then
            table.insert(nearby, entity)
        end
    end
    
    return nearby
end

--- Gets living players
--- @return table Array of living players
function World:getLivingPlayers()
    local livingPlayers = {}
    for _, player in ipairs(self.players) do
        if player:isAlive() then
            table.insert(livingPlayers, player)
        end
    end
    return livingPlayers
end

--- Gets living enemies
--- @return table Array of living enemies
function World:getLivingEnemies()
    local livingEnemies = {}
    for _, enemy in ipairs(self.enemies) do
        if enemy:isAlive() then
            table.insert(livingEnemies, enemy)
        end
    end
    return livingEnemies
end

--- Game state manager
function GameState.new()
    local gameState = {
        world = World.new(),
        currentState = "menu", -- menu, playing, paused, gameOver
        score = 0,
        level = 1,
        gameTime = 0,
        config = {
            maxPlayers = 4,
            enableAI = true,
            debugMode = false
        }
    }
    setmetatable(gameState, GameStateMT)
    return gameState
end

--- Changes game state
--- @param newState string New game state
function GameState:changeState(newState)
    local oldState = self.currentState
    self.currentState = newState
    
    print(string.format("Game state changed from %s to %s", oldState, newState))
    
    -- Handle state transitions
    if newState == "playing" then
        self:startGame()
    elseif newState == "paused" then
        self:pauseGame()
    elseif newState == "gameOver" then
        self:endGame()
    end
end

--- Starts a new game
function GameState:startGame()
    self.world = World.new()
    self.score = 0
    self.level = 1
    self.gameTime = 0
    
    -- Create a test player
    local player = Player.new("Hero")
    player:setPosition(50, 50)
    
    -- Add some test equipment
    local sword = {
        id = "iron_sword",
        name = "Iron Sword",
        slot = "weapon",
        stats = { attack = 15 }
    }
    
    local armor = {
        id = "leather_armor",
        name = "Leather Armor",
        slot = "armor",
        stats = { defense = 10 }
    }
    
    player:addItem(sword)
    player:addItem(armor)
    
    -- Create some enemies
    local goblin = Enemy.new("Goblin", "Humanoid")
    goblin:setPosition(30, 30)
    goblin.lootTable = {
        { item = { id = "gold", name = "Gold Coin" }, dropChance = 0.8 }
    }
    
    local orc = Enemy.new("Orc", "Humanoid")
    orc:setPosition(70, 70)
    orc.lootTable = {
        { item = { id = "health_potion", name = "Health Potion" }, dropChance = 0.6 }
    }
    
    -- Add entities to world
    self.world:addEntity(player)
    self.world:addEntity(goblin)
    self.world:addEntity(orc)
    
    print("New game started!")
    print(string.format("Player %s created at position (%d, %d)", 
                       player.name, player:getPosition().x, player:getPosition().y))
end

--- Pauses the game
function GameState:pauseGame()
    print("Game paused")
end

--- Ends the game
function GameState:endGame()
    print(string.format("Game Over! Final Score: %d, Level: %d", self.score, self.level))
end

--- Updates the game state
--- @param dt number Delta time
function GameState:update(dt)
    if self.currentState == "playing" then
        self.gameTime = self.gameTime + dt
        self.world:update(dt)
        
        -- Simple AI for enemies
        if self.config.enableAI then
            self:updateAI(dt)
        end
        
        -- Check win/lose conditions
        self:checkGameConditions()
    end
end

--- Updates AI behavior
--- @param dt number Delta time
function GameState:updateAI(dt)
    local players = self.world:getLivingPlayers()
    local enemies = self.world:getLivingEnemies()
    
    -- Simple AI: enemies attack nearest player
    for _, enemy in ipairs(enemies) do
        if enemy.attack and #players > 0 then
            local nearestPlayer = nil
            local nearestDistance = math.huge
            
            for _, player in ipairs(players) do
                local dx = player.position.x - enemy.position.x
                local dy = player.position.y - enemy.position.y
                local distance = math.sqrt(dx * dx + dy * dy)
                
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestPlayer = player
                end
            end
            
            -- Attack if in range
            if nearestDistance <= 10 then
                enemy:attack(nearestPlayer)
            end
        end
    end
end

--- Checks win/lose conditions
function GameState:checkGameConditions()
    local players = self.world:getLivingPlayers()
    local enemies = self.world:getLivingEnemies()
    
    -- Lose condition: all players dead
    if #players == 0 then
        self:changeState("gameOver")
        return
    end
    
    -- Win condition: all enemies defeated
    if #enemies == 0 then
        self.score = self.score + 100
        self.level = self.level + 1
        print(string.format("Level %d complete! Score: %d", self.level, self.score))
        
        -- Spawn new enemies for next level
        self:spawnNextLevelEnemies()
    end
end

--- Spawns enemies for the next level
function GameState:spawnNextLevelEnemies()
    local enemyCount = self.level * 2
    
    for i = 1, enemyCount do
        local enemy = Enemy.new(string.format("Level%d_Enemy%d", self.level, i), "Humanoid")
        enemy:setPosition(
            math.random(0, self.world.width),
            math.random(0, self.world.height)
        )
        -- Scale enemy stats with level
        enemy.attack = enemy.attack + (self.level - 1) * 2
        enemy.maxHealth = enemy.maxHealth + (self.level - 1) * 5
        enemy.health = enemy.maxHealth
        
        self.world:addEntity(enemy)
    end
    
    print(string.format("Spawned %d enemies for level %d", enemyCount, self.level))
end

--- Gets game statistics
--- @return table Game statistics
function GameState:getStatistics()
    return {
        state = self.currentState,
        score = self.score,
        level = self.level,
        gameTime = self.gameTime,
        playerCount = #self.world.players,
        enemyCount = #self.world.enemies,
        livingPlayers = #self.world:getLivingPlayers(),
        livingEnemies = #self.world:getLivingEnemies()
    }
end

--- Module return
return {
    GameState = GameState,
    Player = Player,
    Enemy = Enemy,
    Entity = Entity,
    World = World
}