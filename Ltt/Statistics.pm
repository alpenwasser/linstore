package Ltt::Statistics;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use List::Util qw(max sum reduce);
use Data::Dumper;			# for debugging

use Ltt::Strings;

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw(
	get_total_capacity
	calculate_system_capacity
	calculate_system_capacities
	get_arithmetic_mean
	get_median
	get_mode
	get_grouped_stats
	get_total_drives
	get_avg_drives
	get_avg_drive_cap
	get_med_drive_cap
	get_hdd_counts_by_size
	get_hdd_comb_cap_by_size
	get_hdd_perc_count_by_size
	get_hdd_perc_cap_by_size
	get_hdd_counts_and_caps_by_vendor
	get_hdd_perc_count_by_vendor
	get_hdd_perc_cap_by_vendor
	);

# These are exported by default.
our @EXPORT = qw(
	get_total_capacity
	calculate_system_capacity
	calculate_system_capacities
	get_arithmetic_mean
	get_median
	get_mode
	get_grouped_stats
	get_total_drives
	get_avg_drives
	get_avg_drive_cap
	get_med_drive_cap
	get_hdd_counts_by_size
	get_hdd_comb_cap_by_size
	get_hdd_perc_count_by_size
	get_hdd_perc_cap_by_size
	get_hdd_counts_and_caps_by_vendor
	get_hdd_perc_count_by_vendor
	get_hdd_perc_cap_by_vendor
	);


sub _calculate_hdd_type_contribution
{
	my $system_id		= shift;
	my $hdd 			= shift;
	my $systems_ref 	= shift;
	my $hdd_types_ref 	= shift;


    # Capacity per HDD times number  of HDDs of this type in
    # system:

	return $hdd_types_ref->{$hdd}{size} 
	* $systems_ref->{$system_id}{hdds}{$hdd};
}


sub calculate_system_capacity
{
	my $system_id		= shift;
	my $systems_ref		= shift;
	my $hdd_types_ref	= shift;

	for my $hdd (keys %{ $systems_ref->{$system_id}{hdds} })
	{
		$systems_ref->{$system_id}{system_capacity}
			+= _calculate_hdd_type_contribution(
				$system_id,
				$hdd,
				$systems_ref,
				$hdd_types_ref);
	}
}


sub calculate_system_capacities
{
	my $systems_ref		= shift;
	my $hdd_types_ref	= shift;

    # Creates  field {system_capacity}  in  system hash  and
    # assigns total system storage capacity as its value.
    #
    # NOTE:    {system_capacity}   is    the   automatically
    # calculated  system capacity,  {capacity} is  the value
    # entered manually, if one is entered.


	calculate_system_capacity($_,$systems_ref,$hdd_types_ref) 
		for keys %{ $systems_ref };
}


sub get_total_capacity
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;
	my $hdd_types_ref	= shift;

	my $total_capacity;


	for (keys %{ $systems_ref })
	{
        # If, for  whatever reason, the system  capacity has
        # not yet been calculated, do so now.
		calculate_system_capacity($_,$systems_ref, $hdd_types_ref) 
			unless ($systems_ref->{$_}{system_capacity});

        # Only  count those  systems towards  total capacity
        # which  have  more  than  the  required  amount  of
        # storage capacity.
		$total_capacity += $systems_ref->{$_}{system_capacity} 
			unless (
				$systems_ref->{$_}{system_capacity} 
				< 
				$constants_ref->{capacity_threshold});
	}


	# Round to tenths, append ".0" if integer:
	return format_number($total_capacity);
}


sub get_arithmetic_mean
{
	my $list_ref	= shift;

	return sum(@{ $list_ref }) / scalar(@{ $list_ref });	
}


sub get_median
{
    # Takes a  reference to an  unsorted list in  array form
    # and returns median value.

	my $list_ref = shift;

	my $median;

	my $number_of_entries	= scalar(@{ $list_ref });
	my @sorted_list 		= sort { $a <=> $b } @{ $list_ref };


	if ($number_of_entries % 2 == 1)
	{
		# Odd number of elements => central element is median.

		use integer;
		my $median_index = $number_of_entries / 2;
		return $sorted_list[$median_index];

	} else {
		# Even number of elements => arithmetic mean between
		# two central elements is median.

		# Need to adjust because index of array starts at 0,
		# naturally.
		my $lower_median_index = $number_of_entries / 2 - 1;
		my $upper_median_index = $lower_median_index + 1;

		return ($sorted_list[$lower_median_index]
			+ $sorted_list[$upper_median_index]) / 2;
	}
}


sub get_mode
{
    # Gets mode and number of unique entries in an unordered
    # list.


	my $list_ref = shift;
	my %counts;
	my $highest_count;
	my %result;


    # Count each entry's number of occurrences
	$counts{$_}++ for @{ $list_ref };
	$highest_count = max(values %counts);

    # Reduce to mode(s), the mode  need not be unique, hence
    # a hash  instead of a  single value.  Form  of %result:
    # capacity => number of occurrences.

	%result = map { $_ => $counts{$_} } 
		grep { $counts{$_} == $highest_count } keys %counts;
	

    # Two special values. When outputting the mode hash, may
    # need to be extracted and deleted first.
	$result{number_of_unique_capacities} = scalar(keys %counts);
	$result{number_of_occurrences} = $highest_count;

	return \%result;
}


sub get_grouped_stats
{
    # Reference to list of values which are to be grouped.
	my $list_ref 		= shift; 

    # Reference to hash of form: "X ≤ value < Y" => "20"
	my $groups_ref		= shift;

	# Interval value to use for groupings
	my $interval_range	= shift;


	for my $range (keys %{ $groups_ref })
	{
		my $upper_limit = $groups_ref->{$range};

		my @capacities_in_range = grep { 
			$_ >= $upper_limit - $interval_range && $_ < $upper_limit } 
			@{ $list_ref };
 
		$groups_ref->{$range} = scalar(@capacities_in_range);
	}
}


sub get_total_drives
{
	my $hdd_configs_ref = shift;
	# %{ $hdd_configs_ref }: 
	# { 
	#     system_1 => { hdd_type_1 => count, hdd_type_2 => count ... },
	#     system_2 => { hdd_type_1 => count, hdd_type_2 => count ... } 
	#     ...
	# }

	my $total_drive_count;

	for my $system_id (keys %{ $hdd_configs_ref })
	{
		$total_drive_count 
			+= $hdd_configs_ref->{$system_id}{$_} 
			for (keys %{ $hdd_configs_ref->{$system_id} });
	}

	return $total_drive_count;
}


sub get_avg_drives
{
	my $systems_ref		= shift;
	my $total_drives	= shift;

	return format_number(
		$total_drives / scalar(grep {$systems_ref->{$_}{rank} ne "UNRANKED" }
		keys %{ $systems_ref }));
}


sub get_avg_drive_cap
{
	# $_[0]: total number of drives
	# $_[1]: total combined capacity
	return format_number($_[1] / $_[0]);
}


sub get_med_drive_cap
{
	# Returns median drive capacity.
	#
	# %{ $hdd_configs_ref }: 
	# { 
	#     system_1 => { hdd_type_1 => count, hdd_type_2 => count ... },
	#     system_2 => { hdd_type_1 => count, hdd_type_2 => count ... } 
	#     ...
	# }

	my $hdd_configs_ref	= shift;
	my $hdd_types_ref	= shift;

    # Array  with   one  entry   for  each   individual  HDD
    # consisting of its capacity.
	my @hdds_unsorted;

	for my $system_id (keys %{ $hdd_configs_ref })
	{
		# For all systems...
		for my $hdd_type (keys %{ $hdd_configs_ref->{$system_id} })
		{
			# ...iterate over all HDD types present in system...
			for (1..$hdd_configs_ref->{$system_id}{$hdd_type})
			{
                # ...as well  as their  count, and  make one
                # entry  in  @hdds_unsorted   for  each  HDD
                # consisting of its capacity.
				push @hdds_unsorted, $hdd_types_ref->{$hdd_type}{size};
			}
		}
	}

	return get_median(\@hdds_unsorted);
}


sub get_hdd_counts_by_size
{
	my $hdd_configs_ref	= shift;
	my $hdd_types_ref	= shift;

    # NOTE: HDD  capacities are  formatted to  two decimals,
    # where necessary with trailing zeroes.

	my %counts;

	for my $system_id (keys %{ $hdd_configs_ref })
	{
		for my $hdd_type (keys %{ $hdd_configs_ref->{$system_id} })
		{
			for (1..$hdd_configs_ref->{$system_id}{$hdd_type})
			{
				$counts{ 
					format_hdd_capacity($hdd_types_ref->{ $hdd_type }{size}) 
					}++;
			}
		}
	}

	return \%counts;
}


sub get_hdd_counts_and_caps_by_vendor
{
	my $hdd_configs_ref	= shift;
	my $hdd_types_ref	= shift;


	my %counts;
	my %combined_capacities;

	for my $system_id (keys %{ $hdd_configs_ref })
	{
		for my $hdd_type (keys %{ $hdd_configs_ref->{$system_id} })
		{
			for (1..$hdd_configs_ref->{$system_id}{$hdd_type})
			{
				$counts{ 			  $hdd_types_ref->{ $hdd_type }{vendor}}++;
				$combined_capacities{ $hdd_types_ref->{ $hdd_type }{vendor}}
					+= $hdd_types_ref->{ $hdd_type }{size};
			}
		}
	}

	my $max_vendor_length = get_max_elem_length( [ keys %counts ] );

	%counts = map 
	{ 
		pad_right($_,$max_vendor_length,0) => $counts{$_} 
	} keys %counts;

	%combined_capacities = map 
	{ 
		pad_right($_,$max_vendor_length,0) 
			=> format_number($combined_capacities{$_})
	} keys %combined_capacities;

	return (\%counts,\%combined_capacities);
}


sub get_hdd_comb_cap_by_size
{
	my $hdd_counts_ref = shift;
	# size => count

	return { 
		map { $_ => format_number($_ * $hdd_counts_ref->{$_}) } 
			keys %{ $hdd_counts_ref }
	};
}


sub get_hdd_perc_count_by_size
{
	my $hdd_counts_ref = shift;
	# size => count

	my $total_count = sum(values %{ $hdd_counts_ref });

	return {
		map {$_ => format_percentage($hdd_counts_ref->{$_} / $total_count )}
			keys %{ $hdd_counts_ref }
	};
}


sub get_hdd_perc_count_by_vendor
{
	my $hdd_counts_ref = shift;
	# vendor => count

	my $total_count = sum(values %{ $hdd_counts_ref });

	return {
		map {$_ => format_percentage($hdd_counts_ref->{$_} / $total_count )}
			keys %{ $hdd_counts_ref }
	};
}


sub get_hdd_perc_cap_by_size
{
	my $hdd_comb_cap_ref 		= shift;
	# size => combined capacity for size
	
	my $total_combined_capacity = shift;
	
	return {
		map { $_ => format_percentage(
				$hdd_comb_cap_ref->{$_} / $total_combined_capacity) 
			} keys %{ $hdd_comb_cap_ref }
	};
}


sub get_hdd_perc_cap_by_vendor
{
	my $hdd_comb_cap_ref 		= shift;
	# vendor => combined capacity for vendor
	
	my $total_combined_capacity = shift;
	
	return {
		map { $_ => format_percentage(
				$hdd_comb_cap_ref->{$_} / $total_combined_capacity)
			} keys %{ $hdd_comb_cap_ref }
	};
}

1;
