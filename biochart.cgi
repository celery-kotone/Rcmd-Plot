#!/usr/local/bin/perl
use strict;

use CGI;
use CGI::Carp qw(fatalsToBrowser);

use Rcmd::Plot;

my $cgi = CGI->new();

my $chd = $cgi->param("chd");
my $chs = $cgi->param("chs");
my $cht = $cgi->param("cht");

my ( $width, $height ) = split /[x,\/\| \t]/, $chs;

my $jobid = time . substr( rand(10), -4 );

while ( -e "./graph/" . $jobid . ".png" ) {
    $jobid = time . substr( rand(10), -4 );
}

my $filename = "$jobid.png";

my $plot = Rcmd::Plot->new(
    data     => $chd,
    width    => $width,
    height   => $height,
    format   => "png",
    filename => "./graph/$filename"
);

if ( $cht eq "scat" ) {
    $plot->scat();
}

if ( $cht eq "bar" ) {
    $plot->bar();
}

if ( $cht eq "pie" ) {
    $plot->pie();
}

if ( $cht eq "box" ) {
    $plot->box();
}

if ( $cht eq "hist" ) {
    $plot->hist();
}

unless( -e  "./graph" ) {
    mkdir "graph", 0777 or die "$!:graph";
}

if( -e "./graph/$filename" ) {
    chmod 777, "./graph/$filename";
    print "Location: http://localhost/~kotone/biochart/graph/$filename\n\r\n"
}
