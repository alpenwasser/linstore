package Ltt::Digester;
use strict;
use warnings;
use 5.10.0;
use Exporter;
use Digest::SHA1 qw(sha1_hex sha1_base64);

use Ltt::Strings;

our @ISA= qw( Exporter );

# These CAN be exported.
our @EXPORT_OK = qw(
	get_hash_digest
	);

# These are exported by default.
our @EXPORT = qw(
	get_hash_digest
	);


sub get_hash_digest
{
	# Returns  the	SHA1  digest of  a  multidimensional
	# hash.   Since the  order of  hash elements  varies
	# between  runs,  and  therefore the  order  of  its
	# contents  as	well,  we   go	about  this  in  the
	# following fashion:
	# The  hash and  its  descendants  are traversed  by
	# recursive calls  of this function, and  any actual
	# content (i.e. elements which are not references to
	# hashes) have their SHA1 hash calculated, prepended
	# by their respective key.
	# All	of  these   SHA1  hashes   are	concatenated
	# into	one  string.   This string  is	then  sorted
	# alphanumerically, and of  that sorted concatenated
	# string, the SHA1 digest is returned.
	#
	# LIMITS: If, for two different hash structures, the
	# number  of  occurrences  for	each  alphanumerical
	# character  of  their	elements'  SHA1  digests  is
	# identical,  there will  be  a  hash collision  for
	# the  final   hash. However,  since  this   is  not
	# cryptography	 code  and   the  chances   of	this
	# happening are miniscule, we can accept this.


	my $input = shift;

	my $concat_digests;

	# First, see if $input is a hash ref:
	if (ref $input eq ref {})
	{
		# If so, traverse its target hash...
		for (keys %{ $input })
		{
			# Check if  any of its	elements are
			# hash references themselves...
			if (ref $input->{$_} eq ref {})
			{
				# ...	if  so,   call	this
				# function  recursively  for
				# that hash ref...
				$concat_digests 
				.= get_hash_digest($input->{$_});
			}
			else
			{
				# ...otherwise,    calculate
				# SHA1	digest for  contents
				# and hash key name.
				# The key name is also taken
				# into	account  because  it
				# carries  information about
				# the  hash configuarion  as
				# well,   for	example   in
				# systems.json,    it	will
				# identify  the  HDD  vendor
				# and size.
				$concat_digests .= sha1_hex($_ . $input->{$_})
					if ($input->{$_});
			}
		}
	}

	return sha1_base64(sort_string($concat_digests));
}


1;
