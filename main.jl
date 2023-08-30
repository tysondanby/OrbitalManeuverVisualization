include("buildsim.jl")
include("simulate.jl")
include("simplotter.jl")
include("simanimator.jl")

function runandplot(excelfile,trange,dt,frames,nplot,scales, animparams, plotted, animated)
    #SIMULATE
    nframes = length(frames)
    ps = []
    sim = buildsim(excelfile)
    t = trange[1]
    while t < trange[2]
        simulate!(sim,dt)
        percentsimulated = round(((t - trange[1])/(trange[2] - trange[1]))*1000)/10
        t = t+dt
        println("Simulating: $percentsimulated"*"% complete. t = $t")
    end
    #MAKE PLOTS
    n = round(Int64,length(sim.rocket.path)/nplot) #Number of sim points per plot point
    for i = 1:1:nframes
        if plotted[i] == true
            println("Making Plot $i"*"/$nframes . . . . .")
            push!(ps,simplotter(sim,frames[i],n,trange,scales[i]))
        else
            println("Skipping Plot $i"*"/$nframes . . . . .")
        end
        println("Done $i"*"/$nframes")
    end
    #MAKE ANIMATIONS
    for i = 1:1:nframes
        if animated[i] == true
            println("Generating Animation $i"*"/$nframes . . . . .")
            simanimator(sim,frames[i],scales[i],trange,"Animations/$i"*"_"*frames[i]*"_frame_animation.mp4",animparams[i])
        else
            println("Skipping Animation $i"*"/$nframes . . . . .")
        end
        println("Done $i"*"/$nframes")
    end
    return ps
end