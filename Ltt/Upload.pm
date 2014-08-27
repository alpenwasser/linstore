package Ltt::Upload;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use Net::FTP;
use File::Spec;

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw(
	upload_images
	);

# These are exported by default.
our @EXPORT = qw(
	upload_images
	);


sub upload_images
{
	my $constants_ref	= shift;
	my $credentials_ref	= shift;
	my $test_flag		= shift;

	# When testing, do not upload files to FTP.
	return if $test_flag;


    # DO NOT  ENTER SERVER INFORMATION AND  USER CREDENTIALS
    # HERE SINCE THIS FILE IS  BEING TRACKED BY GIT AND WILL
    # THEREFORE BE UPLOADED TO GITHUB!
	# USE THE DEDICATED JSON FILE INSTEAD.
	my $ftp = Net::FTP->new($credentials_ref->{	ftp_server}, 
												Debug => 0,
												Passive => 1)
		or die "Cannot connect to host: $@";
	$ftp->login($credentials_ref->{ftp_user},
				$credentials_ref->{ftp_pass})
		or die "Cannot login ", $ftp->message;


    # We need  this, otherwise the files  will get truncated
    # during transfer and end up being corrupt.
	$ftp->binary;


    # List of  images. NOTE: When more  images are  added to
    # the program,  they will need  to be manually  added to
    # this list as well.
	my @img_list = (
		$constants_ref->{hdd_cap_by_vendor_img},
		$constants_ref->{hdd_count_by_vendor_img},
		$constants_ref->{hdd_cap_by_size_img},
		$constants_ref->{hdd_count_by_size_img},
		$constants_ref->{ranking_chart_img},
		$constants_ref->{grouped_plot_by_count_img},
		$constants_ref->{grouped_plot_by_contrib_img}
	);


    # Timestamp images (each with the same timestamp).
	for my $img (@img_list)
	{
		$ftp->put(
			File::Spec->catfile($constants_ref->{img_dir},
								$constants_ref->{timestamp} 
								. $img ))
			or die "get failed ", $ftp->message;
	}

	$ftp->quit;
}


1;
