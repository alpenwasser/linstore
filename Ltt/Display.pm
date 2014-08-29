package Ltt::Display;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use List::Util qw(max sum reduce );
use Data::Dumper;			# for debugging
use Time::Piece;

use Ltt::Strings;
use Ltt::Statistics;
use Ltt::Plotting;

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw( 
	generate_ranking_list 
	generate_list_footer 
	generate_statistics 
	generate_abbr_key
	generate_unranked_list
	append_img_links
	);

# These are exported by default.
our @EXPORT = qw( 
	generate_ranking_list 
	generate_list_footer 
	generate_statistics 
	generate_abbr_key
	generate_unranked_list
	append_img_links
	);


sub _prepare_ranks
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;

	my $rank_length = get_max_rank_length($systems_ref);

	# Ranks get padded on left for the units to line up.
	pad_ranks($systems_ref,$rank_length);

	pad_field_right(
		$systems_ref,
		"padded_rank",
		$rank_length,
		$constants_ref->{after_rank_padding});
}


sub _prepare_usernames
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;


	# For the  usernames, we  need the username  and the
	# padding to  its right in separate  strings because
	# we do  not want  to make the	padding part  of the
	# hyperlink from [post=...]username[/post].

	my $username_length 
		= get_max_field_length($systems_ref,"username");


	pad_field_right(
		$systems_ref,
		"username",
		$username_length,
		$constants_ref->{after_username_padding});


	separate_padding(
		$systems_ref,
		"username");
}


sub _prepare_capacities
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;


	# Capacities are  first rounded and appended  with a
	# trailing ".0"  if they  are integers,  then padded
	# from the left for the units to line up properly.

	format_capacities($systems_ref);
	my $capacity_length 
		= get_max_field_length(	$systems_ref,
					"formatted_capacity");

	pad_field_left(
		$systems_ref,
		"formatted_capacity",
		$capacity_length,
		$constants_ref->{before_capacity_padding});
}


sub _prepare_enclosures
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;


	my $enclosure_length 
		= get_max_field_length(	$systems_ref,"case");

	pad_field_right(
		$systems_ref,
		"case",
		$enclosure_length,
		$constants_ref->{after_enclosure_padding});

	pad_field_left(
		$systems_ref,
		"padded_case",
		$enclosure_length,
		$constants_ref->{before_enclosure_padding});
}


sub _prepare_os_storage_sys
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;


	# Combine  the OS  and	storage  system fields	into
	# one  to  keep the  line  length  short enough  for
	# acceptable formatting on smaller screens.

	concat_fields(
		$systems_ref,
		"os_storage_sys",
		[ "os","storage_sys" ]);

	my $os_storage_length
		= get_max_field_length($systems_ref,"os_storage_sys");

	pad_field_right(
		$systems_ref,
		"os_storage_sys",
		$os_storage_length,
		$constants_ref->{after_os_stor_padding});
}


sub _print_title
{
	my $constants_ref = shift;

	$constants_ref->{output_data}
		.=$constants_ref->{bold_open}
		. $constants_ref->{font_large_open}
		. $constants_ref->{global_title}
		. $constants_ref->{font_size_close}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline}
		. $constants_ref->{horiz_separator}
		. $constants_ref->{newline};
}


sub _print_ranking_list
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;

	$constants_ref->{output_data} 
		.= $_ . $constants_ref->{newline} for
		map
		{
			# Rank has been  padded twice, hence the
			# "padded_padded_" prefix.
			my $row = $systems_ref->{$_}{padded_padded_rank}
				. $constants_ref->{post_open}
				. $systems_ref->{$_}{post}
				. $constants_ref->{post_mid}
				. $systems_ref->{$_}{username}
				. $constants_ref->{post_close}
				. $systems_ref->{$_}{username_padding}
				. $constants_ref->{bold_open}
				. $systems_ref->{$_}{padded_formatted_capacity}
				. $constants_ref->{capacity_unit}
				. $constants_ref->{bold_close}
				. $systems_ref->{$_}{padded_padded_case}
				. $systems_ref->{$_}{padded_os_storage_sys};

			# The notes field may  or may not be
			# defined...
			$row .= (" " x $constants_ref->{before_notes_padding})
				. $systems_ref->{$_}{notes} 
				if ($systems_ref->{$_}{notes});

			$row
		}
		sort
		{
			# The	ranks	have  already	been
			# determined  at this  point by  the
			# Ranking module  and are  stored in
			# the {rank} field.

			$systems_ref->{$a}{rank}
			<=>
			$systems_ref->{$b}{rank}
		}
		grep
		{	# Omit unranked systems:
			$systems_ref->{$_}{rank} ne "UNRANKED"
		}
		keys %{ $systems_ref };
}




sub generate_ranking_list
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;

	_prepare_ranks(		$systems_ref, $constants_ref);
	_prepare_usernames(	$systems_ref, $constants_ref);
	_prepare_capacities(	$systems_ref, $constants_ref);
	_prepare_enclosures(	$systems_ref, $constants_ref);
	_prepare_os_storage_sys($systems_ref, $constants_ref);

	_print_title($constants_ref);
	_print_ranking_list($systems_ref, $constants_ref);
}


sub _print_total_capacity
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;

	# Prints  the  total   storage	capacity  below  the
	# ranking list.
	# At this point,  total_combined_capacity should not
	# yet have been  calculated, but if it	has been and
	# is already stored, don't recalculate.

	$constants_ref->{total_combined_capacity} = (
		($constants_ref->{total_combined_capacity}) 
		? 
		$constants_ref->{total_combined_capacity}
		: 
		get_total_capacity($systems_ref, $constants_ref)
	);

	$constants_ref->{output_data} 
		.=$constants_ref->{newline}
		. $constants_ref->{horiz_separator}
		. $constants_ref->{bold_open}
		. $constants_ref->{font_medium_open}
		. $constants_ref->{total_capacity_note}
		. $constants_ref->{total_combined_capacity}
		. $constants_ref->{capacity_unit}
		. $constants_ref->{font_size_close}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline}
		. $constants_ref->{horiz_separator}
		. $constants_ref->{newline};
}


sub _print_timestamp_note
{
	my $constants_ref	= shift;

	# Prints  message  stating  the date  on  which  the
	# ranking list was last update.
	my $time = Time::Piece->new();

	$constants_ref->{output_data} 
		.=$constants_ref->{priority_note}
		. $constants_ref->{newline}
		. $constants_ref->{last_updated_note}
		. $time->year() 
		. '-' 
		. uc($time->monname()) 
		. '-' 
		. $time->mday()
		. $constants_ref->{newline}
		. $constants_ref->{newline}
		. $constants_ref->{newline};
}


sub generate_list_footer
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;
	my $hdd_types_ref	= shift;

	# Prints  total storage  capacity and  timestamp for
	# current date.
	_print_total_capacity(	$systems_ref,
				$constants_ref,
				$hdd_types_ref);
	_print_timestamp_note(	$constants_ref);
}


sub _prepare_summary_titles
{
	my $constants_ref	= shift;
	my $titles_ref		= shift;
	my $extra_padding	= shift;


	# Prepares  correctly formatted  category names  for
	# summary statistics section.
	my @length_list;

	push @length_list, length for %{ $titles_ref };
	my $max_field_length = max(@length_list);


	%{ $titles_ref } = 	
		map
		{ 
			$_ 
			=> 
			pad_right(	$titles_ref->{$_},
					$max_field_length,
					$extra_padding)
		} keys %{ $titles_ref };
}


sub _prepare_system_summary_stats
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;


	my $capacities_ref = 
	[
		map   { $systems_ref->{$_}{system_capacity} }
		grep  { $systems_ref->{$_}{rank} ne "UNRANKED" }
		keys %{ $systems_ref } 
	];


	# Make sure keys for  %{ $titles_ref } are identical
	# to the corresponding keys in %{ $constants_ref }.
	my $titles_ref = 
	{
		"mean_sys_capacity_title" 	
		=> $constants_ref->{mean_sys_capacity_title},

		"median_sys_capacity_title"	
		=> $constants_ref->{median_sys_capacity_title},

		"mode_sys_capacity_title" 	
		=> $constants_ref->{mode_sys_capacity_title},

		"no_of_uniq_caps" 			
		=> $constants_ref->{no_of_uniq_caps}
	};


	_prepare_summary_titles(
		$constants_ref, 
		$titles_ref, 
		$constants_ref->{sys_summary_extra_padding});


	$constants_ref->{$_} = $titles_ref->{$_} 
		for keys %{ $titles_ref };


	return (
		format_number(get_arithmetic_mean($capacities_ref)),
		format_number(get_median($capacities_ref)),
		get_mode($capacities_ref),
	);
}


sub _prepare_grouped_system_stats
{
	my $systems_ref		= shift;
	my $groups_ref		= shift;
	my $interval_range	= shift;

	get_grouped_stats(
		[
			map   { $systems_ref->{$_}{system_capacity} }
			grep  { $systems_ref->{$_}{rank} ne "UNRANKED" }
			keys %{ $systems_ref }
		],
		$groups_ref,
		$interval_range);
}


sub _prepare_hdd_summary_stats
{
	my $systems_ref		= shift;
	my $hdd_types_ref	= shift;
	my $constants_ref	= shift;


	# Gather HDD configs for each system which meets the
	# minimum capacity requirement:
	my $hdd_configs_ref = 
	{
		map   { $_ => $systems_ref->{$_}{hdds} }
		grep  { $systems_ref->{$_}{rank} ne "UNRANKED" }
		keys %{ $systems_ref } 
	};


	# Make sure keys for  %{ $titles_ref } are identical
	# to the corresponding keys in %{ $constants_ref }.
	my $titles_ref = 
	{
		"total_drives"
		=> $constants_ref->{total_drives},

		"avg_dr_per_system"
		=> $constants_ref->{avg_dr_per_system},

		"total_comb_cap"
		=> $constants_ref->{total_comb_cap},

		"avg_dr_cap"
		=> $constants_ref->{avg_dr_cap},

		"med_dr_cap"
		=> $constants_ref->{med_dr_cap}
	};


	_prepare_summary_titles(
		$constants_ref, 
		$titles_ref, 
		$constants_ref->{hdd_summary_extra_padding});


	# Write   prepared  summary   titles   back  to   %{
	# $constants_ref }
	$constants_ref->{$_} 
		= $titles_ref->{$_} for keys %{ $titles_ref };


	my $total_drives = get_total_drives($hdd_configs_ref);
	my $avg_drives_per_system 
		= get_avg_drives($systems_ref,$total_drives);


	# The total  combined capacity should at  this point
	# already  have   been	calculated  and   stored  in
	# {total_combined_capacity},  but  if  for  whatever
	# reason that  is not the case,  calculate and store
	# it now.
	$constants_ref->{total_combined_capacity} = (
		($constants_ref->{total_combined_capacity}) 
		? 
		$constants_ref->{total_combined_capacity}
		: 
		get_total_capacity($systems_ref, $constants_ref)
	);

	my $avg_drive_cap 
		= get_avg_drive_cap(
			$total_drives,
			$constants_ref->{total_combined_capacity}
		);

	my $med_drive_cap 
		= get_med_drive_cap($hdd_configs_ref, $hdd_types_ref);

	return (
		$total_drives,
		$avg_drives_per_system,
		$avg_drive_cap,
		$med_drive_cap,
		$hdd_configs_ref
	);
}


sub _prepare_hdd_size_stats
{
	my $systems_ref		= shift;
	my $hdd_types_ref	= shift;
	my $hdd_configs_ref	= shift;
	my $constants_ref	= shift;


	my $counts_ref	
		= get_hdd_counts_by_size(
			$hdd_configs_ref,
			$hdd_types_ref
		);

	my $sums_ref  	= get_hdd_comb_cap_by_size($counts_ref);


	return (
		$counts_ref,
		$sums_ref,
		get_hdd_perc_count_by_size($counts_ref),
		get_hdd_perc_cap_by_size(
			$sums_ref,
			$constants_ref->{total_combined_capacity}
		)
	);
}


sub _prepare_hdd_vendor_stats
{
	my $systems_ref		= shift;
	my $hdd_types_ref	= shift;
	my $hdd_configs_ref	= shift;
	my $constants_ref	= shift;


	my ($counts_ref, $sums_ref)	
		= get_hdd_counts_and_caps_by_vendor(
			$hdd_configs_ref,
			$hdd_types_ref
		);


	return (
		$counts_ref,
		$sums_ref,
		get_hdd_perc_count_by_vendor($counts_ref),
		get_hdd_perc_cap_by_vendor(	
			$sums_ref,
			$constants_ref->{total_combined_capacity}
		)
	);
}


sub _print_system_summary_stats
{
	my $mean_capacity		= shift;
	my $median_capacity		= shift;
	my $mode_ref			= shift;
	my $constants_ref		= shift;


	my $number_of_unique_capacities 
		= $mode_ref->{number_of_unique_capacities};
	my $number_of_occurrences 
		= $mode_ref->{number_of_occurrences};


	# Remove values which are not actually modes.
	delete $mode_ref->{number_of_unique_capacities};
	delete $mode_ref->{number_of_occurrences};
	my @mode_capacities = keys %{ $mode_ref };


	$constants_ref->{output_data} 
		.=$constants_ref->{font_medium_open}
		. $constants_ref->{bold_open}
		. $constants_ref->{stats_title}
		. $constants_ref->{bold_close}
		. $constants_ref->{font_size_close}
		. $constants_ref->{newline}
		. $constants_ref->{horiz_separator}
		. $constants_ref->{newline}
		. $constants_ref->{bold_open}
		. $constants_ref->{stats_system_summary_title}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline}
		. $constants_ref->{mean_sys_capacity_title}
		. $mean_capacity
		. $constants_ref->{capacity_unit}
		. $constants_ref->{newline}
		. $constants_ref->{median_sys_capacity_title}
		. $median_capacity
		. $constants_ref->{capacity_unit}
		. $constants_ref->{newline}
		. $constants_ref->{mode_sys_capacity_title};


	my $i;
	for (sort @mode_capacities)
	{
		# If several capacities are  modes, output them all,
		# separated by comma and space.
		$i++;
		$constants_ref->{output_data} .= format_number($_)
			. $constants_ref->{capacity_unit}
			. (($i == scalar(@mode_capacities)) ? "" : ", ");
	}


	$constants_ref->{output_data} 
		.=" ("
		. $constants_ref->{no_of_occurrences}
		. $number_of_occurrences
		. ")"
		. $constants_ref->{newline}
		. $constants_ref->{no_of_uniq_caps}
		. "     " # lining up with the end of column
		. $number_of_unique_capacities
		. $constants_ref->{newline};
}


sub _print_system_grouped_stats
{
	my $constants_ref = shift;


	my $max_group_count_length 
		= length(
			max(
				values %{$constants_ref->{capacity_groups}}
			)
		);


	$constants_ref->{output_data} 
		.=$constants_ref->{newline}
		. $constants_ref->{bold_open}
		. $constants_ref->{grouped_caps_title}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline};


	$constants_ref->{output_data} 
		.= $_ 
		. pad_left(
			$constants_ref->{capacity_groups}{$_},
			$max_group_count_length,
			$constants_ref->{capacity_groups_padding}
		)
		. $constants_ref->{newline}
		for sort keys %{ $constants_ref->{capacity_groups} };
}


sub _print_hdd_summary_stats
{
	my $constants_ref	= shift;


	# This	is  why   we  pass  $total_combined_capacity
	# separately,	despite  it   being  stored   in  %{
	# $constants_ref } already.
	my $max_number_length = get_max_elem_length(\@_);


	my (
		$total_drive_count,
		$avg_drives_per_system,
		$total_combined_capacity,
		$avg_drive_cap,
		$med_drive_cap
	) = map { pad_left($_,$max_number_length,0) } @_;


	# Strip superfluous dot  and tenths. Not using int()
	# here because that would also remove the padding we
	# just added.
	$total_drive_count =~ s/\.\d+$//;


	$constants_ref->{output_data} 
		.=$constants_ref->{newline}
		. $constants_ref->{bold_open}
		. $constants_ref->{hdd_summary_title}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline}
		. $constants_ref->{total_drives}
		. $total_drive_count
		. $constants_ref->{newline}
		. $constants_ref->{avg_dr_per_system}
		. $avg_drives_per_system
		. $constants_ref->{newline}
		. $constants_ref->{total_comb_cap}
		. $total_combined_capacity
		. $constants_ref->{newline}
		. $constants_ref->{avg_dr_cap}
		. $avg_drive_cap
		. $constants_ref->{newline}
		. $constants_ref->{med_dr_cap}
		. $med_drive_cap
		. $constants_ref->{newline}
		. $constants_ref->{newline};
}


sub _format_columns
{
	# Get maximum  length of  values for a	hash (passed
	# via reference), then pad  remaining values of hash
	# to same length + column spacing.


	my $col_spacing = shift;


	for my $hash_ref (@_)
	{
		my $max_length
			= get_max_elem_length( 
				[ values %{ $hash_ref } ] 
			);


		$hash_ref 
			= { 
				map 
				{
					$_ 
					=> 
					pad_left(
						$hash_ref->{$_},
						$max_length,
						$col_spacing
					)
				} keys %{ $hash_ref } 
			};

	}
}


sub _print_hdd_size_stats
{

	my $constants_ref				= shift;


	_format_columns(
		$constants_ref->{hdd_table_col_spacing_size},
		@_
	);


	my $hdd_counts_by_size_ref	= shift;
	my $hdd_comb_cap_by_size_ref	= shift;
	my $hdd_perc_count_by_size_ref	= shift;
	my $hdd_perc_cap_by_size_ref	= shift;


	#Row: Capacity, Count, Sum, Percentage of Total (Count, Capacity)

	my %rows;


	# Calculate  Length  difference   for  first  column
	# between HDD stats  by size table and	HDD stats by
	# vendor table. Use result to pad first column of by
	# size table to align its following columns with the
	# by vendor table.
	my $length_difference 
		= abs(
			get_max_elem_length(
				[ keys %{ $hdd_counts_by_size_ref } ]
			)

			+ length($constants_ref->{capacity_unit})

			- get_max_elem_length(
				$constants_ref->{vendor_list}
			)
		);


	%rows = map { 
			$_ . $constants_ref->{capacity_unit} 
			. " " x $length_difference
			=>  
			$hdd_counts_by_size_ref->{$_}
			. " drives     "
			. $hdd_comb_cap_by_size_ref->{$_}
			. $constants_ref->{capacity_unit}
			. "   "
			. $hdd_perc_count_by_size_ref->{$_}
			. "%   "
			. $hdd_perc_cap_by_size_ref->{$_}
			. "%"
		} keys %{ $hdd_counts_by_size_ref };


	$constants_ref->{output_data} 
		.=$constants_ref->{newline}
		. $constants_ref->{bold_open}
		. $constants_ref->{hdd_by_size_title}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline}
		. $constants_ref->{by_size_size_col_title}
		. $constants_ref->{by_size_count_col_title}
		. $constants_ref->{by_size_sum_col_title}
		. $constants_ref->{by_size_perc_col_title}
		. $constants_ref->{newline}
		. $constants_ref->{by_size_perc_count_col_title}
		. $constants_ref->{by_size_perc_cap_col_title}
		. $constants_ref->{newline};
	

	$constants_ref->{output_data} 
		.=$_ 
		. "  " 
		. $rows{$_}
		. $constants_ref->{newline}
		for sort keys %rows;


	$constants_ref->{output_data} 
		.=$constants_ref->{bold_open}
		. $constants_ref->{total_table_footer_vendor}

		. pad_left(
			sum(
				values %{ $hdd_counts_by_size_ref }
			),
			$constants_ref->{total_table_footer_size_padding_col1},
			0
		)

		. " drives"

		. pad_left(
			sum(
				values %{ $hdd_comb_cap_by_size_ref }
			),
			$constants_ref->{total_table_footer_size_padding_col2},0
		)

		. $constants_ref->{capacity_unit}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline};
}


sub _print_hdd_vendor_stats
{
	my $constants_ref	= shift;


	_format_columns(
		$constants_ref->{hdd_table_col_spacing_vendor},
		@_
	);


	my $hdd_counts_by_vendor_ref		= shift;
	my $hdd_comb_cap_by_vendor_ref		= shift;
	my $hdd_perc_count_by_vendor_ref	= shift;
	my $hdd_perc_cap_by_vendor_ref		= shift;


	#Row: Capacity, Count, Sum, Percentage of Total (Count, Capacity)

	my %rows;


	%rows = map { 
			$_
			=>  
			$hdd_counts_by_vendor_ref->{$_}
			. " drives     "
			. $hdd_comb_cap_by_vendor_ref->{$_}
			. $constants_ref->{capacity_unit}
			. "   "
			. $hdd_perc_count_by_vendor_ref->{$_}
			. "%   "
			. $hdd_perc_cap_by_vendor_ref->{$_}
			. "%"
		} keys %{ $hdd_counts_by_vendor_ref };


	$constants_ref->{output_data} 
		.=$constants_ref->{newline}
		. $constants_ref->{bold_open}
		. $constants_ref->{hdd_by_vendor_title}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline}
		. $constants_ref->{by_vendor_vendor_col_title}
		. $constants_ref->{by_vendor_count_col_title}
		. $constants_ref->{by_vendor_sum_col_title}
		. $constants_ref->{by_vendor_perc_col_title}
		. $constants_ref->{newline}
		. $constants_ref->{by_vendor_perc_count_col_title}
		. $constants_ref->{by_vendor_perc_cap_col_title}
		. $constants_ref->{newline};


	$constants_ref->{output_data} 
		.=$_ 
		. "  " 
		. $rows{$_} 
		. $constants_ref->{newline}

		for sort 
		{
			$hdd_counts_by_vendor_ref->{$b} 
			<=>
			$hdd_counts_by_vendor_ref->{$a}
		} keys %{ $hdd_counts_by_vendor_ref };



	$constants_ref->{output_data} 
		.=$constants_ref->{bold_open}
		. $constants_ref->{total_table_footer_vendor}
		. pad_left(
			sum(
				values %{ $hdd_counts_by_vendor_ref }
			),
			$constants_ref->{total_table_footer_vendor_padding_col1},
			0
		)

		. " drives"

		. pad_left(
			sum(
				values %{ $hdd_comb_cap_by_vendor_ref }
			),
			$constants_ref->{total_table_footer_vendor_padding_col2},
			0
		)

		. $constants_ref->{capacity_unit}
		. $constants_ref->{bold_close}
		. $constants_ref->{newline};
}


sub generate_abbr_key
{
	my $constants_ref = shift;

	$constants_ref->{output_data} 
		.=$constants_ref->{newline}
		. $constants_ref->{font_medium_open}
		. $constants_ref->{abbreviations_key_title}
		. $constants_ref->{font_size_close}
		. $constants_ref->{horiz_separator}
		. $constants_ref->{newline};


	$constants_ref->{output_data} 
		.=$_ 
		. $constants_ref->{newline}
		for @{ $constants_ref->{abbreviations_key} };
}


sub generate_statistics
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;
	my $hdd_types_ref	= shift;

	my (
		$mean_sys_capacity,
		$median_sys_capacity,
		$mode_sys_ref
	) = _prepare_system_summary_stats(
		$systems_ref,
		$constants_ref
	);


	_prepare_grouped_system_stats(
		$systems_ref,
		$constants_ref->{capacity_groups},
		$constants_ref->{capacity_range}
	);


	my (
		$total_drive_count,
		$avg_drives_per_system,
		$avg_drive_cap,
		$med_drive_cap,
		$hdd_configs_ref
	) = _prepare_hdd_summary_stats(
		$systems_ref,
		$hdd_types_ref, 
		$constants_ref
	);


	my (
		$hdd_counts_by_size_ref,
		$hdd_comb_cap_by_size_ref,
		$hdd_perc_count_by_size_ref,
		$hdd_perc_cap_by_size_ref
	) = _prepare_hdd_size_stats(	
		$systems_ref, 
		$hdd_types_ref, 
		$hdd_configs_ref, 
		$constants_ref
	);


	my (
		$hdd_counts_by_vendor_ref,
		$hdd_comb_cap_by_vendor_ref,
		$hdd_perc_count_by_vendor_ref,
		$hdd_perc_cap_by_vendor_ref
	) = _prepare_hdd_vendor_stats(
		$systems_ref, 
		$hdd_types_ref, 
		$hdd_configs_ref, 
		$constants_ref
	);


	_print_system_summary_stats(
		$mean_sys_capacity,
		$median_sys_capacity,
		$mode_sys_ref,
		$constants_ref
	);

	_print_system_grouped_stats($constants_ref);


	#  We  concatenate with  {capacity_unit} for  string
	# formatting purposes.
	_print_hdd_summary_stats(
		$constants_ref,
		$total_drive_count, 
		$avg_drives_per_system,
		$constants_ref->{total_combined_capacity} 
			. $constants_ref->{capacity_unit},
		$avg_drive_cap . $constants_ref->{capacity_unit},
		$med_drive_cap . $constants_ref->{capacity_unit}
	);


	_print_hdd_size_stats(	
		$constants_ref,
		$hdd_counts_by_size_ref,
		$hdd_comb_cap_by_size_ref,
		$hdd_perc_count_by_size_ref,
		$hdd_perc_cap_by_size_ref
	);

	_print_hdd_vendor_stats(
		$constants_ref,
		$hdd_counts_by_vendor_ref,
		$hdd_comb_cap_by_vendor_ref,
		$hdd_perc_count_by_vendor_ref,
		$hdd_perc_cap_by_vendor_ref
	);


	return (
		$hdd_counts_by_size_ref,
		$hdd_counts_by_vendor_ref,
		$hdd_comb_cap_by_size_ref,
		$hdd_comb_cap_by_vendor_ref
	);
}


sub generate_unranked_list
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;

	$constants_ref->{output_data} 
		.=$constants_ref->{newline}
		. $constants_ref->{font_medium_open}
		. $constants_ref->{unranked_list_title_1}
		. $constants_ref->{font_size_close}
		. $constants_ref->{unranked_list_title_2}
		. $constants_ref->{horiz_separator}
		. $constants_ref->{newline};


	$constants_ref->{output_data} 
		.= $_ . $constants_ref->{newline} for 
		map 
		{
			my $row = $constants_ref->{post_open}
				. $systems_ref->{$_}{post}
				. $constants_ref->{post_mid}
				. $systems_ref->{$_}{username}
				. $constants_ref->{post_close}
				. $systems_ref->{$_}{username_padding}
				. $constants_ref->{bold_open}
				. $systems_ref->{$_}{padded_formatted_capacity}
				. $constants_ref->{capacity_unit}
				. $constants_ref->{bold_close}
				. $systems_ref->{$_}{padded_padded_case}
				. $systems_ref->{$_}{padded_os_storage_sys};


			# The notes field may  or may not be
			# defined...
			$row .= (" " x $constants_ref->{before_notes_padding})
				. $systems_ref->{$_}{notes} 
				if ($systems_ref->{$_}{notes});

			$row
		}
		grep
		{	# Omit unranked systems: 
			$systems_ref->{$_}{rank} eq "UNRANKED" 
		}
		keys %{ $systems_ref };
}


sub append_img_links
{
	my $constants_ref = shift;

	my @img_links = (
		"\n[img=" 
		. $constants_ref->{img_server}
		. $constants_ref->{timestamp}
		. $constants_ref->{ranking_chart_img}
		. "]",
		"[img=" 
		. $constants_ref->{img_server} 
		. $constants_ref->{timestamp}
		. $constants_ref->{grouped_plot_by_count_img}
		. "]",
		"[img=" 
		. $constants_ref->{img_server} 
		. $constants_ref->{timestamp}
		. $constants_ref->{grouped_plot_by_contrib_img}
		. "]",
		"[img=" 
		. $constants_ref->{img_server}
		. $constants_ref->{timestamp}
		. $constants_ref->{hdd_count_by_size_img}
		. "]",
		"[img=" 
		. $constants_ref->{img_server}
		. $constants_ref->{timestamp}
		. $constants_ref->{hdd_cap_by_size_img}
		. "]",
		"[img=" 
		. $constants_ref->{img_server}
		. $constants_ref->{timestamp}
		. $constants_ref->{hdd_count_by_vendor_img}
		. "]",
		"[img=" 
		. $constants_ref->{img_server}
		. $constants_ref->{timestamp}
		. $constants_ref->{hdd_cap_by_vendor_img}
		. "]",
	);

	$constants_ref->{output_data} 
		.=$_ 
		. $constants_ref->{newline}
		for @img_links;
}


1;
