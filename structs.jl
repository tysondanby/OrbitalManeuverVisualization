#

mutable struct body#{T1,T2,T3}
    m#::T1
    pos#::T2
    v#::T2
    path#::T3 
    r
    name
    period
    body(m,pos,v,r,name,period)= new(m,pos,v,[],r,name,period)
end

mutable struct rocket#{T1,T2,T3,T4,T5}
    m#::T1
    stage#::T2
    stages#::T3
    pos#::T4
    v#::T4
    path#::T5
    tburnouts#::T1
    tas
    thrustaccels
    deltavs
    rocket(m,stages,pos,v)= new(m,1,stages,pos,v,[],[],[],[],[])
end

struct stage#{T1}
    Isp#::T1
    Tmax#::T1
    m0#::T1
    mf#::T1
end

mutable struct maneuver#{T1,T2}
    parent
    Dv#::T1 #Delta v is initially set to something, then is depleted to zero
    t0#::T1
    dir#::T2
end

mutable struct simulation#{T1,T2,T3,T4,T5,T6,T7}
    bodies#::T1
    rocket#::T2
    maneuvers#::T3
    t#::T4 #current sim time
    maneuver#::T5 #which maneuver is next/active
    active#::T6 #whether a maneuver is active
    ts#::T7 #vector of past sim timesteps
    simulation(bodies,rocket,maneuvers,t) = new(bodies,rocket,maneuvers,t,1,false,[])
end

mutable struct orbit#{T1,T2,T3}
    pos#::T1
    v#::T1
    name#::T3
    parent#::T3
    m1#::T2
    m2#::T2
    Ap#::T2
    Pe#::T2
    inc#::T2
    LPe#::T2
    Lan#::T2
    th0#::T2
    frame
    r
end

struct AnimParams
    length
    FPS
    tracking
    latitude
    longitude
    resolution
end