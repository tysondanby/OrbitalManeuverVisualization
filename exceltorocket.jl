function exceltorocket(filename,sheetname,orbits)
    excel = XLSX.readxlsx(filename)
    rocketxl = excel[sheetname]
    rows =[]
    for row in XLSX.eachrow(rocketxl)
        push!(rows,row)
    end
    orow=rows[3]

    pos = [0.0,0.0,0.0]
    v = [0.0,0.0,0.0]
    name = "rocket"
    m1 = 1.0#dummy
    m2 = 0.0
    parent = orow[1]
    Ap =orow[2]
    Pe =orow[3]
    inc = orow[4]
    LPe = orow[5]
    Lan = orow[6]
    th0 = orow[7]
    frame = "orbit"
    r = 1.0 #dummy
    rocketorbit = orbit(pos,v,name,parent,m1,m2,Ap,Pe,inc,LPe,Lan,th0,frame,r)
    for j = 1:1:length(orbits)
        if rocketorbit.parent == orbits[j].name
            rocketorbit.m2 = orbits[j].m1
            rocketorbit.Ap = rocketorbit.Ap + orbits[j].r
            rocketorbit.Pe = rocketorbit.Pe + orbits[j].r
        end
    end
    #calculate initial positions and velocities
    calcinit!(rocketorbit)
    push!(orbits,rocketorbit)
    orbittoglobalframe!(orbits,length(orbits))#calculates pos and v for rocket in general frame.

    stages = []
    for rowi = 7:1:length(rows)
        srow=rows[rowi]
        push!(stages,stage(srow[2],srow[3],srow[4],srow[5]))
    end
    m = stages[1].m0
    return rocket(m,stages,orbits[end].pos,orbits[end].v)
end