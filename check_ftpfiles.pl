#!/usr/bin/perl -w
# Nagios plugin that count the number of files in an FTP folder

use strict;
use Getopt::Std;
use Net::FTP;
use Sys::Hostname;

# Agruments validation
my %opts;
getopts('hH:d:c:w:t:u:p:D:v',\%opts);

# Help screen
if ( defined($opts{h}) )
{
  print <<EOF;
    Perl check FTP files plugin for Nagios
    Copyright (c) 2007 Corrado Ferilli
    Copyright (c) 2013 Guillaume Ayoub

    This plugin should be used from the Nagios server to monitor file queues via FTP.

    usage: $0 [-H <hostname>] [-d <folder>] [-u <user>] [-p <pass>] [-D <desc>] [-t <timeout>] [-w <warn>] [-c <crit>]

    -h          print this short help message
    -v          verbose output
    <hostname>  FTP hostname
    <folder>    FTP folder path to monitor
    <user>      FTP user
    <pass>      FTP password
    <desc>      Result message description
    <timeout>   Timeout
    <warn>      Warning items limit
    <crit>      Critical items limit

EOF
  exit;
}

# Check if mandatory options have been specified
if ( ! defined $opts{H} || ! defined $opts{d} || ! defined $opts{u} || ! defined $opts{p} || ! defined $opts{D} || ! defined $opts{t} || ! defined $opts{w} || ! defined $opts{c} )
{
  print "UNKNOWN - Options [H|d|P|u|p|D|t|w|c] are mandatory\n";
  exit 3;
}

# Variables initialization
my $host = $opts{H};
my $directory = $opts{d};
my $timeout = $opts{t};

my $ftp_username = $opts{u};
my $ftp_userpass = $opts{p};

my $warning = $opts{w};
my $critical = $opts{c};

my $count = 0;
my @ERRORS;
my $ftp = "";
my @files;
my $newerr = 0;
my $output = "";
my $date = `date +%Y%m%d`;
chomp $date;
my $hostname = hostname;
my $pattern = "$hostname-(.*)\.$date\.*";

# FTP connection
$ftp=Net::FTP->new($host,Timeout=>$timeout,Passive=>1) or $newerr=1;
  push @ERRORS, "Can't ftp to $host: $!\n" if $newerr;
  myerr() if $newerr;

# FTP login
$ftp->login($ftp_username,$ftp_userpass) or $newerr=1;
  push @ERRORS, "Can't login to $host: $!\n" if $newerr;
  $ftp->quit if $newerr;
  myerr() if $newerr; 

# FTP change current directory
$ftp->cwd($directory) or $newerr=1;
  push @ERRORS, "Can't cd  $!\n" if $newerr;
  myerr() if $newerr;
  $ftp->quit if $newerr;

# FTP directory listing
@files=$ftp->dir or $newerr=1;
  push @ERRORS, "Can't get file list $!\n" if $newerr;
  myerr() if $newerr;

# FTP directory file count
foreach(@files)
  {
    $count++ if $_ =~ $pattern;
  }

# FTP close connection
$ftp->quit;

# Verbose output check
if ($opts{v})
	{
		$output = "$opts{D} : $count items in $directory \n";
	}
	else
	{
		$output = "$opts{D} : $count items \n";
	}

# Threshold check
if ($count > $warning) 
	{ 
		print "OK - $output"; exit 0;
	}
	else
	{
		if ($count > $critical)
			{
				print "WARNING - $output"; exit 1;
			}
			else
			{
				print "CRITICAL - $output"; exit 2;
			}
	}

# Scripts errors handling
sub myerr {
  print "Error: @ERRORS";
  exit 3;
}
