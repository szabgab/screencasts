#!/usr/bin/env perl
#
# Written by Robin Smidsrød <robin@smidsrod.no>
#
# If you need to quickly download the Youtube video so that you can preview
# the translations in VLC or another video player I would suggest using this
# GreaseMonkey script: http://userscripts.org/scripts/show/62634
#
# Create .srt from specified files
# ./create_srt_from_sbv.pl path/to/something.sbv path/to/another.sbv
#
# Create .srt files from all .sbv files found under directory
# ./create_srt_from_sbv.pl path/to
#
# Create .srt files from all .sbv files found under current directory
# ./create_srt_from_sbv.pl (will take all .sbv files found under current directory)
#

use strict;
use warnings;

use autodie;
use File::Find qw(find);

my @sbv_files = scalar @ARGV
              ? ( -f $ARGV[0] ? @ARGV : find_sbv_files($ARGV[0]) )
              : find_sbv_files('.');

foreach my $sbv_file ( @sbv_files ) {
    eval {
        my $srt_file = create_srt_from_sbv($sbv_file);
        print "CREATED: $srt_file\n";
    };
    if ($@) {
        print STDERR "FAILED: $sbv_file: $@";
    }
}

exit;

# A File::Find rule to find all the .sbv files in all subdirectories underneath
# the current directory
# return an array of relative pathnames (to the root directory).
sub find_sbv_files {
    my ($root_dir) = @_;
    die("Please run this program from the root directory of the checkout.\n") unless -f $0;
    my @found_files;
    find(sub {
        return unless -f $_; # Only process files, not directories
        return unless -r $_; # Skip it if it is not readable
        return unless $_ =~ /\.sbv$/i; # Skip it if it is not a .sbv file
        push @found_files, $File::Find::name;
    }, $root_dir);
    return @found_files;
}

# Create and write out an .srt file with the same path as the .sbv file
sub create_srt_from_sbv {
    my ($sbv_file) = @_;
    die("Not an sbv file: $sbv_file\n") unless $sbv_file =~ /\.sbv$/i;
    open(my $sbv, "<", $sbv_file); # Open .sbv file for input
    (my $srt_file = $sbv_file) =~ s/sbv$/srt/i; # Change extension
    open(my $srt, ">", $srt_file); # Open .srt file for output (forced overwrite)
    my $counter = 1;
    while ( my $line = <$sbv> ) {
        # Only convert lines with timecodes
        # They look like this:
        # 0:00:00.000,0:00:00:000
        if ( $line =~ /^(\d:\d{2}:\d{2}\.\d{3}),(\d:\d{2}:\d{2}\.\d{3})$/ ) {

            # Get timecodes
            my $start = $1;
            my $stop = $2;

            # Change them to .srt style
            $start =~ s/\./,/;
            $stop =~ s/\./,/;

            print $srt "$counter\n"; # Add frame number in front of timecode
            print $srt "$start --> $stop\n"; # SRT timecode format
            $counter++;
        }
        else {
            print $srt $line; # Any other line is just printed
        }
    }
    close($srt);
    close($sbv);
    return $srt_file; # Return the name of the .srt file created
}
