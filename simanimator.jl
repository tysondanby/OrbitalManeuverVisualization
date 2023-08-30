using GeometryBasics, LinearAlgebra, GLMakie, FileIO, GeoMakie






function simanimator(sim,frame_name,scale,trange, save_name,animparams)
    vidlength = animparams.length#TODO
    framerate = animparams.FPS
    timesteps_per_frame = 10 #to make lines appear smooth. Not actual simulation steps, but interpolations.
    tracking = animparams.tracking
    camera_latitude = animparams.latitude 
    camera_longitude = animparams.longitude
    showgrid = false

    function position(body,t)
        upper=findfirstgreater(t,sim.ts)
        if t > sim.ts[end]
            upper = length(sim.ts)
        end
        lower = upper -1
        if lower > 0
            upperpath = body.path[upper] - path[upper]
            lowerpath = body.path[lower] - path[lower]
            #frac = (t - sim.ts[lower])/(sim.ts[upper] - sim.ts[lower])
            return (upperpath - lowerpath)*(t - sim.ts[lower])/(sim.ts[upper] - sim.ts[lower]) + lowerpath
        else
            return body.path[upper] - path[upper]
        end
    end

    function position(body,t,upper)#If upper bounding index already known
        lower = upper -1
        if lower > 0
            upperpath = body.path[upper] - path[upper]
            lowerpath = body.path[lower] - path[lower]
            #frac = (t - sim.ts[lower])/(sim.ts[upper] - sim.ts[lower])
            return (upperpath - lowerpath)*(t - sim.ts[lower])/(sim.ts[upper] - sim.ts[lower]) + lowerpath
        else
            return body.path[upper] - path[upper]
        end
    end

    #Stuff for generating seed mesh
    body_image = load("textures/"*frame_name*".png")
    r = 0.5f0
    for i = 1:1:length(sim.bodies)
        bodyname =sim.bodies[i].name
        if "$bodyname" == "$frame_name"
            r = sim.bodies[i].r
        end
    end
    
    n = 5
    θ = LinRange(0, pi, n)
    φ2 = LinRange(0, 2pi, 2 * n)
    x2 = [r*.5 * cos(φv) * sin(θv) for θv in θ, φv in φ2]
    y2 = [r*.5 * sin(φv) * sin(θv) for θv in θ, φv in φ2]
    z2 = [r*.5 * cos(θv) for θv in θ, φv in 2φ2]
    points = vec([Point3f(xv, yv, zv) for (xv, yv, zv) in zip(x2, y2, z2)])
    faces = Makie.decompose(QuadFace{GeometryBasics.GLIndex}, Tesselation(Makie.Rect(0, 0, 1, 1), (n,2*n)))
    normals = normalize.(points)

    function gen_uv(shift)
        return vec(map(CartesianIndices((n,2*n))) do ci
            #println(ci)
            tup = ((ci[1], ci[2]) .- 1) ./ (((n,2*n) .* 1.0) .- 1).*(1.0,shift)
            
            return Vec2f(reverse(tup))
        end)
    end
    uv = gen_uv(0.0)
    uvbuff = Buffer(uv)
    gbmesh = GeometryBasics.Mesh( meta(points; uv=uvbuff, normals), faces)
    uvbuff[1:end] = gen_uv(1.0)
    axis = (; type = Axis3, protrusions = (0, 0, 0, 0), aspect = :equal, limits = (-scale*r, scale*r,-scale*r, scale*r,-scale*r, scale*r),xgridvisible = showgrid,ygridvisible = showgrid,zgridvisible = showgrid,xlabelvisible = showgrid,ylabelvisible = showgrid,zlabelvisible = showgrid,xspinesvisible = showgrid,yspinesvisible = showgrid,zspinesvisible = showgrid,xticksvisible=showgrid,yticksvisible=showgrid,zticksvisible=showgrid,xticklabelsvisible = showgrid,yticklabelsvisible = showgrid,zticklabelsvisible = showgrid)
    f, ax, pl = mesh(gbmesh,  color = body_image, axis = axis, figure = (; resolution = (animparams.resolution[1],animparams.resolution[2])))

    #Find the path of the reference frame body
    path = []
    for i = 1:1:length(sim.bodies)
        bodyname =sim.bodies[i].name
        if "$bodyname" == "$frame_name"
            path = sim.bodies[i].path
        end
    end

    function findfirstgreater(val,list)
        function greater(x)
            return x > val
        end
        out = []
        if val > list[end]
            out = length(list)
        else
            out = findfirst(greater,list)#TODO: this search is incredibly slow, try something faster, perhaps bisection
        end
        
        return out
    end

    time = Observable(trange[1])
    hbound = Observable(1::Int)

    set_theme!(theme_black())

    i = 1
    n = 36
    bodypoints = []
    bodycolors = []
    θ = LinRange(0, pi, n)
    φ2 = LinRange(0, 2pi, 2 * n)
    function gen_uv(shift)
        return vec(map(CartesianIndices((n,2*n))) do ci
            #println(ci)
            tup = ((ci[1], ci[2]) .- 1) ./ (((n,2*n) .* 1.0) .- 1).*(1.0,shift)
            
            return Vec2f(reverse(tup))
        end)
    end
    for body in sim.bodies
        body_image = load("textures/"*body.name*".png")
        
        highbound = @lift(findfirstgreater($time,sim.ts[$hbound:end]) + $hbound - 1)#TODO: try sim.ts => sim.ts[$hbound:end] where hbound[] is an observable, updated in the same scope as time[] = t by hbound[] = currentupper This could help speed things up a lot.
        x = @lift(position(body,$time,$highbound)[1])#TODO: check if this 3 argument version is faster
        y = @lift(position(body,$time,$highbound)[2])
        z = @lift(position(body,$time,$highbound)[3])
        x2 = @lift([body.r * cos(φv+pi*2*($time/body.period)) * sin(θv)+$(x) for θv in θ, φv in φ2])
        y2 = @lift([body.r * sin(φv+pi*2*($time/body.period)) * sin(θv)+$(y) for θv in θ, φv in φ2])
        z2 = @lift([body.r * cos(θv+$time-$time)+$(z) for θv in θ, φv in 2φ2])
        points = @lift(vec([Point3f(xv, yv, zv) for (xv, yv, zv) in zip($(x2), $(y2), $(z2))]))
        faces = Makie.decompose(QuadFace{GeometryBasics.GLIndex}, Tesselation(Makie.Rect(0, 0, 1, 1), (n,2*n)))
        normals = @lift(normalize.($(points)))
        uv = gen_uv(0.0)
        uv_buff = Buffer(uv)
        metastuff = @lift(meta($(points); uv=uv_buff, $(normals)))
        gb_mesh = @lift(GeometryBasics.Mesh( $(metastuff), faces))
        uv_buff[1:end] = gen_uv(1.0)
        mesh!(gb_mesh,  color = body_image)

        push!(bodypoints,Observable(Point3f[]))
        push!(bodycolors,Observable(Int[]))
        lines!(bodypoints[i], color = bodycolors[i], colormap = :inferno, transparency = true)
        i = i+1
        
    end
    
    #actually the rocket, not a body
    push!(bodypoints,Observable(Point3f[]))
    push!(bodycolors,Observable(Int[]))
    lines!(bodypoints[i], color = bodycolors[i], colormap = :inferno, transparency = true)#TODO: use a different colormap for the rocket
    
    global frame = 0
    currentupper = 1
    dt = (trange[2]-trange[1])/(vidlength*framerate-1)
    record(f, save_name, LinRange(trange[1],trange[2], vidlength*framerate);framerate = framerate) do t
        time[] = t
        global frame = frame +1
        #Keep track of body traces
        for i in 1:timesteps_per_frame
            detailedtime=t+(i-timesteps_per_frame)*(dt/timesteps_per_frame)
            increment = findfirstgreater(detailedtime,sim.ts[currentupper:end]) - 1
            if  increment > 0
                currentupper = currentupper + increment
            end
            for j = 1:1:length(sim.bodies)
                # update arrays inplace
                #push!(bodypoints[j][], position(sim.bodies[j],t+(i-timesteps_per_frame)*(dt/timesteps_per_frame)))
                push!(bodypoints[j][], position(sim.bodies[j],detailedtime,currentupper))
                push!(bodycolors[j][], frame)
            end
            push!(bodypoints[end][], position(sim.rocket,detailedtime,currentupper))
            push!(bodycolors[end][], frame)
        end
        
        hbound[] = currentupper

        #Adjust camera
        tracked_angle = 0.0
        if tracking == true
            tracked_angle = pi*2*(t/86400)#TODO: not generalized, only for earth
        else
            tracked_angle = 0.0
        end
        ax.azimuth[] = camera_longitude*pi/180 + tracked_angle
        ax.elevation[] = camera_latitude*pi/180

        for i = 1:1:length(bodypoints)
            notify(bodypoints[i]); notify(bodycolors[i]) # tell points and colors that their value has been updated
        end
        
        #TODO
        #l.colorrange = (0, frame)
    end
end