include("buildsim.jl")
include("simulate.jl")
include("simplotter.jl")

function runandplot(excelfile,trange,dt,frames,nplot,maxdist)
    ps = []
    sim = buildsim(excelfile)
    t = trange[1]
    while t < trange[2]
        simulate!(sim,dt)
        percentsimulated = round(((t - trange[1])/(trange[2] - trange[1]))*1000)/10
        t = t+dt
        println("Simulating: $percentsimulated"*"% complete. t = $t")
    end
    n = round(Int64,length(sim.rocket.path)/nplot) #Number of sim points per plot point
    for i = 1:1:length(frames)
        push!(ps,simplotter(sim,frames[i],n,trange,maxdist))
    end
    return ps
end