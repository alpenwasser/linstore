#!/usr/bin/env python3

import pprint as pp
import json as js
#import sympy as sp
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd

# ---------------------------------------------------------------------------- #
# LOAD JSON AND GENERATE RANKING                                               #
# ---------------------------------------------------------------------------- #
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


# ---------------------------------------------------------------------------- #
# GENERATE HTML                                                                #
# ---------------------------------------------------------------------------- #

# ---------------------------------------------------------------------------- #
# GENERATE PLOT                                                                #
# ---------------------------------------------------------------------------- #
#plot_data = js.loads('{}')
#plot_data_usernames = np.array()
plot_data_ranks = np.array([])
plot_data_ranking_points = np.array([])
#pp.pprint(ranking_db)
plot_data_usernames = []
for rank in ranking_db.keys():
    if ranking_db[rank]['drive_count'] < 5 or ranking_db[rank]['capacity'] < 10:
        continue
    plot_data_usernames.append(ranking_db[rank]['username'] + ' ' + str(rank))
    plot_data_ranks = np.append(plot_data_ranks,[rank])
    plot_data_ranking_points = np.append(plot_data_ranking_points, [ranking_db[rank]['ranking_points']])
    #plot_data[ranked_system] = js.loads('{}')
    #plot_data[ranked_system]['username'] = ranking_db[ranked_system]['username']
    #plot_data[ranked_system]['ranking_points'] = ranking_db[ranked_system]['ranking_points']

#pp.pprint(plot_data_ranks)

#fig = plt.figure(1)
#axes = fig.add_subplot(111)
#axes.scatter(plot_data_ranks,plot_data_ranking_points)
#axes.set_yscale('log',nonposy='clip')
#axes.set_ylim(ymin=20)
#axes.set_xlim(xmin=-10)
#fig.savefig('test.pdf')
#pp.pprint(plot_data)
#print(js.dumps(ranking_db,sort_keys=True))

sns.set(color_codes=True)
#sns.set_palette(sns.color_palette("coolwarm", 7))
#sns.set_palette("Reds")
#df = pd.DataFrame()
#df['x'] = plot_data_ranks
#df['y'] = plot_data_ranking_points

#sns.jointplot(x='x', y='y', data=df)
#grid = sns.JointGrid(plot_data_ranks,plot_data_ranking_points,space=0,size=6,ratio=50)
#grid = sns.JointGrid(plot_data_ranks,plot_data_ranking_points,space=10,size=6)
#grid = sns.jointplot(x=df['x'],y=df['y'])
#grid = sns.JointGrid(plot_data_ranks,plot_data_ranking_points,space=.1)
#grid.plot_joint(plt.scatter,color='#db4105',s=50)
#grid.plot_marginals(sns.distplot, kde=False, color=".5")
#axes = grid.ax_joint
#axes.set_yscale('log',nonposy='clip')
#axes.set_ylim(ymin=20)
#axes.set_xlim(xmin=-10,xmax=130)
#plt.show()
#plt.savefig('test.png')

# Simple scatter plot
#df = pd.DataFrame()
#df['Rank'] = plot_data_ranks
#df['Ranking Points'] = plot_data_ranking_points
#grid = sns.FacetGrid(df)
#grid.map(plt.scatter,'Rank','Ranking Points')
#axes = grid.ax
#axes.set_yscale('log')
#axes.set_ylim(ymin=20)
#axes.set_xlim(xmin=-10,xmax=130)
#plt.show()

#df = pd.DataFrame()
#df['username'] = plot_data_usernames
#df['Ranking Points'] = plot_data_ranking_points
#grid = sns.FacetGrid(df)
#grid.map(sns.barplot,'Ranking Points','username',palette='Blues_d')
#axes = grid.ax
#axes.set_yscale('log')
#axes.set_ylim(ymin=20)
#axes.set_xlim(xmin=-10,xmax=130)
#plt.show()

#df = pd.DataFrame()
##df['Rank'] = plot_data_ranks
#df['Rank'] = plot_data_usernames
#df['Ranking Points'] = plot_data_ranking_points
#grid = sns.FacetGrid(df)
##grid.map(plt.scatter,'Rank','Ranking Points')
#grid.map(sns.swarmplot,'Ranking Points','Rank')
#grid.set_xticklabels(rotation=90)
#axes = grid.ax
#axes.set_xscale('log')
#plt.show()

df = pd.DataFrame()
#df['Rank'] = plot_data_ranks
df['Rank'] = plot_data_usernames
df['Ranking Points'] = plot_data_ranking_points
grid = sns.FacetGrid(df)
#grid.map(plt.scatter,'Rank','Ranking Points')
grid.map(sns.barplot,'Ranking Points','Rank',palette='Blues_r')
grid.set_xticklabels(rotation=90)
axes = grid.ax
axes.set_xscale('log')
plt.show()
