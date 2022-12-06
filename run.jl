include("main.jl")

excelfile = "Simulation_Setup.xlsx"

#-------Start Time
days = 0.0
hours= 0.0
minutes = 0.0
seconds = 0.0
tstart = 3600*(24*days+hours)+60*minutes+seconds
#-------Finish Time
days = 10.0
hours= 0.0
minutes = 0.0
seconds = 0.0
tfinish = 3600*(24*days+hours)+60*minutes+seconds

framesplotted = ["Earth","Moon"]
pointsplotted = 1000
dt = 1.0
scale = [100,5] #Times frame of reference radius

#--------------------Do not modify
trange = [tstart,tfinish]
plots = runandplot(excelfile,trange,dt,framesplotted,pointsplotted,scale)

