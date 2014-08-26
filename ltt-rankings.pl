#!/usr/bin/perl -CS

use warnings;
use strict;
use 5.10.0;

use JSON::XS;
use File::Spec;

use Ltt::Json;
use Ltt::Ranking;
use Ltt::Display;
use Ltt::Statistics;
use Ltt::Plotting;

my $SYSTEMS_FILE 		= File::Spec->catfile("json","systems.json");
my $HDD_TYPES_FILE 		= File::Spec->catfile("json","hdd_types.json");
my $CONSTANTS_FILE 		= File::Spec->catfile("json","constants.json");
my $OUTPUT_FILE 		= "ltt-rankings.txt";

my $SYSTEMS_HASH_REF 	= {};


sub main
{
	my $systems_file_path 	= shift;
	my $hdd_file_path		= shift;
	my $constants_path		= shift;
	my $output_file_path	= shift;


	my $systems_ref;
	my $hdd_types_ref;
	my $constants_ref;


	$systems_ref 	= read_json($systems_file_path);
	$hdd_types_ref 	= read_json($hdd_file_path);
	$constants_ref 	= read_json($constants_path);


	calculate_system_capacities($systems_ref, $hdd_types_ref);
	assign_ranks(			$systems_ref, $constants_ref);
	generate_ranking_list(	$systems_ref, $constants_ref);
	generate_list_footer(	$systems_ref, $constants_ref, $hdd_types_ref);


	my ($hdd_counts_by_size_ref,
		$hdd_counts_by_vendor_ref,
		$hdd_comb_cap_by_size_ref,
		$hdd_comb_cap_by_vendor_ref)
		= generate_statistics($systems_ref, $constants_ref, $hdd_types_ref);


	generate_unranked_list(	$systems_ref, $constants_ref);
	generate_abbr_key(		$constants_ref);

	print_ranking_list_plot($systems_ref, $constants_ref);

	print_groupings_plots($systems_ref, $constants_ref);

	print_hdd_size_plots(	$constants_ref,
							$hdd_counts_by_size_ref,
							$hdd_comb_cap_by_size_ref);
	print_hdd_vendor_plots(	$constants_ref,
							$hdd_counts_by_vendor_ref,
							$hdd_comb_cap_by_vendor_ref);



	return 0;
}


exit(
	main(
		$SYSTEMS_FILE,
		$HDD_TYPES_FILE,
		$CONSTANTS_FILE,
		$OUTPUT_FILE
	)
);
