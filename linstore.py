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


timestamp = dt.datetime.now().strftime("%Y-%m-%d--%H-%M-%S")
plot_dir = 'plots/'
rankings_plot = timestamp + '--rankings.svg'
rankings_plot_caps      = timestamp + '--rankings-caps.svg'
rankings_plot_drvc      = timestamp + '--rankings-drvc.svg'
drive_heatmap           = timestamp + '--drive-heatmap.svg'
os_heatmap              = timestamp + '--os-heatmap.svg'
os_heatmap_caps         = timestamp + '--os-heatmap-caps.svg'
os_heatmap_drvc         = timestamp + '--os-heatmap-drvc.svg'
drive_heatmap_contribs  = timestamp + '--drive-heatmap-contribs.svg'
rankings_plot_path          = plot_dir + timestamp + '--rankings.svg'
rankings_plot_caps_path     = plot_dir + timestamp + '--rankings-caps.svg'
rankings_plot_drvc_path     = plot_dir + timestamp + '--rankings-drvc.svg'
drive_heatmap_path          = plot_dir + timestamp + '--drive-heatmap.svg'
drive_heatmap_contribs_path = plot_dir + timestamp + '--drive-heatmap-contribs.svg'
os_heatmap_path             = plot_dir + timestamp + '--os-heatmap.svg'
os_heatmap_caps_path        = plot_dir + timestamp + '--os-heatmap-caps.svg'
os_heatmap_drvc_path        = plot_dir + timestamp + '--os-heatmap-drvc.svg'

drive_existence_failure = 5
os_existence_failure = 6

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

# Create empty json objects
ranking_file='json/ranking.json'
notew_file='json/notew.json'
drive_stats_file='json/drive_stats.json'
os_stats_file='json/os_stats.json'
ranking_db = js.loads('{}')
notew_db = js.loads('{}')
drive_stats_db = js.loads('{}')
os_stats_db = js.loads('{}')



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
            if drive_db[drive_type]['size'] in drive_stats_db[drive_db[drive_type]['vendor']]:
                # Add number of drives
                drive_stats_db[drive_db[drive_type]['vendor']][drive_db[drive_type]['size']] +=  system_db[ranked_system]['drives'][drive_type]
            else:
                # Add number of drives
                drive_stats_db[drive_db[drive_type]['vendor']][drive_db[drive_type]['size']] = system_db[ranked_system]['drives'][drive_type]
        else:
            # Add number of drives
            drive_stats_db[drive_db[drive_type]['vendor']] = {}
            # Set to number of drives of that size
            drive_stats_db[drive_db[drive_type]['vendor']][drive_db[drive_type]['size']] = system_db[ranked_system]['drives'][drive_type]

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


ranking_data=open(ranking_file, 'w')
js.dump(ranking_db,ranking_data,indent=1,sort_keys=True)
ranking_data.close()

notew_data=open(notew_file, 'w')
js.dump(notew_db,notew_data,indent=1,sort_keys=True)
notew_data.close()

drive_stats_data=open(drive_stats_file, 'w')
js.dump(drive_stats_db,drive_stats_data,indent=1)
drive_stats_data.close()

os_stats_data=open(os_stats_file, 'w')
js.dump(os_stats_db,os_stats_data,indent=1)
os_stats_data.close()


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
postNo_sub = '%postNo%'
rankingpoints_sub = '%rp%'
capacity_sub = '%cap%'
nodrives_sub = '%ndr%'
case_sub = '%cs%'
os_sub = '%os%'
stsys_sub = '%stsys%'
rp_bar_sub = '%rp_bar%'
cap_bar_sub = '%cap_bar%'
drvc_bar_sub = '%drvc_bar%'
drvc_bar_sub = '%drvc_bar%'

# Assemble ranking table
rows = ''
for rank in ranking_db.keys():
    row = re.sub(rank_sub,str(rank),template_row)
    row = re.sub(username_sub,ranking_db[rank]['username'],row)
    row = re.sub(postNo_sub,str(ranking_db[rank]['post']),row)
    row = re.sub(rankingpoints_sub,"{:.2f}".format(ranking_db[rank]['ranking_points']),row)
    row = re.sub(capacity_sub,str(ranking_db[rank]['capacity']),row)
    row = re.sub(nodrives_sub,str(ranking_db[rank]['drive_count']),row)
    row = re.sub(case_sub,str(ranking_db[rank]['case']),row)
    row = re.sub(os_sub,str(ranking_db[rank]['os']),row)
    row = re.sub(stsys_sub,str(ranking_db[rank]['storage_sys']),row)
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
drive_heatmap_pattern = '%%%<drive_heatmap>%%%'
template_footer = re.sub(drive_heatmap_pattern,drive_heatmap,template_footer)
drive_heatmap_contribs_pattern = '%%%<drive_heatmap_contribs>%%%'
template_footer = re.sub(drive_heatmap_contribs_pattern,drive_heatmap_contribs,template_footer)
os_heatmap_pattern = '%%%<os_heatmap>%%%'
template_footer = re.sub(os_heatmap_pattern,os_heatmap,template_footer)
os_heatmap_caps_pattern = '%%%<os_heatmap_caps>%%%'
template_footer = re.sub(os_heatmap_caps_pattern,os_heatmap_caps,template_footer)
os_heatmap_drvc_pattern = '%%%<os_heatmap_drvc>%%%'
template_footer = re.sub(os_heatmap_drvc_pattern,os_heatmap_drvc,template_footer)
total_dr_sub = '%tdr%'
total_cp_sub = '%tc%'
template_footer = re.sub(total_dr_sub,str(total_drives),template_footer)
template_footer = re.sub(total_cp_sub,str(total_capacity),template_footer)

html_file = open('rankings.html','w')
html_file.write(template_header)
html_file.write(rows)
html_file.write(template_footer)
html_file.close()


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
plot_data_drive_counts = []   # list of drive count per vendor and capacity
plot_data_drive_contribs = [] # list of contribution to total by vendor and capacity
for vendor in drive_stats_db.keys():
    for capacity in drive_stats_db[vendor].keys():
        plot_data_drive_vendors.append(vendor)
        plot_data_drive_caps.append(capacity)
        plot_data_drive_counts.append(drive_stats_db[vendor][capacity])
        plot_data_drive_contribs.append(drive_stats_db[vendor][capacity] * capacity)

df['Vendor'] = plot_data_drive_vendors
df['Capacity (TB)'] = plot_data_drive_caps
df['Count'] = plot_data_drive_counts
df['Contribution'] = plot_data_drive_contribs
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
cax = plt.gcf().axes[-1]
cax.tick_params(labelsize=12)
plt.savefig(drive_heatmap_contribs_path)
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
