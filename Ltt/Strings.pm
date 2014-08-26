package Ltt::Strings;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use List::Util qw(max);
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
	my $string 			= shift;
	my $max_str_length	= shift;
	my $extra_padding 	= shift;

	$string = " " . $string 
		until (length($string) == $max_str_length + $extra_padding);

	return $string;
}

sub pad_right
{
	my $string 			= shift;
	my $max_str_length	= shift;
	my $extra_padding 	= shift;

	$string .= " "
		until (length($string) == $max_str_length + $extra_padding);

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


sub _round_number
{
	my $number = shift;

    # Since  we want  tenths, we  add in  and then  remove a
    # factor of ten.
    # We also  make sure not to  try to divide by  zero, and
    # should the integer part of  $number be zero, we return
    # "0.0".
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

    # First, we  round to tenths,  then we append a  ".0" to
    # those numbers which are integers.

	$number = _round_number($number);
	$number .= ".0" if ($number =~ /^[+-]?\d+\z/);

	return $number;
}


sub format_percentage
{
	my $number = shift;

    # Round  number  will  round to  tenths. Since  we  want
    # accuracy of 1/100 percent, we multiply by 1000.
	$number *= 1000;

    # First, we  round to tenths,  then we append a  ".0" to
    # those numbers which are integers.

	$number = _round_number($number);

    # Because in order to get percentages we would only have
    # needed to multiply by 100,  remove the extra factor of
    # 10 here.
    # It  is important  that the  appending of  any trailing
    # zeroes happens after  the last mathematical operation,
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
