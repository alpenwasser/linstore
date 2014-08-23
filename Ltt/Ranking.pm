package Ltt::Ranking;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use Data::Dumper;			# for debugging

use Ltt::Statistics;

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw( 
	calculate_system_capacities 
	assign_ranks 
	calculate_system_capacity);

# These are exported by default.
our @EXPORT = qw( assign_ranks );


sub _calculate_ranks
{
	my $systems_ref		= shift;
	my $constants_ref 	= shift;


	my $rank;
	my $capacity_threshold = $constants_ref->{capacity_threshold};

	return 
	{
		map 
		{
			$rank++;

            # For builds with  capacities below the capacity
            # threshold, we  do not assign any  ranks, since
            # they will be in a separate, unranked list.

			$_ => ( $systems_ref->{$_}{system_capacity} < $capacity_threshold)
				? "UNRANKED" : $rank
		}
		sort 
		{
            # Sort first  by storage capacity, then  by post
            # number. Systems with identical capacities will
            # be ranked higher if they were posted earlier.

			$systems_ref->{$b}{system_capacity} 
			<=>
			$systems_ref->{$a}{system_capacity}
			||
			$systems_ref->{$a}{post} 
			<=> 
			$systems_ref->{$b}{post}
		 } keys %{ $systems_ref }
	};
}


sub assign_ranks
{
	my $systems_ref		= shift;
	my $constants_ref	= shift;


	my $ranks_ref = _calculate_ranks($systems_ref,$constants_ref);


	for my $system_id (keys %{ $systems_ref } )
	{
		$systems_ref->{$system_id}{rank} = $ranks_ref->{$system_id};
	}
}


1;
