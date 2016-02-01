#!/usr/bin/env python3

import pprint as pp
import json as js
#import sympy as sp
import matplotlib.pyplot as plt

systems_file='json/systems.json'
system_data=open(systems_file)
system_db = js.load(system_data)
system_data.close()
#print(system_db['system_001']['capacity'])
#pp.pprint(system_db)

drives_file='json/drive_types.json'
drive_data=open(drives_file)
drive_db = js.load(drive_data)
drive_data.close()
#pp.pprint(drive_db)


# Iterate over all systems:
for system in system_db.keys():
    system_db[system]['capacity'] = 0
    system_db[system]['drive_count'] = 0
    for drive_type in system_db[system]['drives'].keys():
        #print(drive_type + ': ' + system_db[system]['drives'][drive_type])

        # System ranking points: Total capacity * number of drives
        if drive_type in drive_db:
            system_db[system]['capacity'] += int(float(system_db[system]['drives'][drive_type]) * float(drive_db[drive_type]['size']))
            system_db[system]['drive_count'] += int(system_db[system]['drives'][drive_type])
            #system_db[system]['ranking_points'] = drive_type

        system_db[system]['ranking_points'] = system_db[system]['capacity'] * system_db[system]['drive_count']


ranked_systems = sorted(system_db, key=lambda system: system_db[system]['ranking_points'], reverse=True)

# Create empty json object
ranking_file='json/ranking.json'
ranking_db = js.loads('{}')
rank = 0
for ranked_system in ranked_systems:
    rank += 1
    ranking_db[rank] = system_db[ranked_system]
    #del ranking_db[ranked_system]

ranking_data=open(ranking_file, 'w')
js.dump(ranking_db,ranking_data,indent=1,sort_keys=True)
ranking_data.close()




