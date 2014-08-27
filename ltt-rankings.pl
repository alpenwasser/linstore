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


my $SYSTEMS_FILE 		= File::Spec->catfile("json","systems.json");
my $HDD_TYPES_FILE 		= File::Spec->catfile("json","hdd_types.json");
my $CONSTANTS_FILE 		= File::Spec->catfile("json","constants.json");
my $CREDENTIALS_FILE	= File::Spec->catfile("json","credentials.json");


sub main
{
	my $systems_file_path 	= shift;
	my $hdd_file_path		= shift;
	my $constants_path		= shift;
	my $credentials_path	= shift;


	my $systems_ref;
	my $hdd_types_ref;
	my $constants_ref;
	my $credentials_ref;


	$systems_ref 		= read_json($systems_file_path);
	$hdd_types_ref 		= read_json($hdd_file_path);
	$constants_ref 		= read_json($constants_path);
	$credentials_ref 	= read_json($credentials_path);


    # Avoids needing  to configure  the server in  more than
    # one place, but still keeps everything related to it in
    # the same file.
	$constants_ref->{img_server} = $credentials_ref->{img_server};


	my $time = Time::Piece->new();
	$constants_ref->{timestamp} = $time->ymd . "--" . $time->hms("-") . "--";


	calculate_system_capacities($systems_ref,$hdd_types_ref);
	assign_ranks(				$systems_ref,$constants_ref);
	generate_ranking_list(		$systems_ref,$constants_ref);
	generate_list_footer(		$systems_ref,$constants_ref,$hdd_types_ref);


	my ($hdd_counts_by_size_ref,
		$hdd_counts_by_vendor_ref,
		$hdd_comb_cap_by_size_ref,
		$hdd_comb_cap_by_vendor_ref)
		= generate_statistics($systems_ref, $constants_ref, $hdd_types_ref);


	generate_unranked_list(	$systems_ref, $constants_ref);
	generate_abbr_key(		$constants_ref);

	append_img_links($constants_ref);

	print_ranking_list_plot($systems_ref, $constants_ref);

	print_groupings_plots($systems_ref, $constants_ref);


	print_hdd_size_plots(	$constants_ref,
							$hdd_counts_by_size_ref,
							$hdd_comb_cap_by_size_ref);
	print_hdd_vendor_plots(	$constants_ref,
							$hdd_counts_by_vendor_ref,
							$hdd_comb_cap_by_vendor_ref);

	upload_images($constants_ref, $credentials_ref,0);


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
