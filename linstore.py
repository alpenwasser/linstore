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
from matplotlib.ticker import ScalarFormatter


#timestamp = dt.datetime.now().strftime("%Y-%m-%d--%H-%M-%S")
timestamp = '2016-02-06--17-09-22'
plot_dir = 'plots/'
rankings_plot           = timestamp + '--rankings.svg'
rankings_plot_caps      = timestamp + '--rankings-caps.svg'
rankings_plot_drvc      = timestamp + '--rankings-drvc.svg'
drive_heatmap           = timestamp + '--drive-heatmap.svg'
os_heatmap              = timestamp + '--os-heatmap.svg'
os_heatmap_caps         = timestamp + '--os-heatmap-caps.svg'
os_heatmap_drvc         = timestamp + '--os-heatmap-drvc.svg'
drive_heatmap_contribs  = timestamp + '--drive-heatmap-contribs.svg'
drive_heatmap_systems   = timestamp + '--drive-heatmap-systems.svg'
storage_sys_plot        = timestamp + '--storage_sys.svg'
timeline_sys_plot       = timestamp + '--timeline_sys.svg'
timeline_caps_plot      = timestamp + '--timeline_caps.svg'
timeline_drvc_plot      = timestamp + '--timeline_drvc.svg'
rankings_plot_path          = plot_dir + timestamp + '--rankings.svg'
rankings_plot_caps_path     = plot_dir + timestamp + '--rankings-caps.svg'
rankings_plot_drvc_path     = plot_dir + timestamp + '--rankings-drvc.svg'
drive_heatmap_path          = plot_dir + timestamp + '--drive-heatmap.svg'
drive_heatmap_contribs_path = plot_dir + timestamp + '--drive-heatmap-contribs.svg'
drive_heatmap_systems_path  = plot_dir + timestamp + '--drive-heatmap-systems.svg'
os_heatmap_path             = plot_dir + timestamp + '--os-heatmap.svg'
os_heatmap_caps_path        = plot_dir + timestamp + '--os-heatmap-caps.svg'
os_heatmap_drvc_path        = plot_dir + timestamp + '--os-heatmap-drvc.svg'
storage_sys_plot_path       = plot_dir + timestamp + '--storage_sys.svg'
timeline_sys_plot_path      = plot_dir + timestamp + '--timeline_sys.svg'
timeline_caps_plot_path     = plot_dir + timestamp + '--timeline_caps.svg'
timeline_drvc_plot_path     = plot_dir + timestamp + '--timeline_drvc.svg'

drive_existence_failure = 5
os_existence_failure = 6
storage_sys_failure = 7

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

storage_sys_file='json/storage_sys.json'
storage_sys_data = open(storage_sys_file)
storage_sys_db = js.load(storage_sys_data)
storage_sys_data.close()

os_file='json/os_abbr_key.json'
os_data=open(os_file)
os_db = js.load(os_data)
os_data.close()

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
        else:
            print("Drive not found in " + drives_file + ": " + drive_type)
            exit(drive_existence_failure)

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

# Calcualte widths for bar lengths in HTML table
# max_points is defined as 100% width, everything is relative to that, logarithmically
for system in system_db.keys():
    system_db[system]['rp_bar'] = np.log(system_db[system]['ranking_points']) / np.log(max_points) * 100
    system_db[system]['cap_bar'] = np.log(system_db[system]['capacity']) / np.log(max_points) * 100
    system_db[system]['drvc_bar'] = np.log(system_db[system]['drive_count']) / np.log(max_points) * 100


# Rank systems
# Sort by ranking points first, descending, then by post number, ascending
ranked_systems = sorted(system_db, key=lambda system: (system_db[system]['ranking_points'],-system_db[system]['post']), reverse=True)
ranked_systems_timeline = sorted(system_db, key=lambda system: (system_db[system]['timestamp']), reverse=False)

# Create empty json objects
ranking_db = js.loads('{}')
timeline_db = js.loads('{}')
notew_db = js.loads('{}')
drive_stats_db = js.loads('{}')
os_stats_db = js.loads('{}')
stor_sys_stats_db = js.loads('{}')

timeline_capacity = 0
timeline_drive_count = 0
timeline_system_count = 0
for ranked_system_timeline in ranked_systems_timeline:
    if (system_db[ranked_system_timeline]['drive_count'] < 5
        or system_db[ranked_system_timeline]['capacity'] < 10
        or system_db[ranked_system_timeline]['ditch'] == 1):
        continue
    timeline_capacity     += system_db[ranked_system_timeline]['capacity']
    timeline_drive_count  += system_db[ranked_system_timeline]['drive_count']
    timeline_system_count += 1
    timeline_db[ system_db[ranked_system_timeline]['timestamp'] ] = {'capacity': timeline_capacity, 'drive_count': timeline_drive_count, 'system_count': timeline_system_count}


# Populate databases
rank = 0
total_drives = 0
total_capacity = 0
for ranked_system in ranked_systems:
    if (system_db[ranked_system]['drive_count'] < 5
        or system_db[ranked_system]['capacity'] < 10
        or system_db[ranked_system]['ditch'] == 1):
        notew_db[ranked_system] = system_db[ranked_system]
        continue
    rank += 1
    ranking_db[rank] = system_db[ranked_system]
    total_capacity += ranking_db[rank]['capacity']
    total_drives   += ranking_db[rank]['drive_count']

    # Drive Statistics
    for drive_type in system_db[ranked_system]['drives'].keys():
        if drive_db[drive_type]['vendor'] in drive_stats_db:
            if drive_db[drive_type]['size'] in drive_stats_db[ drive_db[drive_type]['vendor'] ]:
                # Add number of drives
                drive_stats_db[ drive_db[drive_type]['vendor'] ][ drive_db[drive_type]['size'] ]['count'] += system_db[ranked_system]['drives'][drive_type]
                drive_stats_db[ drive_db[drive_type]['vendor'] ][ drive_db[drive_type]['size'] ]['system_usage'] += 1
            else:
                # Add number of drives
                drive_stats_db[ drive_db[drive_type]['vendor'] ][ drive_db[drive_type]['size'] ] = {}
                drive_stats_db[ drive_db[drive_type]['vendor'] ][ drive_db[drive_type]['size'] ]['count'] = system_db[ranked_system]['drives'][drive_type]
                drive_stats_db[ drive_db[drive_type]['vendor'] ][ drive_db[drive_type]['size'] ]['system_usage'] = 1
        else:
            # Add number of drives
            drive_stats_db[ drive_db[drive_type]['vendor'] ] = {}
            drive_stats_db[ drive_db[drive_type]['vendor'] ][ drive_db[drive_type]['size'] ] = {}
            # Set to number of drives of that size
            drive_stats_db[ drive_db[drive_type]['vendor'] ][ drive_db[drive_type]['size'] ]['count'] = system_db[ranked_system]['drives'][drive_type]
            drive_stats_db[ drive_db[drive_type]['vendor'] ][ drive_db[drive_type]['size'] ]['system_usage'] = 1

    for storage_sys in system_db[ranked_system]['storage_sys'].keys():
        if storage_sys not in storage_sys_db:
            print("Storage System not found in " + storage_sys_file + ": " + storage_sys)
            exit(storage_sys_failure)
        if storage_sys_db[storage_sys] in stor_sys_stats_db:
            stor_sys_stats_db[storage_sys_db[storage_sys]] += system_db[ranked_system]['storage_sys'][storage_sys]
        else:
            stor_sys_stats_db[storage_sys_db[storage_sys]] = system_db[ranked_system]['storage_sys'][storage_sys]


    if system_db[ranked_system]['os'] not in os_db:
        print("OS not found in " + os_file + ": " + system_db[ranked_system]['os'])
        exit(os_existence_failure)

    if system_db[ranked_system]['os'] in os_stats_db:
        os_stats_db[system_db[ranked_system]['os']]['count'] += 1
        os_stats_db[system_db[ranked_system]['os']]['drive_count'] += system_db[ranked_system]['drive_count']
        os_stats_db[system_db[ranked_system]['os']]['capacity'] += system_db[ranked_system]['capacity']
    else:
        os_stats_db[system_db[ranked_system]['os']] = os_db[system_db[ranked_system]['os']]
        os_stats_db[system_db[ranked_system]['os']]['count'] = 1
        os_stats_db[system_db[ranked_system]['os']]['drive_count'] = system_db[ranked_system]['drive_count']
        os_stats_db[system_db[ranked_system]['os']]['capacity'] = system_db[ranked_system]['capacity']


ranking_file='json/ranking.json'
ranking_data=open(ranking_file, 'w')
js.dump(ranking_db,ranking_data,indent=1,sort_keys=True)
ranking_data.close()

notew_file='json/notew.json'
notew_data=open(notew_file, 'w')
js.dump(notew_db,notew_data,indent=1,sort_keys=True)
notew_data.close()

drive_stats_file='json/drive_stats.json'
drive_stats_data=open(drive_stats_file, 'w')
js.dump(drive_stats_db,drive_stats_data,indent=1)
drive_stats_data.close()

os_stats_file='json/os_stats.json'
os_stats_data=open(os_stats_file, 'w')
js.dump(os_stats_db,os_stats_data,indent=1)
os_stats_data.close()

stor_sys_stats_file='json/storage_sys_stats.json'
stor_sys_stats_data=open(stor_sys_stats_file, 'w')
js.dump(stor_sys_stats_db,stor_sys_stats_data,indent=1)
stor_sys_stats_data.close()

# ---------------------------------------------------------------------------- #
# GENERATE HTML                                                                #
# ---------------------------------------------------------------------------- #

html_template_file = 'template.html'
html_template = open(html_template_file, 'r')
header_tago = re.compile('%%%<ranked_header>%%%')
header_tagc = re.compile('%%%</ranked_header>%%%')
header_open = False
ranked_row_tago = re.compile('%%%<ranked_row>%%%')
ranked_row_tagc = re.compile('%%%</ranked_row>%%%')
ranked_row_open = False
abbr_tago = re.compile('%%%<abbr_key>%%%')
abbr_tagc = re.compile('%%%</abbr_key>%%%')
abbr_open = False
plots_tago = re.compile('%%%<plots>%%%')
plots_tagc = re.compile('%%%</plots>%%%')
plots_open = False
notew_header_tago = re.compile('%%%<notew_header>%%%')
notew_header_tagc = re.compile('%%%</notew_header>%%%')
notew_header_open = False
notew_row_tago = re.compile('%%%<notew_row>%%%')
notew_row_tagc = re.compile('%%%</notew_row>%%%')
notew_row_open = False
footer_tago = re.compile('%%%<footer>%%%')
footer_tagc = re.compile('%%%</footer>%%%')
footer_open = False


opening_tag=re.compile('%%%<template_row>%%%')
closing_tag=re.compile(r'%%%</template_row>%%%')
opening_tag_notew=re.compile('%%%<template_row>%%%')
closing_tag_notew=re.compile(r'%%%</template_row>%%%')

result=''

tag_open = False # indicates whether tag is currently open
tag_open_notew = False # indicates whether tag is currently open
tag_has_been_opened = False # indicates whether tag has ever been opened: used for footer/header
tag_has_been_opened_notew = False # indicates whether tag has ever been opened: used for footer/header

# First, grab header, footer and the template row which will be used to assemble
# the system entries.
template_ranked_header = ''
template_ranked_row = ''
template_abbr_key = ''
template_plots = ''
template_notew_header = ''
template_notew_row = ''
template_footer = ''

for line in html_template:
    if header_tago.search(line):
        header_open = True
    elif header_open:
        if header_tagc.search(line):
            header_open = False
            continue
        template_ranked_header += line
    elif ranked_row_tago.search(line):
        ranked_row_open = True
    elif ranked_row_open:
        if ranked_row_tagc.search(line):
            ranked_row_open = False
            continue
        template_ranked_row += line
    elif abbr_tago.search(line):
        abbr_open = True
    elif abbr_open:
        if abbr_tagc.search(line):
            abbr_open = False
            continue
        template_abbr_key += line
    elif plots_tago.search(line):
        plots_open = True
    elif plots_open:
        if plots_tagc.search(line):
            plots_open = False
            continue
        template_plots += line
    elif notew_header_tago.search(line):
        notew_header_open = True
    elif notew_header_open:
        if notew_header_tagc.search(line):
            notew_header_open = False
            continue
        template_notew_header += line
    elif notew_row_tago.search(line):
        notew_row_open = True
    elif notew_row_open:
        if notew_row_tagc.search(line):
            notew_row_open = False
            continue
        template_notew_row += line
    elif footer_tago.search(line):
        footer_open = True
    elif footer_open:
        if footer_tagc.search(line):
            footer_open = False
            continue
        template_footer += line



# Generate rows:
# Regex search and replace patterns
rank_sub = '%r%'
username_sub = '%u%'
postNo_sub = '%postNo%'
rankingpoints_sub = '%rp%'
capacity_sub = '%cap%'
nodrives_sub = '%ndr%'
case_sub = '%cs%'
os_sub = '%os%'
updPost_sub = '%updPost%'
updNo_sub = '%updNo%'
upd_line_sub = '%upd_line%'
stsys_sub = '%stsys%'
rp_bar_sub = '%rp_bar%'
cap_bar_sub = '%cap_bar%'
drvc_bar_sub = '%drvc_bar%'
drvc_bar_sub = '%drvc_bar%'
upd_template = '<a style="color:#aaaaaa;" href="https://linustechtips.com/main/topic/21948-ltt-10tb-storage-show-off-topic/?do=findComment&comment=%updPost%">%updNo%</a>'

# Assemble ranking table
ranked_rows = ''
for rank in ranking_db.keys():
    storage_sys_str = ''
    first_stor_sys = True
    ranked_row = re.sub(rank_sub,str(rank),template_ranked_row)
    ranked_row = re.sub(username_sub,ranking_db[rank]['username'],ranked_row)
    ranked_row = re.sub(postNo_sub,str(ranking_db[rank]['post']),ranked_row)
    ranked_row = re.sub(rankingpoints_sub,"{:.2f}".format(ranking_db[rank]['ranking_points']),ranked_row)
    ranked_row = re.sub(capacity_sub,str(ranking_db[rank]['capacity']),ranked_row)
    ranked_row = re.sub(nodrives_sub,str(ranking_db[rank]['drive_count']),ranked_row)
    ranked_row = re.sub(case_sub,str(ranking_db[rank]['case']),ranked_row)
    ranked_row = re.sub(os_sub,str(ranking_db[rank]['os']),ranked_row)
    ranked_row = re.sub(rp_bar_sub,str(ranking_db[rank]['rp_bar']),ranked_row)
    ranked_row = re.sub(cap_bar_sub,str(ranking_db[rank]['cap_bar']),ranked_row)
    ranked_row = re.sub(drvc_bar_sub,str(ranking_db[rank]['drvc_bar']),ranked_row)
    for storage_sys in ranking_db[rank]['storage_sys']:
        if first_stor_sys:
            storage_sys_str += storage_sys
            first_stor_sys = False
        else:
            storage_sys_str += ', ' + storage_sys
    ranked_row = re.sub(stsys_sub,storage_sys_str,ranked_row)
    if ranking_db[rank]['updates']:
        updNo = 1
        update_str = ''
        first_upd = True
        for updPost in ranking_db[rank]['updates']:
            upd_line = upd_template
            upd_line = re.sub(updPost_sub, str(updPost), upd_line)
            upd_line = re.sub(updNo_sub, str(updNo), upd_line)
            if first_upd:
                update_str += upd_line
                updNo += 1
                first_upd = False
            else:
                update_str += ', ' + upd_line
                updNo += 1
    else:
        update_str = '&nbsp;'
    ranked_row = re.sub(upd_line_sub, update_str, ranked_row)
    ranked_rows += ranked_row


# Insert Images
rankings_plot_pattern = '%%%<rankings_plot>%%%'
rankings_plot_caps_pattern = '%%%<rankings_plot_caps>%%%'
rankings_plot_drvc_pattern = '%%%<rankings_plot_drvc>%%%'
drive_heatmap_pattern = '%%%<drive_heatmap>%%%'
drive_heatmap_contribs_pattern = '%%%<drive_heatmap_contribs>%%%'
drive_heatmap_systems_pattern = '%%%<drive_heatmap_systems>%%%'
os_heatmap_pattern = '%%%<os_heatmap>%%%'
os_heatmap_caps_pattern = '%%%<os_heatmap_caps>%%%'
os_heatmap_drvc_pattern = '%%%<os_heatmap_drvc>%%%'
timeline_sys_pattern = '%%%<timeline_sys>%%%'
timeline_caps_pattern = '%%%<timeline_caps>%%%'
timeline_drvc_pattern = '%%%<timeline_drvc>%%%'
storage_sys_pattern = '%%%<storage_sys_plot>%%%'
total_dr_sub = '%tdr%'
total_cp_sub = '%tc%'
template_plots = re.sub(rankings_plot_pattern,rankings_plot,template_plots)
template_plots = re.sub(rankings_plot_caps_pattern,rankings_plot_caps,template_plots)
template_plots = re.sub(rankings_plot_drvc_pattern,rankings_plot_drvc,template_plots)
template_plots = re.sub(drive_heatmap_pattern,drive_heatmap,template_plots)
template_plots = re.sub(drive_heatmap_contribs_pattern,drive_heatmap_contribs,template_plots)
template_plots = re.sub(drive_heatmap_systems_pattern,drive_heatmap_systems,template_plots)
template_plots = re.sub(os_heatmap_pattern,os_heatmap,template_plots)
template_plots = re.sub(os_heatmap_caps_pattern,os_heatmap_caps,template_plots)
template_plots = re.sub(os_heatmap_drvc_pattern,os_heatmap_drvc,template_plots)
template_plots = re.sub(total_dr_sub,str(total_drives),template_plots)
template_plots = re.sub(total_cp_sub,str(total_capacity),template_plots)
template_plots = re.sub(storage_sys_pattern,storage_sys_plot,template_plots)
template_plots = re.sub(timeline_sys_pattern, timeline_sys_plot, template_plots)
template_plots = re.sub(timeline_caps_pattern, timeline_caps_plot, template_plots)
template_plots = re.sub(timeline_drvc_pattern, timeline_drvc_plot, template_plots)

#print(template_notew_row)
#print(template_footer)
notew_rows = ''
for rank in notew_db.keys():
    storage_sys_str = ''
    first_stor_sys = True
    notew_row = re.sub(rank_sub,str(rank),template_notew_row)
    notew_row = re.sub(username_sub,notew_db[rank]['username'],notew_row)
    notew_row = re.sub(postNo_sub,str(notew_db[rank]['post']),notew_row)
    notew_row = re.sub(rankingpoints_sub,"{:.2f}".format(notew_db[rank]['ranking_points']),notew_row)
    notew_row = re.sub(capacity_sub,str(notew_db[rank]['capacity']),notew_row)
    notew_row = re.sub(nodrives_sub,str(notew_db[rank]['drive_count']),notew_row)
    notew_row = re.sub(case_sub,str(notew_db[rank]['case']),notew_row)
    notew_row = re.sub(os_sub,str(notew_db[rank]['os']),notew_row)
    for storage_sys in notew_db[rank]['storage_sys']:
        if first_stor_sys:
            storage_sys_str += storage_sys
            first_stor_sys = False
        else:
            storage_sys_str += ', ' + storage_sys
    notew_row = re.sub(stsys_sub,storage_sys_str,notew_row)
    notew_row = re.sub(stsys_sub,str(notew_db[rank]['storage_sys']),notew_row)
    notew_rows += notew_row


html_file = open('rankings.html','w')
html_file.write(template_ranked_header)
html_file.write(ranked_rows)
html_file.write(template_abbr_key)
html_file.write(template_plots)
html_file.write(template_notew_header)
html_file.write(notew_rows)
html_file.write(template_footer)
html_file.close()

exit()

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
plot_data_usernames_caps = [] # for username string
plot_data_usernames_drvc = [] # for username string
plot_data_capacities = []
plot_data_drivecount = []
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

# Drive Heatmaps (Count and Contributions)
df = pd.DataFrame()
plot_data_drive_vendors = []  # list of vendors
plot_data_drive_caps = []     # list of drive capacities
plot_data_drive_counts = []   # How many HDDs of this type are used?
plot_data_drive_contribs = [] # How much does this type of HDD contribute to total capacity?
plot_data_drive_systems = []  # how many systems use this type of HDD?
for vendor in drive_stats_db.keys():
    for capacity in drive_stats_db[vendor].keys():
        plot_data_drive_vendors.append(vendor)
        plot_data_drive_caps.append(capacity)
        plot_data_drive_counts.append(drive_stats_db[vendor][capacity]['count'])
        plot_data_drive_contribs.append(drive_stats_db[vendor][capacity]['count'] * capacity)
        plot_data_drive_systems.append(drive_stats_db[vendor][capacity]['system_usage'])

df['Vendor'] = plot_data_drive_vendors
df['Capacity (TB)'] = plot_data_drive_caps
df['Count'] = plot_data_drive_counts
df['Contribution'] = plot_data_drive_contribs
df['Systems'] = plot_data_drive_systems
df = df.sort_values(by=['Capacity (TB)'], ascending=[True])
#df = df.pivot('Vendor','Capacity (TB)','Count')


# We  need to  pivot  differently for  the  heatmap and  top
# histogram,  and for  the vertical  histogram on  the right
# side.
df_heatmap = pd.DataFrame()
df_heatmap = df.pivot('Vendor','Capacity (TB)','Count')
df_verthist = pd.DataFrame()
df_verthist = df.pivot('Capacity (TB)','Vendor','Count')

df_sums_ven = pd.DataFrame()
df_sums_ven['Count'] = df_heatmap.sum(axis=1)
df_sums_cap = pd.DataFrame()
df_sums_cap['Count'] = df_verthist.sum(axis=1)

plt.rc('figure',figsize=(16,10)) # 1600 x 1000 px at 100 dpi
plt.rc('font',family='monospace')
fig4 = plt.figure()
fig4.subplots_adjust(bottom=0.10,left=0.125,right=0.975,top=0.97)
ax4 = plt.subplot2grid((22, 30), ( 0, 0), colspan=26, rowspan=4)  # top histogram
ax5 = plt.subplot2grid((22, 30), ( 4, 0), colspan=26, rowspan=15) # heatmap
ax6 = plt.subplot2grid((22, 30), ( 4,26), colspan=4,  rowspan=15) # right histogram
ax7 = plt.subplot2grid((22, 30), (21, 0), colspan=26)             # color bar
sns.barplot(df_sums_cap.index.tolist(), df_sums_cap['Count'],      ax=ax4,palette="Greys_r") # top histogram
sns.barplot(df_sums_ven['Count'],       df_sums_ven.index.tolist(),ax=ax6,palette="Greys_r") # right histogram
ax4.set_xlabel('')
ax4.set_ylabel('Drives (log)', fontsize=11)
ax6.set_ylabel('')
ax6.set_xlabel('Drives (log)', fontsize=11)
ax4.set(xticks=[])
ax6.set(yticks=[])
ax4.tick_params(labelsize=11)
ax6.tick_params(labelsize=11)
ax4.set_yscale('log')
ax6.set_xscale('log')
ax4.yaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'
ax6.xaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'

ax5.set_xlabel('Capacity (TB)',fontsize=16)
ax5.set_ylabel('Vendor',fontsize=16)
ax5.tick_params(labelsize=14)
sns.heatmap(df_heatmap, linewidths=.5, ax=ax5, annot=True, fmt='g', cbar_ax = ax7, cbar_kws={"orientation": "horizontal"})
plt.setp(ax5.yaxis.get_majorticklabels(), rotation=0)
plt.setp(ax6.xaxis.get_majorticklabels(), rotation=90)
cax = plt.gcf().axes[-1]
cax.tick_params(labelsize=12)
plt.savefig(drive_heatmap_path)
#plt.show()

df_heatmap_contribs = pd.DataFrame()
df_heatmap_contribs = df.pivot('Vendor','Capacity (TB)','Contribution')
df_verthist_contribs = pd.DataFrame()
df_verthist_contribs = df.pivot('Capacity (TB)','Vendor','Contribution')

df_sums_ven_contribs = pd.DataFrame()
df_sums_ven_contribs['Contribution'] = df_heatmap_contribs.sum(axis=1)
df_sums_cap_contribs = pd.DataFrame()
df_sums_cap_contribs['Contribution'] = df_verthist_contribs.sum(axis=1)

plt.rc('figure',figsize=(16,10)) # 1600 x 1000 px at 100 dpi
plt.rc('font',family='monospace')
fig5 = plt.figure()
fig5.subplots_adjust(bottom=0.10,left=0.125,right=0.975,top=0.97)
ax8 = plt.subplot2grid((22, 30), ( 0, 0), colspan=26, rowspan=4)  # top histogram
ax9 = plt.subplot2grid((22, 30), ( 4, 0), colspan=26, rowspan=15) # heatmap
ax10 = plt.subplot2grid((22, 30), ( 4,26), colspan=4,  rowspan=15) # right histogram
ax11 = plt.subplot2grid((22, 30), (21, 0), colspan=26)             # color bar
sns.barplot(df_sums_cap_contribs.index.tolist(), df_sums_cap_contribs['Contribution'],      ax=ax8,palette="Greys_r") # top histogram
sns.barplot(df_sums_ven_contribs['Contribution'],       df_sums_ven_contribs.index.tolist(),ax=ax10,palette="Greys_r") # right histogram
ax8.set_xlabel('')
ax8.set_ylabel('Contribution (log)', fontsize=11)
ax10.set_ylabel('')
ax10.set_xlabel('Contribution (log)', fontsize=11)
ax8.set(xticks=[])
ax10.set(yticks=[])
ax8.tick_params(labelsize=11)
ax10.tick_params(labelsize=11)
ax8.set_yscale('log')
ax10.set_xscale('log')
ax8.yaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'
ax10.xaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'

ax9.set_xlabel('Capacity (TB)',fontsize=16)
ax9.set_ylabel('Vendor',fontsize=16)
ax9.tick_params(labelsize=14)
sns.heatmap(df_heatmap_contribs, linewidths=.5, ax=ax9, annot=True, fmt='g', cbar_ax = ax11, cbar_kws={"orientation": "horizontal"})
plt.setp(ax9.yaxis.get_majorticklabels(), rotation=0)
plt.setp(ax10.xaxis.get_majorticklabels(), rotation=90)
cax = plt.gcf().axes[-1]
cax.tick_params(labelsize=12)
plt.savefig(drive_heatmap_contribs_path)
#plt.show()

df_heatmap_systems = pd.DataFrame()
df_heatmap_systems = df.pivot('Vendor','Capacity (TB)','Systems')
df_verthist_systems = pd.DataFrame()
df_verthist_systems = df.pivot('Capacity (TB)','Vendor','Systems')

df_sums_ven_systems = pd.DataFrame()
df_sums_ven_systems['Systems'] = df_heatmap_systems.sum(axis=1)
df_sums_cap_systems = pd.DataFrame()
df_sums_cap_systems['Systems'] = df_verthist_systems.sum(axis=1)

plt.rc('figure',figsize=(16,10)) # 1600 x 1000 px at 100 dpi
plt.rc('font',family='monospace')
fig5 = plt.figure()
fig5.subplots_adjust(bottom=0.10,left=0.125,right=0.975,top=0.97)
ax8 = plt.subplot2grid((22, 30), ( 0, 0), colspan=26, rowspan=4)  # top histogram
ax9 = plt.subplot2grid((22, 30), ( 4, 0), colspan=26, rowspan=15) # heatmap
ax10 = plt.subplot2grid((22, 30), ( 4,26), colspan=4,  rowspan=15) # right histogram
ax11 = plt.subplot2grid((22, 30), (21, 0), colspan=26)             # color bar
sns.barplot(df_sums_cap_systems.index.tolist(), df_sums_cap_systems['Systems'],      ax=ax8,palette="Greys_r") # top histogram
sns.barplot(df_sums_ven_systems['Systems'],       df_sums_ven_systems.index.tolist(),ax=ax10,palette="Greys_r") # right histogram
ax8.set_xlabel('')
ax8.set_ylabel('Systems (log)', fontsize=11)
ax10.set_ylabel('')
ax10.set_xlabel('Systems (log)', fontsize=11)
ax8.set(xticks=[])
ax10.set(yticks=[])
ax8.tick_params(labelsize=11)
ax10.tick_params(labelsize=11)
ax8.set_yscale('log')
ax10.set_xscale('log')
ax8.yaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'
ax10.xaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'

ax9.set_xlabel('Capacity (TB)',fontsize=16)
ax9.set_ylabel('Vendor',fontsize=16)
ax9.tick_params(labelsize=14)
sns.heatmap(df_heatmap_systems, linewidths=.5, ax=ax9, annot=True, fmt='g', cbar_ax = ax11, cbar_kws={"orientation": "horizontal"})
plt.setp(ax9.yaxis.get_majorticklabels(), rotation=0)
plt.setp(ax10.xaxis.get_majorticklabels(), rotation=90)
cax = plt.gcf().axes[-1]
cax.tick_params(labelsize=12)
plt.savefig(drive_heatmap_systems_path)
#plt.show()


# Operating System Plots
df_os = pd.DataFrame()
df_os_caps = pd.DataFrame()
df_os_drvc = pd.DataFrame()
plot_data_os_families= []
plot_data_os_versions = []
plot_data_os_counts = []
plot_data_os_drive_counts = []
plot_data_os_contribs = []
for os_key in os_stats_db.keys():
    plot_data_os_families.append(os_stats_db[os_key]['family'])
    plot_data_os_versions.append(os_stats_db[os_key]['os'])
    plot_data_os_counts = np.append(plot_data_os_counts, [os_stats_db[os_key]['count']])
    plot_data_os_drive_counts = np.append(plot_data_os_drive_counts, [os_stats_db[os_key]['drive_count']])
    plot_data_os_contribs = np.append(plot_data_os_contribs, [os_stats_db[os_key]['capacity']])
#for os_key in os_db.keys():


df_os['OS Family'] = plot_data_os_families
df_os['Operating System'] = plot_data_os_versions
df_os['Count'] = plot_data_os_counts
df_os_caps['OS Family'] = plot_data_os_families
df_os_caps['Operating System'] = plot_data_os_versions
df_os_caps['Capacity'] = plot_data_os_contribs
df_os_drvc['OS Family'] = plot_data_os_families
df_os_drvc['Operating System'] = plot_data_os_versions
df_os_drvc['Drives'] = plot_data_os_drive_counts

# We  need to  pivot  differently for  the  heatmap and  top
# histogram,  and for  the vertical  histogram on  the right
# side.
df_os_heatmap = pd.DataFrame()
df_os_heatmap = df_os.pivot('OS Family','Operating System','Count')
df_os_verthist = pd.DataFrame()
df_os_verthist = df_os.pivot('Operating System','OS Family','Count')
df_os_caps_heatmap = pd.DataFrame()
df_os_caps_heatmap = df_os_caps.pivot('OS Family','Operating System','Capacity')
df_os_caps_verthist = pd.DataFrame()
df_os_caps_verthist = df_os_caps.pivot('Operating System','OS Family','Capacity')
df_os_drvc_heatmap = pd.DataFrame()
df_os_drvc_heatmap = df_os_drvc.pivot('OS Family','Operating System','Drives')
df_os_drvc_verthist = pd.DataFrame()
df_os_drvc_verthist = df_os_drvc.pivot('Operating System','OS Family','Drives')

df_os_sums_fam = pd.DataFrame()
df_os_sums_fam['Count'] = df_os_heatmap.sum(axis=1)
df_os_caps_sums_fam = pd.DataFrame()
df_os_caps_sums_fam['Capacity'] = df_os_caps_heatmap.sum(axis=1)
df_os_drvc_sums_fam = pd.DataFrame()
df_os_drvc_sums_fam['Drives'] = df_os_drvc_heatmap.sum(axis=1)

plt.rc('figure',figsize=(16,10)) # 1600 x 1000 px at 100 dpi
plt.rc('font',family='monospace')

fig6 = plt.figure()
fig6.subplots_adjust(bottom=0.10,left=0.125,right=0.975,top=0.97)

ax13 = plt.subplot2grid((18, 30), ( 0, 0), colspan=26, rowspan=10) # heatmap
ax14 = plt.subplot2grid((18, 30), ( 0,26), colspan=4,  rowspan=10) # right histogram
ax15 = plt.subplot2grid((18, 30), (17, 0), colspan=26)             # color bar

sns.barplot(df_os_sums_fam['Count'],       df_os_sums_fam.index.tolist(),ax=ax14,palette="Greys_r") # right histogram
ax14.set_ylabel('')
ax14.set_xlabel('Count', fontsize=11)
ax14.set(yticks=[])
ax14.tick_params(labelsize=11)
ax14.xaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'

ax13.set_xlabel('Operating System',fontsize=16)
ax13.set_ylabel('OS Family',fontsize=16)
ax13.tick_params(labelsize=14)
sns.heatmap(df_os_heatmap, linewidths=.5, ax=ax13, annot=True, fmt='g', cbar_ax = ax15, cbar_kws={"orientation": "horizontal"})
plt.setp(ax13.yaxis.get_majorticklabels(), rotation=0)
plt.setp(ax13.xaxis.get_majorticklabels(), rotation=90)
plt.setp(ax14.xaxis.get_majorticklabels(), rotation=90)
cax = plt.gcf().axes[-1]
cax.tick_params(labelsize=12)
plt.savefig(os_heatmap_path)

fig7 = plt.figure()
fig7.subplots_adjust(bottom=0.10,left=0.125,right=0.975,top=0.97)

ax16 = plt.subplot2grid((18, 30), ( 0, 0), colspan=26, rowspan=10) # heatmap
ax17 = plt.subplot2grid((18, 30), ( 0,26), colspan=4,  rowspan=10) # right histogram
ax18 = plt.subplot2grid((18, 30), (17, 0), colspan=26)             # color bar

sns.barplot(df_os_caps_sums_fam['Capacity'],       df_os_caps_sums_fam.index.tolist(),ax=ax17,palette="Greys_r") # right histogram
ax17.set_ylabel('')
ax17.set_xlabel('Capacity', fontsize=11)
ax17.set(yticks=[])
ax17.tick_params(labelsize=11)
ax17.xaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'

ax16.set_xlabel('Operating System',fontsize=16)
ax16.set_ylabel('OS Family',fontsize=16)
ax16.tick_params(labelsize=14)
sns.heatmap(df_os_caps_heatmap, linewidths=.5, ax=ax16, annot=True, fmt='g', cbar_ax = ax18, cbar_kws={"orientation": "horizontal"})
plt.setp(ax16.yaxis.get_majorticklabels(), rotation=0)
plt.setp(ax16.xaxis.get_majorticklabels(), rotation=90)
plt.setp(ax17.xaxis.get_majorticklabels(), rotation=90)
cax = plt.gcf().axes[-1]
cax.tick_params(labelsize=12)
plt.savefig(os_heatmap_caps_path)

fig8 = plt.figure()
fig8.subplots_adjust(bottom=0.10,left=0.125,right=0.975,top=0.97)

ax19 = plt.subplot2grid((18, 30), ( 0, 0), colspan=26, rowspan=10) # heatmap
ax20 = plt.subplot2grid((18, 30), ( 0,26), colspan=4,  rowspan=10) # right histogram
ax21 = plt.subplot2grid((18, 30), (17, 0), colspan=26)             # color bar

sns.barplot(df_os_drvc_sums_fam['Drives'],       df_os_drvc_sums_fam.index.tolist(),ax=ax20,palette="Greys_r") # right histogram
ax20.set_ylabel('')
ax20.set_xlabel('Drives', fontsize=11)
ax20.set(yticks=[])
ax20.tick_params(labelsize=11)
ax20.xaxis.set_major_formatter(ScalarFormatter()) # Switch from '1e3' to '1000'

ax19.set_xlabel('Operating System',fontsize=16)
ax19.set_ylabel('OS Family',fontsize=16)
ax19.tick_params(labelsize=14)
sns.heatmap(df_os_drvc_heatmap, linewidths=.5, ax=ax19, annot=True, fmt='g', cbar_ax = ax21, cbar_kws={"orientation": "horizontal"})
plt.setp(ax19.yaxis.get_majorticklabels(), rotation=0)
plt.setp(ax19.xaxis.get_majorticklabels(), rotation=90)
plt.setp(ax20.xaxis.get_majorticklabels(), rotation=90)
cax = plt.gcf().axes[-1]
cax.tick_params(labelsize=12)
plt.savefig(os_heatmap_drvc_path)


plot_data_stor_sys = []
plot_data_stor_sys_count = []
for storage_sys in stor_sys_stats_db.keys():
    plot_data_stor_sys.append(storage_sys)
    plot_data_stor_sys_count.append(stor_sys_stats_db[storage_sys])
df_stor_sys = pd.DataFrame()
df_stor_sys['Storage System'] = plot_data_stor_sys
df_stor_sys['Usage'] = plot_data_stor_sys_count
plt.rc('figure',figsize=(16,12))
plt.rc('font',family='monospace')
fig9, ax22 = plt.subplots(1)
sns.barplot(df_stor_sys['Storage System'],df_stor_sys['Usage'],ax=ax22,palette=sns.color_palette("husl", df_stor_sys.shape[0]))
plt.setp(ax22.xaxis.get_majorticklabels(), rotation=90)
fig9.subplots_adjust(bottom=0.4,left=0.1,right=0.9,top=0.95)
ax22.set_xlabel('Storage System',fontsize=20)
ax22.set_ylabel('Number of Systems',fontsize=20)
ax22.tick_params(labelsize=20)
plt.savefig('test.png')
plt.savefig(storage_sys_plot_path)


plt.rc('figure',figsize=(16,9)) # 1600 x 900 px at 100 dpi
plot_data_timeline_dates = []
plot_data_timeline_caps  = []
plot_data_timeline_drvc  = []
plot_data_timeline_timestamps = []
plot_data_timeline_sys = []
for timestamp in timeline_db.keys():
    plot_data_timeline_dates.append(dt.datetime.fromtimestamp(timestamp).strftime("%Y-%b-%d"))
    plot_data_timeline_timestamps.append(timestamp)
    plot_data_timeline_caps.append(timeline_db[timestamp]['capacity'])
    plot_data_timeline_drvc.append(timeline_db[timestamp]['drive_count'])
    plot_data_timeline_sys.append(timeline_db[timestamp]['system_count'])
df_timeline = pd.DataFrame()
df_timeline['Timestamp'] = plot_data_timeline_timestamps
df_timeline['Date'] = plot_data_timeline_dates
df_timeline['Capacity (TB)'] = plot_data_timeline_caps
df_timeline['Drive Count'] = plot_data_timeline_drvc
df_timeline['System Count'] = plot_data_timeline_sys
df_timeline = df_timeline.sort_values(by=['Timestamp'], ascending=[True])
#ax = sns.swarmplot(x='Timestamp', y="Capacity", data=df_timeline)
fig10, ax23 = plt.subplots(1)
sns.stripplot(x='Date', y="Capacity (TB)", data=df_timeline, ax=ax23, palette = sns.dark_palette("purple"),size=10)
fig10.subplots_adjust(bottom=0.2,left=0.1,right=0.9,top=0.95)
plt.setp(ax23.xaxis.get_majorticklabels(), rotation=90)
plt.setp(ax23.get_xticklabels()[::], visible=False)
plt.setp(ax23.get_xticklabels()[::5], visible=True)
ax23.set_ylim(bottom=0)
fig10.savefig(timeline_caps_plot_path)

fig11, ax24 = plt.subplots(1)
sns.stripplot(x='Date', y="Drive Count", data=df_timeline, ax=ax24, palette = sns.dark_palette("purple"),size=10)
fig11.subplots_adjust(bottom=0.2,left=0.1,right=0.9,top=0.95)
plt.setp(ax24.xaxis.get_majorticklabels(), rotation=90)
plt.setp(ax24.get_xticklabels()[::], visible=False)
plt.setp(ax24.get_xticklabels()[::5], visible=True)
ax24.set_ylim(bottom=0)
fig11.savefig(timeline_drvc_plot_path)

fig12, ax25 = plt.subplots(1)
sns.stripplot(x='Date', y="System Count", data=df_timeline, ax=ax25, palette = sns.dark_palette("purple"),size=10)
fig12.subplots_adjust(bottom=0.2,left=0.1,right=0.9,top=0.95)
plt.setp(ax25.xaxis.get_majorticklabels(), rotation=90)
plt.setp(ax25.get_xticklabels()[::], visible=False)
plt.setp(ax25.get_xticklabels()[::5], visible=True)
ax25.set_ylim(bottom=0)
fig12.savefig(timeline_sys_plot_path)
