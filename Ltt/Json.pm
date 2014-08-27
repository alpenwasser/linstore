package Ltt::Json;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use Data::Dumper;			# for debugging

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw(
	read_json 
	write_json
	);

# These are exported by default.
our @EXPORT = qw(
	read_json 
	write_json
	);


sub read_json
{
	# Reads  a JSON  String from specified input file into a
	# hash. Returns reference to said hash.

	my $input_file_path	= shift;
	my $debug_flag		= shift;

	my $json_decoded_ref;	# reference to hash with decoded
				# JSON contents


	if (-e $input_file_path)
	{
		open my $fh_read, '<', $input_file_path
			or die "Could not open [$input_file_path]: $!";

		my $json_string = '';
		{
			local $/;
			$json_string = <$fh_read>;
		}
		close $fh_read;


		my $json_obj = new JSON::XS;
		$json_obj->utf8(1);

		# Insert line breaks to improve readability:
		$json_obj->pretty(1);

		# Insert space before delimiting colons:
		$json_obj->space_before(1);

		# Insert spaces after delimiting colons:
		$json_obj->space_after(1);

		# And voilà!
		$json_decoded_ref = $json_obj->decode($json_string);
	}


	return $json_decoded_ref unless ($debug_flag);


	# For debugging:
	print Dumper $json_decoded_ref;
	die "Killed script for debugging.";
}


sub write_json
{
	# Writes contents of a given JSON object to a file.


	my $output_file_path	= shift;
	my $json_decoded_ref	= shift;


	my $json_obj = new JSON::XS;
	$json_obj->utf8(1);

	# Insert line breaks to improve readability:
	$json_obj->pretty(1);

	# Insert spaces after delimiting colons:
	$json_obj->space_after(1);

	# Insert space before delimiting colons:
	$json_obj->space_before(1);

	# Keep JSON entries sorted by primary keys.
	$json_obj->canonical(1);


	my $json_output = $json_obj->encode($json_decoded_ref);

	open my $fh, '>', $output_file_path
		or die "Could not open [$output_file_path]: $!";
	print $fh $json_output;
	close $fh;
}


1;
