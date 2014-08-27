package Ltt::Writer;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use File::Spec;

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw( 
	write_output
	);

# These are exported by default.
our @EXPORT = qw( 
	write_output
	);


sub write_output
{
	my $output_data = shift;
	my $output_file = shift;

	open(my $fh, '>:encoding(UTF-8)', $output_file)
		or die "Could not open file '$output_file'";
	print $fh $output_data;
	close $fh;
}


1;
