include("main.jl")

excelfile = "Simulation_Setup.xlsx"

#-------Start Time
hours= 0.0
minutes = 0.0
seconds = 0.0
tstart = 3600*hours+60*minutes+seconds
#-------Finish Time
hours= 0.01
minutes = 0.0
seconds = 0.0
tfinish = 3600*hours+60*minutes+seconds

framesplotted = ["Earth","Moon"]
pointsplotted = 10
dt = 1.0
scale = 3e7

#--------------------Do not modify
trange = [tstart,tfinish]
plots = runandplot(excelfile,trange,dt,framesplotted,pointsplotted,scale)

