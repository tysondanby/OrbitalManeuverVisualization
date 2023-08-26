using DifferentialEquations,Plots, LinearInterpolations

function thrustmassconstructor(sim)
    tmaneuvers = [0.0]
    maneuveron = [0.0]
    tas = [0.0]
    ta = 0.0
    for i = 1:1:length(sim.maneuvers)
        push!(tmaneuvers,sim.maneuver.t0-1E-6)
        push!(maneuveron,0.0)
        push!(tas,0.0)
        push!(tmaneuvers,sim.maneuver.t0+1E-6)
        push!(maneuveron,1.0)
        push!(tas,0.0)
        push!(tmaneuvers,sim.maneuver.t0+deltat-1E-6)
        push!(maneuveron,1.0)
        push!(tmaneuvers,sim.maneuver.t0+deltat+1E-6)
        push!(maneuveron,0.0)
        ta = ta + deltat
    end


    function thrustaccel(t)
        if interpolate(ts,maneuveron,t) >=0.5
            timeactive = interpolate(ts,tas,t)
            T = interpolate(sim.rocket.tas,sim.rocket.thrustaccels,timeactive)
        else
            T = 0
        end
    end
    return thrust
end

#only need be rerun if rocket params changed
function simburn!(sim)#time active
    Taccel = 1E-6
    dt = 1E-6
    while T > 0.0
        Taccel = sim.rocket.stages[sim.rocket.stage].Tmax/sim.rocket.m
        ddeltav = (T/sim.rocket.m)*dt
        sim.maneuvers[sim.maneuver].Dv = sim.maneuvers[sim.maneuver].Dv - ddeltav
        push!(sim.rocket.thrustaccels,Taccel)
        push!(sim.rocket.deltavs,deltav)
        push!(sim.rocket.tas,ta)
        if sim.maneuvers[sim.maneuver].Dv <= 0.0
            sim.maneuver = sim.maneuver + 1
        end
    end
end
#=
function thrust(t)
    if t >10.0
        T = 1.0*cos((t-10)*pi/2.5)
    else
        T = 0.0
    end
    return T
end

function particle!(dx,x,p,t)
    dx[1] = x[2]
    dx[2] =thrust(t)
end

function analyticpos(t)
    if t<10.0
        pos = 0.0
    else
        pos = -.633257*cos(1.25664*t-12.5664)+.633257
    end
    return pos
end
prob  = ODEProblem(particle!,[0.0;0.0],(0.0,20.0))

sol = solve(prob)

pos = []
vel =[]
for i = 1:1:length(sol.t)
    push!(pos,sol.u[i][1])
    push!(vel,sol.u[i][2])
end
t = collect(0.0:0.1:20.0)
realpos = zeros(length(t))
realpos = @. analyticpos(t)
plot(sol.t,pos)
plot!(t,realpos)
=#