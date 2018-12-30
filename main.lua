function love.load()
    math.randomseed(os.time())
    --G = 6.67 × 10^−11 N m² / kg²
    G = 6.67 * 0.0000000000001
    M = 1.9885 * 10^30  -- sun mass (oter mass are expressed in sun masses
    S = 200000 -- scale
    level = 1
    love.window.setFullscreen(true,"desktop")
    maxx = love.graphics.getWidth()
    maxy = love.graphics.getHeight()
    createSolarSystem()
    local img = love.graphics.newImage('particle.png')
    start = 0
    psystem = love.graphics.newParticleSystem(img, 32)
    psystem:setParticleLifetime(0.1, 1) -- Particles live at least 2s and at most 5s.
    psystem:setEmissionRate(0)
    psystem:setSizeVariation(0.5)
    psystem:setLinearAcceleration(0, -20, 20, 20) -- Random movement in all directions.
    psystem:setColors(255, 255, 255, 255, 255, 255, 255, 0) -- Fade to transparency.
end

function love.keypressed(key)
   if key == "escape" then
      love.event.quit()
   end

   --reset level
   if key == "space" then
      createSolarSystem()
   end

   if key == "up" then
       p.dy = p.dy - 10 * S
       p.anim = "up"
       start = love.timer.getTime()
   end
   if key == "down" then
       p.dy = p.dy + 10 * S
       p.anim = "down"
       start = love.timer.getTime()
   end
   if key == "right" then
       p.dx = p.dx + 10 * S
       p.anim = "right"
       start = love.timer.getTime()
   end
   if key == "left" then
       p.dx = p.dx - 10 * S
       p.anim = "left"
       start = love.timer.getTime()
   end
end


function love.update(dt)
    psystem:update(dt)
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
      if now > start + 1 then
    p.anim = ""
        psystem:setEmissionRate(0)
      end

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
                createSolarSystem()
          else
            print ("DIE!")
        level = 1
                createSolarSystem()
        end
    end
     end
      
end

function love.draw()
    -- stats
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("level " ..level , maxx - 50, 20)

    for key,object in pairs(objects) do
        love.graphics.setColor(object.color[1]/255,object.color[2]/255,object.color[3]/255)
        love.graphics.circle("fill",object.x,object.y,object.radius*5)
        if object.type == "star" then
        ray = math.random(5,10)
            love.graphics.line(object.x,object.y,object.x+object.radius*ray,object.y)
            love.graphics.line(object.x,object.y,object.x-object.radius*ray,object.y)
            love.graphics.line(object.x,object.y,object.x,object.y+object.radius*ray)
            love.graphics.line(object.x,object.y,object.x,object.y-object.radius*ray)
    elseif object.type == "planet" then
        love.graphics.setColor(6/255,214/255,144/255)
        love.graphics.circle("line",object.x,object.y,object.radius+1)
    elseif object.type == "target" then
        love.graphics.setColor(1,0,0)
        love.graphics.circle("line",object.x,object.y,object.radius+5)
        end
    end

    -- player
    love.graphics.setColor(1, 0, 0)
    love.graphics.polygon("fill", p.x - 3, p.y -3, p.x - 3 , p.y +3, p.x + 3, p.y)
    love.graphics.setColor(0, 0, 1)
    if p.anim == "up" then
        psystem:setLinearAcceleration(-5, 100, 5, 150)
        psystem:setEmissionRate(100)
    elseif p.anim == "down" then
        psystem:setLinearAcceleration(-5, -100, 5, -150)
        psystem:setEmissionRate(100)
    elseif p.anim == "left" then
        psystem:setLinearAcceleration(100, -5, 150, 5)
        psystem:setEmissionRate(100)
    elseif p.anim == "right" then
        psystem:setLinearAcceleration(-100, -5, -150, 5)
        psystem:setEmissionRate(100)
    end
    love.graphics.draw(psystem, p.x, p.y)
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
        o = { type = 'star', mass = mass, color = color, radius = radius, x = x, y = y, dx = 0, dy = 0 }
        table.insert(objects,o)
    end

    -- planets
    numplanets = math.random(1,level)
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
        v = math.sqrt ( ( m2^2 * G ) / (m1 + m2) * r )
        objects[k].dy = deltax * v / r 
        objects[k].dx = deltay * v / r
    end
    -- add player
    p = { anim = "", dx = 0, dy = 0, x = 3, y = math.floor(maxy/2)}

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




