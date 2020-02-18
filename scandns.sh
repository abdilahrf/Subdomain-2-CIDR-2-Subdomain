#!/usr/bin/perl -w
#
# File:           scandns.pl
# Summary:        dns cleanup tool
#
# Author:         Jon Schatz
#                 Mark Ruys
# E-Mail:         jon@divisionbyzero.com
# Org:            Jon Schatz
#
# Source:         https://github.com/markruys/scandns
#
# Orig-Date:      22-Mar-2000 at 13:30:53
# Last-Mod:       19-Jun-2015 at 12:04:00 by markruys
#
#    This program is free software; you can redistribute it and/or modify it
#    under the terms of the GNU General Public License as published
#    by the Free Software Foundation; either version 1, or (at your option)
#    any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
#    the GNU General Public License or the Artistic License for more details.

use IO::Socket;
use Net::Netmask;
use POSIX ':signal_h';
use strict;

#separate the netmask from the network

my $network = $ARGV[0] || "";
my ($ip_address,$netmask) = split /[\/||:]/ , $network;
my $address;

&usage unless ($ip_address); #complain if @ARGV was incorrect
&badip unless (&validip($ip_address)); #copmlain if $ip_address is invalid

#complain if $netmask is bad. unfortunately Net::Netmask only warns if it's
#given an invalid netmask. I'm working on a patch so that the module will
#be smart enough to return something useful when it cant parse the netmask.

&badnet unless (&validnet($netmask));

#if the netmask is given as a netmask (ie, 255.255.255.0 as opposed to CIDR
# notation (/24)), then ditch the "/" since Net::Netmask isn't smart enough
# to do that either.

$network=~s/\//:/ if (validip($netmask));

#create the netmask object

(my $obj=Net::Netmask->new ($network)) or die "Invalid address / netmask\n";

#return an array of all addresses in the given network

my (@addresses)=$obj->enumerate();


foreach $address (@addresses) {
  &checkdns($address);
}

#the good stuff

sub checkdns {
  my ($ip_address)=@_;
  my ($packed_ip_address)=&get_packed_ip($ip_address);
  my ($hostname)=gethostbyaddr($packed_ip_address, AF_INET);
  
  if (! $hostname) { 
    &no_ptr("$ip_address"); 
    return; 
  }

  my @reverse_packed_ip_address;
  eval {
    sigaction SIGALRM, new POSIX::SigAction sub { die "alarm\n" }
        or die "Error setting SIGALRM handler: $!\n";
    alarm 10;
    ($_ , $_, $_, $_, @reverse_packed_ip_address) = gethostbyname $hostname;
    alarm 0;
  };
  if ($@) {
    die unless $@ eq "alarm\n";
  }

  if ( ! @reverse_packed_ip_address ) {
    &no_a("$ip_address","$hostname"); 
    return;
  }
  
  my @reverse_ip_address = map { inet_ntoa($_) } @reverse_packed_ip_address;

  if ( ! grep(/^$ip_address$/, @reverse_ip_address) ) {
    print("$hostname \n");
  }
  else {
    print("$hostname \n");
  }
}

sub no_ptr {
  my ($ip_address)=@_;
  print " \n";
  
  return;
}

sub no_a {
  my ($ip_address, $hostname)=@_;
  print "$hostname \n";
  return;
}

sub badip {
  print "$ip_address is an invalid address.\n";
  exit 1;
}

sub badnet {
  print "/$netmask is an invalid netmask.\n";
  exit 1;
}

sub usage {
  print "Usage: scandns.pl <address>[/netmask]\n";
  exit 1;
}

sub validnet {
  return(1) unless $_[0];
  my $netmask = $_[0];
  return(1) if (validip($netmask)) ;
  return(1) if (($netmask>=0)&&($netmask<=32));
}

#this is an ip checker that seems simpler to me than the enormous regex in
#the cookbook. since it's only executed twice, it's probably not generating
#that much overhead.

sub validip {
  my $ip = $_[0] || "";
  my $x = 0;
  foreach ($ip=~/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/){ 
    $x++ if(($_>=0)&&($_<=255)); 
  }
  return($x==4);
}

sub get_packed_ip {
 
  my ($ip)=@_;
  chomp $ip;
  my $a;
  my $b;
  my $c;
  my $d;
  ($a, $b, $c, $d)=split(/\./,$ip);
  my $packed_ip=pack "C4","$a","$b","$c","$d";
  return $packed_ip;
}

sub bin2dec {
  my $str= unpack("B8", pack("N", shift));
  $str=~s/^0+(?=\d)//;
  return $str;
}

sub dec2bin {
  return unpack("N",pack("B8", substr("0"x 8, -8)));
}

