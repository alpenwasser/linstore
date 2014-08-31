#!/usr/bin/perl -CS

use warnings;
use strict;
use 5.10.0;

use JSON::XS;
use File::Spec;
use Time::Piece;

use Ltt::Json;
use Ltt::Ranking;
use Ltt::Display;
use Ltt::Statistics;
use Ltt::Plotting;
use Ltt::Upload;
use Ltt::Writer;
use Ltt::Imaging;
use Ltt::Digester;


my $SYSTEMS_FILE	= File::Spec->catfile("json","systems.json");
my $HDD_TYPES_FILE	= File::Spec->catfile("json","hdd_types.json");
my $CONSTANTS_FILE	= File::Spec->catfile("json","constants.json");
my $CREDENTIALS_FILE	= File::Spec->catfile("json","credentials.json");


sub main
{
	my $systems_file_path	= shift;
	my $hdd_file_path	= shift;
	my $constants_path	= shift;
	my $credentials_path	= shift;


	# Grab configuration and data.
	my $systems_ref		= read_json($systems_file_path);
	my $hdd_types_ref	= read_json($hdd_file_path);
	my $constants_ref	= read_json($constants_path);

	# If there  is no credentials file,  the read_json()
	# function will return 0.
	my $credentials_ref	= read_json($credentials_path);


	# Avoids  needing to  configure the  server in	more
	# than one place, but still keeps everything related
	# to it in the same file.
	# If  no  credentials  file  is  present,  we  leave
	# the default value $constants_ref->{img_server} for
	# later manual edit by user.
	$constants_ref->{img_server} = $credentials_ref->{img_server}
		if ($credentials_ref && $credentials_ref->{img_server});


	# Generate  a timestamp  for  the plot	images. This
	# prevents us from  overwriting existing plot images
	# on the server with the newer ones.
	my $time = Time::Piece->new();
	$constants_ref->{timestamp}	= $time->ymd
					. "--" . $time->hms("-") . "--";


	# Calculate  a SHA1  digest for  the current  system
	# configuration.  This is  then watermarked onto the
	# plot images. The purpose of this is that it can be
	# determined  which graph  images resulted  from the
	# same systems configuration.
	# The order in which the  elements are stored in the
	# systems.json file  is irrelevant,  so long  as the
	# fundamental data structure is  the same in content
	# (this  corresponds to  Perl's handling  of element
	# order within	a hash, which is  not guaranteed and
	# will vary between program runs).
	$constants_ref->{systems_digest}
		= get_hash_digest($systems_ref);


	# The  total  storage  capacity of  each  system  is
	# calculated based on its HDD configuration.
	calculate_system_capacities($systems_ref,$hdd_types_ref);


	# Ranks are  assigned based on total  system storage
	# capacity  in	 first	priority,   ascending,	then
	# based  on post  number (and  hence the  post date)
	# descending.
	assign_ranks($systems_ref,$constants_ref);


	# Generate text for ranking list.
	generate_ranking_list($systems_ref,$constants_ref);
	generate_list_footer($systems_ref,$constants_ref,$hdd_types_ref);


	# Generate data for HDD statistics plots.
	my (
		$hdd_counts_by_size_ref,
		$hdd_counts_by_vendor_ref,
		$hdd_comb_cap_by_size_ref,
		$hdd_comb_cap_by_vendor_ref
	    ) = generate_statistics(
		$systems_ref,
		$constants_ref,
		$hdd_types_ref
		);


	# The  systems	which  do  not	reach  the  capacity
	# threshold are put into a second list.
	generate_unranked_list($systems_ref,	$constants_ref);

	# The explanations for the abbreviations used in the
	# ranked and unranked list.
	generate_abbr_key(			$constants_ref);


	# Append the  links to the plot images	to the post.
	append_img_links($constants_ref);


	# Plot of systems ranked by  same criteria as in the
	# main ranking list.
	print_ranking_list_plot($systems_ref,	$constants_ref);


	# Plots of systems grouped by total system capacity.
	print_groupings_plots(	$systems_ref,	$constants_ref);


	print_hdd_size_plots(	$constants_ref,
				$hdd_counts_by_size_ref,
				$hdd_comb_cap_by_size_ref);

	print_hdd_vendor_plots(	$constants_ref,
				$hdd_counts_by_vendor_ref,
				$hdd_comb_cap_by_vendor_ref);


	# Upload   images  to	FTP  server,   specified  in
	# json/credentials.json.
	upload_images($constants_ref, $credentials_ref,0)
		if($credentials_ref);


	# Write  to output  file. This is  what needs  to be
	# copied into the forum post.
	write_output(	$constants_ref->{output_data},
			$constants_ref->{output_file});


	return 0;
}





exit(
	main(
		$SYSTEMS_FILE,
		$HDD_TYPES_FILE,
		$CONSTANTS_FILE,
		$CREDENTIALS_FILE
	)
);
