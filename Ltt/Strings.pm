package Ltt::Strings;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use List::Util qw(max reduce);
use Data::Dumper;			# for debugging

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw(
	pad_left
	pad_right
	reduce_to_padding
	format_number
	format_percentage
	get_max_elem_length
	format_hdd_capacity
	ltrim
	rtrim
	trim
	format_hbar_cap_value
	pad_ranks
	get_max_rank_length
	pad_field_right
	pad_field_left
	get_max_field_length
	separate_padding
	concat_fields
	format_capacities
	sort_string
	);

# These are exported by default.
our @EXPORT = qw(
	pad_left
	pad_right
	reduce_to_padding
	format_number
	format_percentage
	get_max_elem_length
	format_hdd_capacity
	ltrim
	rtrim
	trim
	format_hbar_cap_value
	pad_ranks
	get_max_rank_length
	pad_field_right
	pad_field_left
	get_max_field_length
	separate_padding
	concat_fields
	format_capacities
	sort_string
	);


sub ltrim
{
	my $s = shift;
	$s =~ s/^\s+//;
	return $s
}

sub rtrim
{
	my $s = shift;
	$s =~ s/\s+$//;
	return $s
}

sub trim
{
	my $s = shift;
	$s =~ s/^\s+|\s+$//g;
	return $s
}


sub pad_left
{
	my $string 		= shift;
	my $max_str_length	= shift;
	my $extra_padding 	= shift;

	$string = " "
		. $string
		until (
			length($string)
			==
			$max_str_length + $extra_padding
		);

	return $string;
}


sub pad_right
{
	my $string 		= shift;
	my $max_str_length	= shift;
	my $extra_padding 	= shift;

	$string .= " "
		until (
			length($string)
			==
			$max_str_length + $extra_padding
		);

	return $string;
}


sub reduce_to_padding
{
	my $unpadded_string	= shift;
	my $padded_string	= shift;
	my $padding = $padded_string;

	# Strip actual string from $padding:
	$padding =~ s/$unpadded_string//ig;

	return $padding;
}


sub get_max_rank_length
{
	my $systems_ref	= shift;

	return length(
		max(
			map   { $systems_ref->{$_}{rank} }
			grep  { $systems_ref->{$_}{rank} ne "UNRANKED" }
			keys %{ $systems_ref }
		)
	);
}


sub pad_field_right
{
	my $systems_ref		= shift;
	my $field		= shift;
	my $field_length	= shift;
	my $extra_padding	= shift;


	for my $system_id (keys %{ $systems_ref })
	{
		next unless $systems_ref->{$system_id}{$field};

		$systems_ref->{$system_id}{"padded_" . $field}
			= pad_right(
				$systems_ref->{$system_id}{$field},
				$field_length,
				$extra_padding
			);
	}
}


sub pad_field_left
{
	my $systems_ref		= shift;
	my $field		= shift;
	my $field_length	= shift;
	my $extra_padding	= shift;


	for my $system_id (keys %{ $systems_ref })
	{
		next unless $systems_ref->{$system_id}{$field};

		$systems_ref->{$system_id}{"padded_" . $field}
			= pad_left(
				$systems_ref->{$system_id}{$field},
				$field_length,
				$extra_padding
			);
	}
}


sub get_max_field_length
{
	my $systems_ref	= shift;
	my $field	= shift;

	my $longest_element =
		reduce {
				length($systems_ref->{$a}{$field})
				>
				length($systems_ref->{$b}{$field})
			?
			$a : $b
		} keys %{ $systems_ref };

	return length($systems_ref->{$longest_element}{$field});
}


sub separate_padding
{
	my $systems_ref	= shift;
	my $field	= shift;

	$systems_ref->{$_}{$field . "_padding"}
		= reduce_to_padding(
			$systems_ref->{$_}{$field},
			$systems_ref->{$_}{"padded_" . $field}
		)
		for keys %{ $systems_ref };
}


sub concat_fields
{
	my $systems_ref		= shift;
	my $new_field_name	= shift;
	my $fields_ref		= shift;

	for my $system_id (keys %{ $systems_ref })
	{
		my $concat_string;

		for (@{ $fields_ref })
		{
			# Make sure we don't  add a comma at
			# the beginning of string.
			if ($concat_string)
			{
				$concat_string
					.= ", "
					. $systems_ref->{$system_id}{$_};
			}
			else
			{
				$concat_string
					= $systems_ref->{$system_id}{$_};
			}
		}
		$systems_ref->{$system_id}{$new_field_name}
			= $concat_string;
	}
}


sub format_capacities
{
	my $systems_ref		= shift;


	$systems_ref->{$_}{formatted_capacity}
		= format_number($systems_ref->{$_}{system_capacity})
		for keys %{ $systems_ref };

}


sub pad_ranks
{
	my $systems_ref		= shift;
	my $rank_length		= shift;

	# Add padding  to the  left of	ranks so  that units
	# will align  properly in the final  list. Note that
	# because unranked systems should not have a ranking
	# field printed in the	secondary systems list, they
	# need to be omitted from this process.
	$systems_ref->{$_}{padded_rank}
		= pad_left($systems_ref->{$_}{rank},$rank_length,0)
		for grep { $systems_ref->{$_}{rank} ne "UNRANKED" }
		keys %{ $systems_ref };
}


sub _round_number
{
	my $number = shift;

	# Since we want tenths, we  add in and then remove a
	# factor of  ten.  We also  make sure not to  try to
	# divide  by zero,  and should	the integer  part of
	# $number be zero, we return "0.0".
	return (int(abs(10*$number*2)) == 0)
		? "0.0"
		: int(10*$number + 10*$number/abs(10*$number*2)) / 10;
}


sub get_max_elem_length
{
	# Returns length of longest element in a list.

	my $list_ref	= shift;

	my %lengths;

	$lengths{length($_)}++ for @{ $list_ref };

	return max(keys %lengths);
}


sub format_number
{
	my $number = shift;

	# First, we round  to tenths, then we  append a ".0"
	# to those numbers which are integers.

	$number = _round_number($number);
	$number .= ".0" if ($number =~ /^[+-]?\d+\z/);

	return $number;
}


sub format_percentage
{
	my $number = shift;

	# Round number	will round to tenths. Since  we want
	# accuracy of 1/100 percent, we multiply by 1000.
	$number *= 1000;

	# First, we  round to tenths,  then we append a  ".0" to
	# those numbers which are integers.

	$number = _round_number($number);

	# Because in order to get percentages we would only have
	# needed to multiply by 100,  remove the extra factor of
	# 10 here.
	# It  is important  that the  appending of  any trailing
	# zeroes happens after	the last mathematical operation,
	# otherwise they'll be stripped again.
	$number /= 10;
	$number .= ".0" if ($number =~ /^[+-]?\d+\z/);
	$number .= "0" if ($number =~ /^[+-]?\d+\.\d\z/);

	return $number;
}


sub format_hdd_capacity
{
	my $number = shift;

	# Pad with trailing zeroes until two decimal places.
	$number .= "0" until ($number =~ /^[+-]?\d+\.\d\d\z/);

	return $number;
}


sub format_hbar_cap_value
{
	# $_[0]: number
	# NOTE: We need a magic string here unfortunately.

	return format_number($_[0]) . " TB";
}


sub sort_string
{
	return join '', sort { $a cmp $b } split(//, $_[0]);
}

1;
