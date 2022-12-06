include("structs.jl")
include("exceltobodies.jl")
include("exceltorocket.jl")
include("exceltomaneuvers.jl")
#include("simulate.jl")



function buildsim(xlsxfilename)
    bodies, orbits = exceltobodies(xlsxfilename,"Bodies")

#construct rocket from excel 
    rocket = exceltorocket(xlsxfilename,"Rocket",orbits)

#construct maneuvers from excel
    maneuvers = exceltomaneuvers(xlsxfilename,"Maneuvers")

#build the whole sim object
    return simulation(bodies,rocket,maneuvers,0.0)
end
