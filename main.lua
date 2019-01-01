function love.load()
    math.randomseed(os.time())
    --G = 6.67 × 10^−11 N m² / kg²
    G = 6.67 * 0.0000000000001
    M = 1.9885 * 10^30  -- sun mass (oter mass are expressed in sun masses
    S = 200000 -- scale
    level = 1
    fuel = 100
    love.window.setFullscreen(true,"desktop")
    maxx = love.graphics.getWidth()
    maxy = love.graphics.getHeight()
    createSolarSystem()
    debug = true
    debugmessages = {}
---------------------------------
-- particle system for engines --
---------------------------------
    local img = love.graphics.newImage('particle.png')
    psystem = {}
    for engine,power in pairs(enginepower) do
        psystem[engine] = love.graphics.newParticleSystem(img, 32)
        psystem[engine]:setParticleLifetime(0.1, 1) -- Particles live at least 2s and at most 5s.
        psystem[engine]:setEmissionRate(0)
        psystem[engine]:setSizeVariation(0.5)
        psystem[engine]:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.
    end
    psystem["down"]:setLinearAcceleration(-50, -100, 50, -150)
    psystem["up"]:setLinearAcceleration(-50, 100, 50, 150)
    psystem["right"]:setLinearAcceleration(-100, -50, -150, 50)
    psystem["left"]:setLinearAcceleration(100, -50, 150, 50)
-------------------------
end

-------------------------
-- Keyboard management --
-------------------------

local keys = {}

local function down(k)
  for i = 1, #keys do
    if keys[i] == k then return i end
  end
  return false
end

function love.keypressed(k)
  if not down(k) then table.insert(keys, k) end
end

function love.keyreleased(key)
  local index = down(key)
  if index then table.remove(keys, index) end

-- reset level
   if key == "space" then
      createSolarSystem()
   end
-------------------------
-- quit
   if key == "escape" then
      love.event.quit()
   end
-------------------------
end

function love.update(dt)
-------------------------
-- Keyboard management --
-------------------------
    -- set engine power to 0 if key is not pressed
    local engineson = { up = false, down = false, right = false, left = false }
    for k,key in pairs(keys) do
        if engineson[key] ~= nil then
	    if fuel > 0 then
                engineson[key] = true
                if enginepower[key] < 100 then
                    enginepower[key] = enginepower[key] + ( 20 * dt / 0.1 ) -- increase 20% engine power every 0.1 seconds
                elseif enginepower[key] > 100 then
                    enginepower[key] = 100
                end
                fuel = fuel - ( enginepower[key]/100 * dt / 1 ) -- decrease fuel level by engine power every second
	    end

            if key == "up" then
                p.dy = p.dy - 0.5 * S * enginepower[key]/100 -- Accel of 0.5 m^2 * Scale * % of engine power
            elseif key == "down" then
                p.dy = p.dy + 0.5 * S * enginepower[key]/100 -- Accel of 0.5 m^2 * Scale * % of engine power
            elseif key == "right" then
                p.dx = p.dx + 0.5 * S * enginepower[key]/100 -- Accel of 0.5 m^2 * Scale * % of engine power
            elseif key == "left" then
                p.dx = p.dx - 0.5 * S * enginepower[key]/100 -- Accel of 0.5 m^2 * Scale * % of engine power
            end
            debugmessages["engine_" .. key] = "Engine " .. key .. " power: " .. enginepower[key] .. "%"
        end
    end

-- switch off engines not active
    for engine,on in pairs(engineson) do
        if not on then enginepower[engine] = 0 end
    end
--

-- Update engine particle systems state
    for engine,power in pairs(enginepower) do
        psystem[engine]:update(dt)
    end
-------------------------

    for k1,o1 in pairs(objects) do
        for k2,o2 in pairs(objects) do
            if k1 ~= k2 then 
                deltax = o2.x - o1.x
                deltay = o2.y - o1.y
                r = math.sqrt(deltax ^ 2 + deltay ^ 2) * S
                f = (o2.mass * o1.mass) / r^2 * G
                objects[k1].dx = objects[k1].dx + ( f * deltax / o1.mass)
                objects[k1].dy = objects[k1].dy + ( f * deltay / o1.mass)
            end
          end
          objects[k1].newx = objects[k1].x + (objects[k1].dx * dt / S)
          objects[k1].newy = objects[k1].y + (objects[k1].dy * dt / S)
      end

      for k1,o1 in pairs(objects) do
          objects[k1].x = objects[k1].newx
          objects[k1].y = objects[k1].newy
      end

      -- player
      for k,o in pairs(objects) do
          deltax = p.x - o.x
          deltay = p.y - o.y
          r = math.sqrt(deltax ^ 2 + deltay ^ 2) * S
          f = o.mass / r^2 * G
          p.dx = p.dx - ( f * deltax )
          p.dy = p.dy - ( f * deltay )
      end
      p.x = p.x + (p.dx * dt / S)
      p.y = p.y + (p.dy * dt / S)
      now = love.timer.getTime()

     -- check collisions
     for k,o in pairs(objects) do
    if o.type == "target" then
        r = o.radius + 5
    else 
        r = o.radius
    end
        
    if p.x + 3 >= o.x - r and p.x - 3 <= o.x + r and p.y +3 >= o.y -r and p.y -3 <= o.y + r then
        if o.type == "target" then
            print ("WIN!")
            level = level+1
        fuel = fuel + 100
            createSolarSystem()
          else
            print ("DIE!")
            level = 1
        fuel = 100
            createSolarSystem()
        end
    end
     end
      
end

function love.draw()
    -- stars
    for k,s in pairs(stars) do
        love.graphics.setColor(s.color[1]/255,s.color[2]/255,s.color[3]/255,math.random(150,255)/255)
        if s.size == 0 then
            love.graphics.points(s.x,s.y)
        else
            love.graphics.line(s.x-size,s.y,s.x+size,s.y)
            love.graphics.line(s.x,s.y-size,s.x,s.y+size)
        end
    end

    -- stats
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("level " ..level , maxx - 60, 20)
    love.graphics.print("fuel " ..fuel , maxx - 60, 35)
    -- debug stats
    if debug then
        local i = 1
        for k,message in pairs(debugmessages) do
            i = i + 1
            love.graphics.print(message, 10 , 15 * i)
        end
    end


    for key,object in pairs(objects) do
        love.graphics.setColor(object.color[1]/255,object.color[2]/255,object.color[3]/255)
        love.graphics.circle("fill",object.x,object.y,object.radius)
        if object.type == "star" then
            ray = math.random(1,2)
            love.graphics.line(object.x,object.y,object.x+object.radius*ray,object.y)
            love.graphics.line(object.x,object.y,object.x-object.radius*ray,object.y)
            love.graphics.line(object.x,object.y,object.x,object.y+object.radius*ray)
            love.graphics.line(object.x,object.y,object.x,object.y-object.radius*ray)
        elseif object.type == "planet" then
            love.graphics.setColor(6/255,214/255,144/255)
            love.graphics.circle("line",object.x,object.y,object.radius+1)
        elseif object.type == "target" then
	    targetx = object.x
	    targety = object.y
            love.graphics.setColor(1,0,0)
            love.graphics.circle("line",object.x,object.y,object.radius+5)
        end
    end

    -- player
    love.graphics.setColor(0, 1, 0)
    love.graphics.polygon("fill", p.x - 3, p.y -3, p.x - 3 , p.y +3, p.x + 3, p.y)

-- out of screen arrows
    drawArrow(p.x-maxx/2,p.y-maxy/2, 0, 1, 0, 0.9)
    drawArrow(targetx-maxx/2,targety-maxy/2, 1, 0, 0, 0.9)
    
-- draw particle system for each engine
   love.graphics.setColor(0, 0, 1) -- blue
    for engine,power in pairs(enginepower) do
        psystem[engine]:setEmissionRate(power)
    if power > 0 then
            love.graphics.draw(psystem[engine], p.x, p.y)
        end
    end
end

function createSolarSystem()
    nz = math.random(1,6)
    objects = {}

    -- stars
    if nz <= 4 then
        nstar = 1
    elseif nz <= 5 then
        nstar = 2
    else
        nstar = 3
    end

    for i = 1, nstar do
        mz = math.random(0,10000)
        if mz == 0 then
            mass = math.random(16,20) * M
            color = {155, 176, 255}
            radius = 7
        elseif mz < 13 then
            mass = math.random(21, 160)/10 * M
            color = {170, 191, 255}
            radius = math.random(18,66)/10
        elseif mz < 60 then
            mass = math.random(14, 21)/10 * M
            color = {213, 224, 255}
            radius = math.random(14,18)/10
        elseif mz < 300 then
            mass = math.random(104, 140)/100 * M
            color = {255, 255, 255}
            radius = math.random(115,140)/100
        elseif mz < 760 then
            mass = math.random(80, 104)/100 * M
            color = {255, 237, 227}
            radius = math.random(96,115)/100
        elseif mz < 1210 then
            mass = math.random(45, 80)/100 * M
            color = {255, 218, 181}
            radius = math.random(70,96)/100
        else
            mass = math.random(8,45)/100 * M
            color = {255, 181, 108}
            radius = math.random(3,7)/10
        end

    x = math.random(math.floor(maxx/2-100),math.floor(maxx/2+100))
    y = math.random(math.floor(maxy/2-100),math.floor(maxy/2+100))
        o = { type = 'star', mass = mass, color = color, radius = radius*5, x = x, y = y, dx = 0, dy = 0 }
        table.insert(objects,o)
    end

    -- planets
    numplanets = level
    dmax = math.floor(maxy/2)
    for i = 1,numplanets do
    distance = math.random(math.floor(dmax/numplanets*i)-10,math.floor(dmax/numplanets*i)+10)
    -- x^2 + y^2 = r^2
    if math.random(0,1) == 0 then
        x = - math.random(0,distance)
    else
        x = math.random(0,distance)
    end
    if math.random(0,1) == 0 then
        y = math.sqrt((distance^2 - x^2))
    else
        y = - math.sqrt((distance^2 - x^2))
        end
        x = x + math.floor(maxx/2)
        y = y + math.floor(maxy/2)
        o = { type = 'planet', mass = math.random(1,100)/100000000 * M, color = {140,68,29}, radius = math.random(1,30)/100*5, x = x, y = y , dx = 0, dy = 0}
        table.insert(objects,o)
    end

    -- target
    distance = math.random(math.floor(dmax)/20,math.floor(dmax))
    if math.random(0,1) == 0 then
        x = - math.random(0,distance)
    else
        x = math.random(0,distance)
    end
    if math.random(0,1) == 0 then
        y = math.sqrt((distance^2 - x^2))
    else
        y = - math.sqrt((distance^2 - x^2))
    end
    x = x + math.floor(maxx/2)
    y = y + math.floor(maxy/2)

    o = { type = 'target', mass = 1/100000000 * M, color = {255,0,0}, radius = 30/100, x = x, y = y , dx = 0, dy = 0}
    table.insert(objects,o)


    -- calculate center of gravity and center system to screen
    getCenterOfGravity()
    deltax = maxx/2 - cx
    deltay = maxy/2 - cy
    for k,object in pairs(objects) do
        objects[k].x = object.x + deltax
        objects[k].y = object.y + deltay
    end

    -- give objects initial speed
    for k,object in pairs(objects) do
        m1 = object.mass
        m2 = totalmass - m1
        deltax = (object.x - maxx/2)
        deltay = (object.y - maxy/2)
        r = math.sqrt(deltax ^ 2 + deltay ^ 2) * S
        -- TODO fix me!!! initial speed is wrong, find a better way to compute an initial speed around center of mass to start with a more stable system
        v = math.sqrt ( ( m2^2 * G ) / (m1 + m2) * r/3 )
        objects[k].dy = deltax * v / r 
        objects[k].dx = deltay * v / r
    end
    -- add player
    p = { anim = "", dx = 0, dy = 0, x = 3, y = math.floor(maxy/2)}
    enginepower = {up = 0, down = 0, right = 0, left = 0}

    -- background stars
    ns = math.random(100,1000)
    stars = {}
    for i = 0, ns do
    mz = math.random(0,10000)
        if mz == 0 then
            color = {155, 176, 255}
        size = 3
        elseif mz < 13 then
            color = {170, 191, 255}
        size = 2
        elseif mz < 60 then
            color = {213, 224, 255}
        elseif mz < 300 then
            color = {255, 255, 255}
        size = 1
        elseif mz < 760 then
            color = {255, 237, 227}
        size = 1
        elseif mz < 1210 then
            color = {255, 218, 181}
        size = 0
        else
            color = {255, 181, 108}
        size = 0
        end
    s = { x = math.random(0,maxx), y = math.random(0,maxy), color = color, size = size}
    table.insert(stars,s)
    end
end

function getCenterOfGravity()
    cx = 0
    cy = 0
    totalmass = 0
    for k,object in pairs(objects) do
        totalmass = totalmass + object.mass
    end

    for k,object in pairs(objects) do
        cx = cx + object.x * (object.mass/totalmass)
        cy = cy + object.y * (object.mass/totalmass)
    end
end

function drawArrow(px,py,r,g,b,a)
    if px > maxx/2 or px < -maxx/2 or py > maxy/2 or py < -maxy/2 then
        if px/py == maxx/maxy then
            tx = maxy/2
            ty = maxy/2
        elseif math.abs(px/py) > maxx/maxy then
            tx = maxx/2
            ty = maxx/2*py/px
        elseif math.abs(px/py) < maxx/maxy then
            tx = maxy/2*px/py
            ty = maxy/2
        end
        if ( px < 0 and tx > 0 ) or ( px > 0 and tx < 0 ) then tx = - tx end 
        if ( py < 0 and ty > 0 ) or ( py > 0 and ty < 0 ) then ty = - ty end 
        tx = tx + maxx/2
        ty = ty + maxy/2
        if tx >= maxx then
             tx = tx - 5
        else 
            tx = tx + 5
        end
        if ty >= maxy then
            ty = ty - 5
        else 
            ty = ty + 5 
        end
        local angle = math.atan2(py,px)
        love.graphics.translate(tx, ty)
        love.graphics.rotate(angle)
        love.graphics.setColor(r, g, b, a) -- use green
        love.graphics.line(0,0,10,0)
        love.graphics.rotate(-angle)
        love.graphics.translate(-tx, -ty)
    end
end


