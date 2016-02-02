#!/usr/bin/env python3

import pprint as pp
import json as js
#import sympy as sp
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import re as re

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

        system_db[system]['ranking_points'] = system_db[system]['capacity'] * np.log(system_db[system]['drive_count'])


ranked_systems = sorted(system_db, key=lambda system: system_db[system]['ranking_points'], reverse=True)

# Create empty json object
ranking_file='json/ranking.json'
notew_file='json/notew.json'
ranking_db = js.loads('{}')
notew_db = js.loads('{}')
rank = 0
for ranked_system in ranked_systems:
    if (system_db[ranked_system]['drive_count'] < 5
        or system_db[ranked_system]['capacity'] < 10
        or system_db[ranked_system]['ditch'] == 1):
        # TODO: add to noteworthy
        notew_db[ranked_system] = system_db[ranked_system]
        continue
    rank += 1
    ranking_db[rank] = system_db[ranked_system]
    #del ranking_db[ranked_system]

ranking_data=open(ranking_file, 'w')
js.dump(ranking_db,ranking_data,indent=1,sort_keys=True)
ranking_data.close()

notew_data=open(notew_file, 'w')
js.dump(notew_db,notew_data,indent=1,sort_keys=True)
notew_data.close()


# ---------------------------------------------------------------------------- #
# GENERATE HTML                                                                #
# ---------------------------------------------------------------------------- #

html_template_file = 'template.html'
html_template = open(html_template_file, 'r')
template_header=''
template_row = ''
template_footer=''
opening_tag=re.compile('%%%<template_row>%%%')
closing_tag=re.compile(r'%%%</template_row>%%%')
result=''
tag_open = False # indicates whether tag is currently open
tag_has_been_opened = False # indicates whether tag has ever been opened: used for footer/header

# First, grab header, footer and the template row which will be used to assemble
# the system entries.
for html_tpl_str in html_template:
    if not tag_open:
        #print('closed')
        if opening_tag.search(html_tpl_str):
            tag_open = True
            tag_has_been_opened = True
            #print('opening')
            continue
        elif closing_tag.search(html_tpl_str):
            tag_open = False
            #print('closing')
            continue

        if not tag_has_been_opened:
            template_header += html_tpl_str
        else:
            template_footer += html_tpl_str
    else:
        #print('open')
        if tag_has_been_opened:
            if closing_tag.search(html_tpl_str):
                tag_open = False
                #print('closing')
                continue

        template_row += html_tpl_str


# Generate rows:
# Regex search and replace patterns
rank_sub = '%r%'
username_sub = '%u%'
rankingpoints_sub = '%rp%'
capacity_sub = '%cap%'
nodrives_sub = '%ndr%'
case_sub = '%cs%'

# Assemble ranking table
rows = ''
for rank in ranking_db.keys():
    row = re.sub(rank_sub,str(rank),template_row)
    row = re.sub(username_sub,ranking_db[rank]['username'],row)
    row = re.sub(rankingpoints_sub,"{:.2f}".format(ranking_db[rank]['ranking_points']),row)
    row = re.sub(capacity_sub,str(ranking_db[rank]['capacity']),row)
    row = re.sub(nodrives_sub,str(ranking_db[rank]['drive_count']),row)
    row = re.sub(case_sub,str(ranking_db[rank]['case']),row)
    rows += row

html_file = open('rankings.html','w')
html_file.write(template_header)
html_file.write(rows)
html_file.write(template_footer)
html_file.close()


# ---------------------------------------------------------------------------- #
# GENERATE PLOTS                                                               #
# ---------------------------------------------------------------------------- #
#plot_data = js.loads('{}')
#plot_data_usernames = np.array()
plot_data_ranks = np.array([])
plot_data_ranking_points = np.array([])
#pp.pprint(ranking_db)
plot_data_usernames = []
for rank in ranking_db.keys():
    plot_data_usernames.append(ranking_db[rank]['username'] + ' ' + str(rank))
    #plot_data_usernames.append('username ' + str(rank))
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

#sns.set(color_codes=True)
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

#sns.set(color_codes=True,font_scale=0.5)
#df = pd.DataFrame()
#df['Rank'] = plot_data_ranks
#df['Rank'] = plot_data_usernames
#df['Ranking Points'] = plot_data_ranking_points
#grid = sns.FacetGrid(df)
#grid.map(plt.scatter,'Rank','Ranking Points')
#grid.map(sns.barplot,'Ranking Points','Rank',palette='Blues_r')
#grid.set_xticklabels(rotation=90)
#axes = grid.ax
#axes.set_xscale('log')
#plt.show()
#plt.savefig('test.png')


#plt.rc('text', usetex=True)
font = {
        'family' : 'serif',
        'color' : 'black',
        'weight' : 'normal',
        'size' : '10',
        }
plt.rc('figure',figsize=(16,40))
plt.rc('font',family='sans-serif')
df = pd.DataFrame()
df['Username'] = plot_data_usernames
df['Ranking Points'] = plot_data_ranking_points
fig, ax1 = plt.subplots(1)
sns.barplot(df['Ranking Points'],df['Username'],ax=ax1,palette='Blues_r')
#plt.show()
fig.subplots_adjust(bottom=0.03,left=0.3,right=0.95,top=0.95)
ax1.tick_params(labelsize=24)
ax1.set_xscale('log')
plt.savefig('test_log.png')
#plt.show()
