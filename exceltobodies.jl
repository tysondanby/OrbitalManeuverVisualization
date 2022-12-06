using XLSX, LinearAlgebra

function calcinit!(orb)#Finds initial v and pos for an orbit
    if orb.Ap != 0.0 || orb.Pe !=0.0
        a = (orb.Ap +orb.Pe)/2 #semimajor
        mu = 6.67e-11 * orb.m2
        th = orb.th0
    
        SPe = sqrt(mu*(2/orb.Pe - (1/a)))#Speed at periapsis
        UPe = -6.67e-11 * orb.m1*orb.m2/orb.Pe
        TPe = .5*orb.m1*SPe^2
        #eps = -mu/(2*a)
        thdotPe = SPe / orb.Pe
        h = orb.Pe^2*thdotPe
        ecc = sqrt(1 + 2*((h/mu)^2)*((TPe+UPe)/orb.m1))
        a1 = cosd(th)^2 + sind(th)^2/(1-ecc^2)
        b1 = 2*cosd(th)*(a-orb.Pe)
        c1 = (a-orb.Pe)^2 - a^2
        r = (-b1 + sqrt(b1^2 - 4*a1*c1))/(2*a1)

        x = r*cosd(th)
        y = r*sind(th)
        orb.pos = [ x, y, 0.0]

        dxdy = -1*sign(x)*y/( (1-ecc^2)*sqrt(a^2-(y^2/(1-ecc^2))) )
        dir = normalize([dxdy,1.0,0.0])
        V = sqrt(mu*(2/r - (1/a)))
        orb.v = V*dir
    end
end

function orbittoparentframe!(orbit1)
    #Go from orbit frame to parent frame
    
    if orbit1.parent != "Origin"
        #POSITION
        xorb = orbit1.pos[1]
        yorb = orbit1.pos[2]
        zorb = orbit1.pos[3]
        z = sind(orbit1.inc)*sind(orbit1.th0 - orbit1.Lan)*sqrt(xorb^2+yorb^2)
        x = (xorb*cosd(orbit1.LPe) - yorb*sind(orbit1.LPe))*cos(asin(z/sqrt(xorb^2+yorb^2)))
        y = (xorb*sind(orbit1.LPe) + yorb*cosd(orbit1.LPe))*cos(asin(z/sqrt(xorb^2+yorb^2)))
        orbit1.pos = [x,y,z]

        #velocity
        xorb = orbit1.v[1]
        yorb = orbit1.v[2]
        zorb = orbit1.v[3]
        z = sind(orbit1.inc)*sind(orbit1.th0 - orbit1.Lan)*sqrt(xorb^2+yorb^2)
        x = (xorb*cosd(orbit1.LPe) - yorb*sind(orbit1.LPe))*cos(asin(z/sqrt(xorb^2+yorb^2)))
        y = (xorb*sind(orbit1.LPe) + yorb*cosd(orbit1.LPe))*cos(asin(z/sqrt(xorb^2+yorb^2)))
        orbit1.v = [x,y,z]
    end
    orbit1.frame = "parent"
end

function parenttoglobalframe!(orbits,n)#n is the index of the orbit to be placed in general frame
    #Go from parent frame to global frame
    parent = orbits[n].parent
    if (parent != "Origin") #& (orbits[n].frame != "global")
        parentindex = 1
        for i = 1:1:length(orbits)
            if parent == orbits[i].name
                parentindex = i
            end
        end
        orbittoglobalframe!(orbits,parentindex)
        orbits[n].pos = orbits[n].pos +orbits[parentindex].pos
        orbits[n].v = orbits[n].v +orbits[parentindex].v
    end
    orbits[n].frame = "global"
end

function orbittoglobalframe!(orbits,n)
    if orbits[n].frame == "orbit"
        orbittoparentframe!(orbits[n])
    end
    if orbits[n].frame == "parent"
        parenttoglobalframe!(orbits,n)
    end
end

function exceltobodies(filename,sheetname)
    excel = XLSX.readxlsx(filename)
    #Read bodies into orbits from excel
        bodiesxl = excel[sheetname]
        orbits = []
        for row in XLSX.eachrow(bodiesxl)
            if row[1] != "name"
                pos = [0.0,0.0,0.0]
                v = [0.0,0.0,0.0]
                name = row[1]
                m1 = row[2]
                r = row[3]
                m2 = 0.0
                parent = row[4]
                Ap =row[5]
                Pe =row[6]
                inc = row[7]
                LPe = row[8]
                Lan = row[9]
                th0 = row[10]
                frame = "orbit"
                neworbit = orbit(pos,v,name,parent,m1,m2,Ap,Pe,inc,LPe,Lan,th0,frame,r)
                push!(orbits,neworbit)
            end
        end
    #Fill in missing orbital info and bump pe and ap
        norbits = length(orbits)
        for i = 1:1:norbits
        #Fill in m2 property
            for j = 1:1:norbits
                if orbits[i].parent == orbits[j].name
                    orbits[i].m2 = orbits[j].m1
                    orbits[i].Ap = orbits[i].Ap + orbits[j].r
                    orbits[i].Pe = orbits[i].Pe + orbits[j].r
                end
            end
        #calculate initial positions and velocities
            calcinit!(orbits[i])
        end
    
    
    #construct vector of bodies
        bodies = []
        for i = 1:1:length(orbits)
            #rotate velocity and rotate+translate position into general frame #CHECK
            orbittoglobalframe!(orbits,i)
            newbody = body(orbits[i].m1,orbits[i].pos,orbits[i].v,orbits[i].r,orbits[i].name)
            push!(bodies,newbody)
        end
    return bodies, orbits
end