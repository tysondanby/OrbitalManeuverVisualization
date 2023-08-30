include("main.jl")

excelfile = "Simulation_Setup.xlsx"

#-------Start Time
sdays = 0.0
shours= 0.0
sminutes = 0.0
sseconds = 0.0
#-------Finish Time
fdays = 10.0
fhours= 0.0
fminutes = 0.0
fseconds = 0.0




dt = 1.0
framesplotted = ["Earth","Earth","Earth","Moon"]
scale = [100,10,5,10] #Times frame of reference radius
plotted = [false,false,false,false]
pointsplotted = 2E4#round(tfinish/40)
animated = [true,true,true,true]
tracking = [false,false,true,false]
latitude = [16.75973,16.75973,16.75973,25.0]#camera
longitude = [0.0,0.0,0.0,0.0]
vidlength = 15
FPS = 30
resolution = (4096,2160)#(1920,1080)#(4096,2160)


#--------------------Do not modify
tfinish = 3600*(24*fdays+fhours)+60*fminutes+fseconds
tstart = 3600*(24*sdays+shours)+60*sminutes+sseconds
trange = [tstart,tfinish]
animparams=[]
for i = 1:1:length(framesplotted)
    push!(animparams,AnimParams(vidlength,FPS,tracking[i],latitude[i],longitude[i],resolution))
end
plots = runandplot(excelfile,trange,dt,framesplotted,pointsplotted,scale,animparams,plotted,animated)
println("Done!")