using PlotlyJS
#make trange select the right values
function simtoindexrange(sim,tframe)
    indexrange = [0,0]
    for i in 1:1:length(sim.ts)
        if sim.ts[i] >= tframe[1]
            indexrange[1] = deepcopy(i)
            break#i = length(sim.ts) +1
        end
    end
    for i = 1:1:length(sim.ts)
        if sim.ts[i] <= tframe[2]
            indexrange[2] = deepcopy(i)
        end
    end
    return indexrange
end

function simtrim!(sim,tframe)
    indexrange = simtoindexrange(sim,tframe)
    for i = 1:1:length(sim.bodies)
        sim.bodies[i].path = sim.bodies[i].path[indexrange[1]:indexrange[2]]
    end
    sim.rocket.path = sim.rocket.path[indexrange[1]:indexrange[2]]
end

function frametrajectory(sim,frame)#basically returns body.path for body in sim with name frame.
    path = []
    for i = 1:1:length(sim.bodies)
        bodyname =sim.bodies[i].name
        #println("is $bodyname"*" == $frame"*"?")#DEBUG
        if "$bodyname" == "$frame"
            path = sim.bodies[i].path
            #println(path)#DEBUG
        end
    end
    return path
end

function frameradius(sim,frame)#basically returns body.r for body in sim with name frame.
    R = []
    for i = 1:1:length(sim.bodies)
        bodyname =sim.bodies[i].name
        #println("is $bodyname"*" == $frame"*"?")#DEBUG
        if "$bodyname" == "$frame"
            R = sim.bodies[i].r
            #println(path)#DEBUG
        end
    end
    return R
end

function simtobodytraces(sim,frame,color,n)
    frametraj = frametrajectory(sim,frame)
    traces = [] 
    for planet in sim.bodies
        traj = planet.path - frametraj
        x = []
        y = []
        z = []
        for i = 1:n:length(traj)
            xi,yi,zi = traj[i]
            push!(x,xi)
            push!(y,yi)
            push!(z,zi)
        end
        trace = scatter(x=x,y=y,z=z,line=attr(color=color, width=2),type="scatter3d",mode="lines")
        push!(traces,trace)
    end
    return traces
end

function simtobodyspheres(sim,frame)
    frametraj = frametrajectory(sim,frame)
    framepos = frametraj[end]
    traces = [] 
    for planet in sim.bodies
        center=planet.pos - framepos
        r = planet.r
        dom = range(0, stop=2π, length=20)
        u = dom' .* ones(20)
        v = ones(20)' .* dom
        x = @. r*cos(v)*cos(u) + center[1]
        y = @. r*cos(v)*sin(u) + center[2]
        z = @. r*sin(v) + center[3]
        sphere = surface(x=x, y=y, z=z)
        push!(traces,sphere)
    end
    return traces
end

function simtorockettrace(sim,frame,color1,color2,n)
    traces = []
    frametraj = frametrajectory(sim,frame)
    traj = sim.rocket.path - frametraj
    x = []
    y = []
    z = []
    t = []
    for i = 1:n:length(traj)
        xi,yi,zi = traj[i]
        ti = sim.ts[i]
        push!(x,xi)
        push!(y,yi)
        push!(z,zi)
        push!(t,ti)
    end
    pathtrace = scatter(x=x,y=y,z=z,line=attr(color=color1, width=2),type="scatter3d",mode="lines")
    push!(traces,pathtrace)

    if length(sim.rocket.tburnouts) != 0
        stagingindicies = []#not currently used
        xs = []
        ys = []
        zs = []
        for i = 1:1:length(sim.rocket.tburnouts)
            tstage=sim.rocket.tburnouts[i]
            for index = 1:1:length(t)
                if t[index] >= tstage
                    index2 = deepcopy(index)
                    push!(xs,x[index2])
                    push!(ys,y[index2])
                    push!(zs,z[index2])
                    break#index = length(sim.ts) +1 #get out of for loop
                end
            end
        end
        stagetrace = scatter(x=xs,y=ys,z=zs,line=attr(color=color1, width=2),type="scatter3d",mode="markers")
        push!(traces,stagetrace)
    end
    
    if length(sim.maneuvers) != 0
        xm = []
        ym = []
        zm = []
        for maneuver = 1:1:length(sim.maneuvers)
            tm = sim.maneuvers[maneuver].t0
            for index = 1:1:length(t)
                if t[index] >= tm
                    index2 = deepcopy(index)
                    push!(xm,x[index2])
                    push!(ym,y[index2])
                    push!(zm,z[index2])
                    break #get out of for loop
                end
            end
        end
        maneuvertrace =  scatter(x=xm,y=ym,z=zm,line=attr(color=color2, width=2),type="scatter3d",mode="markers")
        push!(traces,maneuvertrace)
    end
    return traces
end


function simplotter(sim,frame,n,trange,scale)#Frame is a string name of the body n is the number of timesteps per plot point.
    simcopy = deepcopy(sim)
    simtrim!(simcopy,trange)
    btraces1 =simtobodytraces(simcopy,frame,"darkblue",n)#build body path traces (Line plots)
    btraces2 =simtobodyspheres(simcopy,frame)#,"darkblue")#build body final position traces (3D meshes)
    rtrace = simtorockettrace(simcopy,frame,"darkblue","red",n)#Build rocket path trace (Line plot)
    traces = append!(btraces1,btraces2,rtrace)

    maxdist = scale*frameradius(sim,frame)
    layout = Layout(
    width=800,
    height=800,
    autosize=false,
    scene=attr(
        camera=attr(
            up=attr(x=0, y=0, z=1),
            eye=attr(x=0, y=1.0707, z=1)
        ),
        aspectratio=attr(x=1.0, y=1.0, z=1.0),
        aspectmode="manual",
        xaxis = attr(
            nticks = 10,
            range  =[-maxdist,maxdist]
        ),
        yaxis = attr(
            nticks = 10,
            range  =[-maxdist,maxdist]
        ),
        zaxis = attr(
            nticks = 10,
            range  =[-maxdist,maxdist]
        ),
    ),
    plot_bgcolor="rgb(0, 0, 0)"
    )
    #println(typeof(traces[1]))
    p = plot(traces[1],layout)
    for i = 2:1:length(traces)
        add_trace!(p,traces[i])
    end
    return p #returns a PlotlyJS 3D plot
end