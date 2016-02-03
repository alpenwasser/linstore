#!/usr/bin/env python3

import pprint as pp
import json as js
#import sympy as sp
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import re as re
import datetime as dt
import operator as op


timestamp = dt.datetime.now().strftime("%Y-%m-%d--%H-%M-%S")
plot_dir = 'plots/'
rankings_plot = timestamp + '--rankings.png'
rankings_plot_caps = timestamp + '--rankings-caps.png'
rankings_plot_drvc = timestamp + '--rankings-drvc.png'
rankings_plot_path = plot_dir + timestamp + '--rankings.png'
rankings_plot_caps_path = plot_dir + timestamp + '--rankings-caps.png'
rankings_plot_drvc_path = plot_dir + timestamp + '--rankings-drvc.png'

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


# Find highest points, capacity and drive counts:
max_points = 0
max_cap = 0
max_drvc = 0
for system in system_db.keys():
    if system_db[system]['ranking_points'] > max_points:
        max_points = system_db[system]['ranking_points']
    if system_db[system]['capacity'] > max_cap:
        max_cap = system_db[system]['capacity']
    if system_db[system]['drive_count'] > max_drvc:
        max_drvc = system_db[system]['drive_count']

# max_points is defined as 100% width, everything is relative to that, logarithmically
for system in system_db.keys():
    system_db[system]['rp_bar'] = np.log(system_db[system]['ranking_points']) / np.log(max_points) * 100
    system_db[system]['cap_bar'] = np.log(system_db[system]['capacity']) / np.log(max_points) * 100
    system_db[system]['drvc_bar'] = np.log(system_db[system]['drive_count']) / np.log(max_points) * 100


# Rank systems
# Sort by ranking points first, descending, then by post number, ascending
ranked_systems = sorted(system_db, key=lambda system: (system_db[system]['ranking_points'],-system_db[system]['post']), reverse=True)

# Create empty json objects
ranking_file='json/ranking.json'
notew_file='json/notew.json'
ranking_db = js.loads('{}')
notew_db = js.loads('{}')

# Populate databases
rank = 0
for ranked_system in ranked_systems:
    if (system_db[ranked_system]['drive_count'] < 5
        or system_db[ranked_system]['capacity'] < 10
        or system_db[ranked_system]['ditch'] == 1):
        notew_db[ranked_system] = system_db[ranked_system]
        continue
    rank += 1
    ranking_db[rank] = system_db[ranked_system]

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
            # We're in the header
            template_header += html_tpl_str
        else:
            # We're in the footer
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
rp_bar_sub = '%rp_bar%'
cap_bar_sub = '%cap_bar%'
drvc_bar_sub = '%drvc_bar%'

# Assemble ranking table
rows = ''
for rank in ranking_db.keys():
    row = re.sub(rank_sub,str(rank),template_row)
    row = re.sub(username_sub,ranking_db[rank]['username'],row)
    row = re.sub(rankingpoints_sub,"{:.2f}".format(ranking_db[rank]['ranking_points']),row)
    row = re.sub(capacity_sub,str(ranking_db[rank]['capacity']),row)
    row = re.sub(nodrives_sub,str(ranking_db[rank]['drive_count']),row)
    row = re.sub(case_sub,str(ranking_db[rank]['case']),row)
    row = re.sub(rp_bar_sub,str(ranking_db[rank]['rp_bar']),row)
    row = re.sub(cap_bar_sub,str(ranking_db[rank]['cap_bar']),row)
    row = re.sub(drvc_bar_sub,str(ranking_db[rank]['drvc_bar']),row)
    rows += row

# Insert Images
rankings_plot_pattern = '%%%<rankings_plot>%%%'
template_footer = re.sub(rankings_plot_pattern,rankings_plot,template_footer)
rankings_plot_pattern = '%%%<rankings_plot_caps>%%%'
template_footer = re.sub(rankings_plot_pattern,rankings_plot_caps,template_footer)
rankings_plot_pattern = '%%%<rankings_plot_drvc>%%%'
template_footer = re.sub(rankings_plot_pattern,rankings_plot_drvc,template_footer)

html_file = open('rankings.html','w')
html_file.write(template_header)
html_file.write(rows)
html_file.write(template_footer)
html_file.close()

#exit()

# ---------------------------------------------------------------------------- #
# GENERATE PLOTS                                                               #
# ---------------------------------------------------------------------------- #


rank_length = len(str(max(ranking_db.keys())))
ranking_points_lengths = []
username_lengths = []
capacity_lengths = []
drivecount_lengths = []
for rank in ranking_db.keys():
    ranking_points_lengths.append(len('{:.2f}'.format(ranking_db[rank]['ranking_points'])))
    username_lengths.append(len(ranking_db[rank]['username']))
    drivecount_lengths.append(len(str(ranking_db[rank]['drive_count'])))
    capacity_lengths.append(len(str(ranking_db[rank]['capacity'])))
ranking_point_length = max(ranking_points_lengths)
username_length = max(username_lengths)
capacity_length = max(capacity_lengths)
drivecount_length = max(drivecount_lengths)


plot_data_ranking_points = np.array([])
plot_data_usernames = []
plot_data_capacities = []
plot_data_drivecount = []
plot_data_usernames_caps = []
plot_data_usernames_drvc = []
for rank in ranking_db.keys():
    plot_data_usernames.append(str(rank) + '{0: >{pad}}'.format(ranking_db[rank]['username'], pad = username_length + 1 ) + '{0: >{pad}.2f}'.format(ranking_db[rank]['ranking_points'], pad = ranking_point_length + 1))
    plot_data_usernames_caps.append(str(rank) + '{0: >{pad}}'.format(ranking_db[rank]['username'], pad = username_length + 1 ) + '{0: >{pad}}'.format(ranking_db[rank]['capacity'], pad = capacity_length + 1))
    plot_data_usernames_drvc.append(str(rank) + '{0: >{pad}}'.format(ranking_db[rank]['username'], pad = username_length + 1 ) + '{0: >{pad}}'.format(ranking_db[rank]['drive_count'], pad = drivecount_length + 1))
    plot_data_ranking_points = np.append(plot_data_ranking_points, [ranking_db[rank]['ranking_points']])
    plot_data_capacities = np.append(plot_data_capacities, [ranking_db[rank]['capacity']])
    plot_data_drivecount = np.append(plot_data_drivecount, [ranking_db[rank]['drive_count']])

df = pd.DataFrame()
df['Username'] = plot_data_usernames
df['Username Caps'] = plot_data_usernames_caps
df['Username DrvC'] = plot_data_usernames_drvc
df['Ranking Points'] = plot_data_ranking_points
df['Capacity'] = plot_data_capacities
df['Drive Count'] = plot_data_drivecount

#plt.rc('text', usetex=True)
plt.rc('figure',figsize=(16,40))
plt.rc('font',family='monospace')
fig, ax1 = plt.subplots(1)
sns.barplot(df['Ranking Points'],df['Username'],ax=ax1,palette='Blues_r')
fig.subplots_adjust(bottom=0.01,left=0.33,right=0.98,top=0.99)
ax1.set_xlabel('Ranking Points',fontsize=20)
ax1.set_ylabel('User',fontsize=20)
ax1.set_xlim([0.8*np.amin(plot_data_ranking_points),1.5*np.amax(plot_data_ranking_points)])
ax1.tick_params(labelsize=20)
ax1.set_xscale('log')

plt.savefig(rankings_plot_path)


fig2, ax2 = plt.subplots(1)
sns.barplot(df['Capacity'],df['Username Caps'],ax=ax2,palette='Blues_r')
fig2.subplots_adjust(bottom=0.01,left=0.33,right=0.98,top=0.99)
ax2.set_xlabel('Capacity',fontsize=20)
ax2.set_ylabel('User',fontsize=20)
ax2.tick_params(labelsize=20)
ax2.set_xlim([0.8*np.amin(plot_data_capacities),1.5*np.amax(plot_data_capacities)])
ax2.set_xscale('log')

plt.savefig(rankings_plot_caps_path)


fig3, ax3 = plt.subplots(1)
sns.barplot(df['Drive Count'],df['Username DrvC'],ax=ax3,palette='Blues_r')
fig3.subplots_adjust(bottom=0.01,left=0.33,right=0.98,top=0.99)
ax3.set_xlabel('Drive Count',fontsize=20)
ax3.set_ylabel('User',fontsize=20)
ax3.tick_params(labelsize=20)
ax3.set_xlim([0.8*np.amin(plot_data_drivecount),1.5*np.amax(plot_data_drivecount)])
ax3.set_xscale('log')

plt.savefig(rankings_plot_drvc_path)
#plt.show()
