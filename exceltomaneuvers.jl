function exceltomaneuvers(filename,sheetname)
    excel = XLSX.readxlsx(filename)
    maneuverxl = excel[sheetname]
    maneuvers=[]
    for row in XLSX.eachrow(maneuverxl)
        if row[2] != "Frame"
            v = [row[4],row[5],row[6]]
            Dv = norm(v)
            dir = v/Dv
            push!(maneuvers,maneuver(row[2],Dv,row[3],dir))
        end
    end
    
    return maneuvers
end