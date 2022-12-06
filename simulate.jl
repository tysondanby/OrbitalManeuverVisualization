function gravrocket(sim)
    G = 6.67e-11
    m1 = sim.rocket.m
    F = [0.0,0.0,0.0]
    for i=1:1:length(sim.bodies)
        m2 = sim.bodies[i].m
        r =  sim.bodies[i].pos - sim.rocket.pos
        F = F + (G*m1*m2/(norm(r)^3)) * r
    end
    return F
end

function gravbody(sim,n)
    G = 6.67e-11
    m1 = sim.bodies[n].m
    F = [0.0,0.0,0.0]
    for i=1:1:(n-1)
        m2 = sim.bodies[i].m
        r =  sim.bodies[i].pos - sim.bodies[n].pos
        F = F + (G*m1*m2/(norm(r)^3)) * r
    end
    for i=(n+1):1:length(sim.bodies)
        m2 = sim.bodies[i].m
        r =  sim.bodies[i].pos - sim.bodies[n].pos
        F = F + (G*m1*m2/(norm(r)^3)) * r
    end
    return F
end

function simulate!(sim,dt)
    #Add each position property in each path property using push!
    push!(sim.rocket.path,sim.rocket.pos)
    #println(sim.rocket.pos)#Debug
    for i = 1:1:length(sim.bodies)
        push!(sim.bodies[i].path,sim.bodies[i].pos)
    end

    #Add a timestep to the ts property using push!
    push!(sim.ts,sim.t)


    #Find if a maneuver is active
    #Find Thrust for the rocket using maneuvers (if the maneuver is active, then thrust in dir)
    if sim.active == true
        maneuver = sim.maneuvers[sim.maneuver]
        T = maneuver.dir .* sim.rocket.stages[sim.rocket.stage].Tmax
        #Find and propogate deltaV change
        ddeltav = norm((T/sim.rocket.m)*dt)
        sim.maneuvers[sim.maneuver].Dv = sim.maneuvers[sim.maneuver].Dv - ddeltav
        #Stop maneuver if Dv has reached zero
        if sim.maneuvers[sim.maneuver].Dv <= 0.0
            sim.active = false
            sim.maneuver = sim.maneuver + 1
        end
    else
        T = [0.0, 0.0, 0.0]
        #start a new maneuver when the time arrives
        if sim.maneuver <= length(sim.maneuvers) #Check for new maneuver if there are any left.
            if sim.maneuvers[sim.maneuver].t0 <= dt + sim.t
                sim.active = true
                #change sim.maneuvers[sim.maneuver].dir from rocket [prograde, normal, radial] frame to general [x,y,z] frame
                refpos = [0.0,0.0,0.0]
                refv = [0.0,0.0,0.0]
                for i = 1:1:length(sim.bodies)
                    if sim.bodies[i].name == sim.maneuvers[sim.maneuver].parent
                        refpos = sim.bodies[i].pos
                        refv = sim.bodies[i].v
                    end
                end
                prograde = normalize(sim.rocket.v)
                radial = normalize(sim.rocket.pos - refpos)
                normal = normalize(cross(radial,prograde))
                #make the conversion
                sim.maneuvers[sim.maneuver].dir = sim.maneuvers[sim.maneuver].dir[1]*prograde + sim.maneuvers[sim.maneuver].dir[2]*normal + sim.maneuvers[sim.maneuver].dir[2]*radial
            
            end
        end
    end
    
    
    #propogate velocities' effects on positions & find and propogate accelerations' effect on velocities
        #rocket
    sim.rocket.pos = sim.rocket.pos + (sim.rocket.v .*dt)
    G = gravrocket(sim)
    F = T + G
    a = F./sim.rocket.m
    sim.rocket.v = sim.rocket.v + (a .*dt)
        #bodies
    for i = 1:1:length(sim.bodies)
        sim.bodies[i].pos = sim.bodies[i].pos + (sim.bodies[i].v .*dt)
        G = gravbody(sim,i)
        a = G./sim.bodies[i].m
        sim.bodies[i].v = sim.bodies[i].v + (a .*dt)
    end
    
    #Propogate thrust's effect on mass
    dm = norm(T)/(sim.rocket.stages[sim.rocket.stage].Isp * 9.81)
    sim.rocket.m = sim.rocket.m - dm
    #Check if necessary to stage
    if sim.rocket.m <= sim.rocket.stages[sim.rocket.stage].mf
        sim.rocket.stage = sim.rocket.stage + 1
        sim.rocket.m = sim.rocket.stages[sim.rocket.stage].m0
        push!(sim.rocket.tburnouts,sim.t) #Just to keep track.
    end
    #Propogate time
    sim.t = sim.t + dt
end