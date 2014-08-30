package Ltt::Imaging;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use Net::FTP;
use File::Spec;
use GD;
use GD::Text::Align;


our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw(
	timestamp_img
	);

# These are exported by default.
our @EXPORT = qw(
	timestamp_img
	);


sub timestamp_img
{
	# Takes  an   image  and  watermarks  it   with  the
	# timestamp of the current program  run as well as a
	# string (in our case, a  SHA1 digest of the systems
	# configuration).  This  ensures that images  can be
	# dated without their filename information, and that
	# they can be grouped based on system configuration,
	# if needed.
	# Returns the actual image data.


	my $img_data = shift;
	my $timestamp = shift;
	my $digest = shift;


	my $gd = GD::Image->new($img_data) or die;
	$gd->interlaced('true');


	my ($w, $h) = $gd->getBounds();

			
	my $gdt_br = GD::Text::Align->new($gd,
		valign => 'bottom',
		halign => 'right',
		text   => $timestamp,
		colour => $gd->colorResolve(0,0,0),
	) or die;
	$gdt_br->set_font('fonts/FreeMono.ttf', 12) or die;

	# Timestamp goes in the lower right corner:
	$gdt_br->draw($w, $h, 0) or die;


	my $gdt_bl = GD::Text::Align->new($gd,
		valign => 'bottom',
		halign => 'left',
		text   => $digest,
		colour => $gd->colorResolve(0,0,0),
	) or die;
	$gdt_bl->set_font('fonts/FreeMono.ttf', 12) or die;

	# String into the lower left corner:
	$gdt_bl->draw(0, $h, 0) or die;


	return $gd->png;
}
