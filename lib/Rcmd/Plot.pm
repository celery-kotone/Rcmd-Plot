package Rcmd::Plot;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('1.0.0');

use base qw(Class::Accessor Rcmd);

Rcmd::Plot->follow_best_practice;

my %defaults = (
    "width"     => 640,
    "height"    => 480,
    "title"     => "",
    "xlabel"    => "",
    "ylabel"    => "",
    "format"    => "postscript",
    "filename"  => "default",
    "color"     => "default",
    "linestyle" => "p",
    "linetype"  => "default",
    "point"     => "default",
    "legend"    => "",
    "legendbor" => "rgb(0,0,0,alpha=0)",
    "legendpos" => "topleft",
    "internal"  => "library(RColorBrewer)",
    "library"   => "",
    "bgcolor"   => "white",
    "fontcolor" => "black",
    "overflow"  => "T",
    "sets"      => 1,
    "breaks"    => "Sturges"
);

sub new {
    my $class = shift;
    my %args  = (@_);

    my $thys = bless Rcmd->new, $class;

    $thys->set_mode("silent");
    $thys->set_args(%defaults);
    $thys->set_args(%args);

    return $thys;
}

sub DESTROY {
    my $thys = shift;

    return 0;
}

sub exec_plot {
    my $thys = shift;

    $thys->process_filename;

    my $plot     = $thys->get("plot");
    my $width    = $thys->get("width");
    my $height   = $thys->get("height");
    my $internal = $thys->get("internal");
    my $library  = $thys->get("library");
    my $format   = $thys->get("format");
    my $filename = $thys->get("filename");

    my $dev = sprintf( "%s(file=\"%s\",width=%d,height=%d)",
        $format, $filename, $width, $height );

    $thys->exec(
        $internal,
        $library,
        $dev,
        $thys->query_params,
        $plot,
        $thys->query_legend,
        "graphics.off()"
        );

    return 0;
}

sub set_args {
    my $thys = shift;
    my %args = (@_);

    foreach my $key ( keys %args ) {
        $thys->set( $key, delete $args{$key} );
    }

    return 0;
}

sub process_color {
    my $thys = shift;
    my $type;

    if ( ~~ @_ ) {
        $type = shift;
    }
    else {
        $type = "color";
    }

    my $sets  = $thys->get("sets");
    my $color = $thys->get($type);

    $sets += !$sets;

    if ( $sets < 3 && $color eq "mat" ) {
        $sets = 3;
    }

    $color = sprintf( "rainbow(%d)", $sets ) if $color eq "default";
    $color = sprintf( "brewer.pal(%d,'Spectral')", $sets ) if $color eq "mat";
    $color = sprintf( "c(%s)", $color ) if $color =~ /rgb(.+?)/;
    $color =~ s/auto/$sets/g;
    $color = sprintf( "'%s'", $color ) if $color =~ /^\w+$/;

    return $color;
}

sub process_point {
    my $thys = shift;

    my $sets  = $thys->get("sets");
    my $point = $thys->get("point");

    $sets += !$sets;

    $point = sprintf( "0:%d", $sets ) if $point eq "default";

    return $point;
}

sub process_linetype {
    my $thys = shift;

    my $sets     = $thys->get("sets");
    my $linetype = $thys->get("linetype");

    $sets += !$sets;

    $linetype = sprintf( "1:%d", $sets ) if $linetype eq "default";

    return $linetype;
}

sub process_filename {
    my $thys = shift;

    my $filename = $thys->get("filename");
    my $format   = $thys->get("format");

    $format = "ps"
      if $format eq "postscript";

    $filename .= sprintf( ".%s", $format )
      if $filename eq "default";

    $filename .= sprintf( "%s.", $format )
      if ( $filename !~ /$format/ );

    $thys->set( "filename", $filename );

    return 0;
}

sub query_params {
    my $thys = shift;

    my $bgcolor   = $thys->process_color("bgcolor");
    my $fontcolor = $thys->process_color("fontcolor");
    my $overflow  = $thys->get("overflow");

    my $params = sprintf( "par(bg=%s,col.main=%s,col.lab=%s,xpd=%s)",
        $bgcolor, $fontcolor, $fontcolor, $overflow );

    return $params;
}

sub query_legend {
    my $thys = shift;

    my $legend    = $thys->get("legend");
    my $point     = $thys->get("point");
    my $color     = $thys->process_color("color");
    my $fontcolor = $thys->process_color("fontcolor");
    my $linetype  = $thys->get("linetype");
    my $lborder   = $thys->get("legendbor");
    my $lposition = $thys->get("legendpos");

    return "" unless length $legend;

    $legend = sprintf( "c('%s')", $legend );
    $legend =~ s/\|/','/g;

    return
      sprintf( "legend('%s',%s,fill=%s,cex=1,border=%s,bty='n'"
          . ",xpd=T,text.col=%s)",
        $lposition, $legend, $color, $lborder, $fontcolor );
}

sub line {
    my $thys = shift;
    my %args = (@_);

    $thys->set_args(%args);

    unless ( defined $thys->get("data") ) {
        die("Plotting data not specified\n");
    }

    my $data      = $thys->get("data");
    my $title     = $thys->get("title");
    my $xlabel    = $thys->get("xlabel");
    my $ylabel    = $thys->get("ylabel");
    my $linestyle = $thys->get("linestyle");

    if ( $data =~ /,/ ) {
        my @sets = split( /\|/, $data );

        $data = sprintf( "c(%s)", shift(@sets) );
        if ( ~~ @sets ) {
            $data .= sprintf( ",cbind(c(%s))", join( "),c(", @sets ) );
        }

        $thys->set( "sets", ~~ @sets );
    }

    my $color    = $thys->process_color;
    my $point    = $thys->process_point;
    my $linetype = $thys->process_linetype;

    my $plot = sprintf(
        "matplot(%s,main=\"%s\",col=%s,type=\"%s\","
          . "xlab=\"%s\",ylab=\"%s\",pch=%s,lty=%s)",
        $data,   $title,  $color, $linestyle,
        $xlabel, $ylabel, $point, $linetype
    );

    $thys->set( "plot", $plot );
    $thys->exec_plot;

    return 0;
}

sub scat {
    my $thys = shift;
    my %args = (@_);

    $thys->set_args(%args);

    unless ( defined $thys->get("data") ) {
        die("Plotting data not specified\n");
    }

    my $data      = $thys->get("data");
    my $title     = $thys->get("title");
    my $xlabel    = $thys->get("xlabel");
    my $ylabel    = $thys->get("ylabel");
    my $linestyle = $thys->get("linestyle");

    if ( $data =~ /,/ ) {
        my ( @x, @y );
        my @sets = split( /\|/, $data );
        my $sets = ~~ @sets;

        if( $sets > 1 ) {
            while( ~~ @sets ) {
                push( @x, sprintf( "c(%s)", shift @sets ) );
                push( @y, sprintf( "c(%s)", shift @sets ) );
            }

            $data = sprintf(
                "cbind(%s),cbind(%s)",
                join( ",", @x ),
                join( ",", @y )
                );
        } else {
            $data = sprintf( "c(%s)", $data );
        }
        
        $thys->set( "sets", ~~ $sets );
    }

    my $color    = $thys->process_color;
    my $point    = $thys->process_point;
    my $linetype = $thys->process_linetype;

    my $plot = sprintf(
        "matplot(%s,main=\"%s\",col=%s,type=\"%s\","
          . "xlab=\"%s\",ylab=\"%s\",pch=%s,lty=%s)",
        $data,   $title,  $color, $linestyle,
        $xlabel, $ylabel, $point, $linetype
    );

    $thys->set( "plot", $plot );
    $thys->exec_plot;

    return 0;
}

sub bar {
    my $thys = shift;
    my %args = (@_);

    $thys->set_args(%args);

    unless ( defined $thys->get("data") ) {
        die("Plotting data not specified\n");
    }

    my $data   = $thys->get("data");
    my $title  = $thys->get("title");
    my $xlabel = $thys->get("xlabel");
    my $ylabel = $thys->get("ylabel");

    my @sets = split( /\|/, $data );
    my $sets = ~~ @sets;

    if ( $data =~ /,/ ) {
        if ( $sets == 1 ) {
            $sets = ( $data =~ tr/,/,/ ) + 1;
            $data = sprintf( "c(%s)", shift @sets );
        }
        else {
            foreach (@sets) {
                if ( $sets < ( $_ =~ tr/,/,/ ) + 1 ) {
                    $sets = ( $data =~ tr/,/,/ ) + 1;
                }
            }
            $data = sprintf( "cbind(c(%s))", join( "),c(", @sets ) );
        }
    }

    $thys->set( "sets", $sets );

    my $color = $thys->process_color;

    $xlabel = sprintf( "c('%s')", $xlabel );
    $xlabel =~ s/\|/','/g;

    my $plot =
      sprintf( "barplot(%s,main=\"%s\",names.arg=%s,ylab=\"%s\",col=%s)",
        $data, $title, $xlabel, $ylabel, $color );

    $thys->set( "plot", $plot );
    $thys->exec_plot;

    return 0;
}

sub pie {
    my $thys = shift;
    my %args = (@_);

    $thys->set_args(%args);

    unless ( defined $thys->get("data") ) {
        die("Plotting data not specified\n");
    }

    my $data  = $thys->get("data");
    my $title = $thys->get("title");

    if ( $data =~ /,/ ) {
        $data =~ s/\|/,/g;

        my @sets = split( /,/, $data );
        $thys->set( "sets", ~~ @sets );

        $data = sprintf( "c(%s)", $data );
    }

    my $color = $thys->process_color;

    my $plot =
      sprintf( "pie(%s,main=\"%s\",col=%s,init.angle=90,clockwise=1,radius=1)",
        $data, $title, $color );

    $thys->set( "plot", $plot );
    $thys->exec_plot;

    return 0;
}

sub box {
    my $thys = shift;
    my %args = (@_);

    $thys->set_args(%args);

    unless ( defined $thys->get("data") ) {
        die("Plotting data not specified\n");
    }

    my $data   = $thys->get("data");
    my $title  = $thys->get("title");
    my $xlabel = $thys->get("xlabel");
    my $ylabel = $thys->get("ylabel");

    if ( $data =~ /,/ ) {
        my @sets = split( /\|/, $data );
        my $sets = ~~ @sets;

        if ( $sets == 1 ) {
            $sets = ( $data =~ tr/,/,/ ) + 1;
            $data = sprintf( "c(%s)", shift @sets );
        }
        else {
            foreach (@sets) {
                if ( $sets < ( $_ =~ tr/,/,/ ) + 1 ) {
                    $sets = ( $data =~ tr/,/,/ ) + 1;
                }
            }
            $data = sprintf( "list(c(%s))", join( "),c(", @sets ) );
        }

        $thys->set( "sets", $sets );
    }

    my $color = $thys->process_color;

    my $plot =
      sprintf( "boxplot(%s,main=\"%s\",xlab=\"%s\",ylab=\"%s\",col=%s)",
        $data, $title, $xlabel, $ylabel, $color );

    $thys->set( "plot", $plot );
    $thys->exec_plot;

    return 0;
}

sub hist {
    my $thys = shift;
    my %args = (@_);

    $thys->set_args(%args);

    unless ( defined $thys->get("data") ) {
        die("Plotting data not specified\n");
    }

    my $data   = $thys->get("data");
    my $title  = $thys->get("title");
    my $xlabel = $thys->get("xlabel");
    my $ylabel = $thys->get("ylabel");
    my $breaks = $thys->get("breaks");

    if ( $data =~ /,/ ) {
        $data =~ s/\|/,/g;

        my @sets = split( /,/, $data );
        $thys->set( "sets", ~~ @sets );

        $data = sprintf( "c(%s)", shift @sets );
    }

    my $color = $thys->process_color;

    my $plot =
      sprintf(
        "hist(%s,main=\"%s\",xlab=\"%s\",ylab=\"%s\",col=%s," . "breaks='%s')",
        $data, $title, $xlabel, $ylabel, $color, $breaks );

    $thys->set( "plot", $plot );
    $thys->exec_plot;

    return 0;
}

q^
sub venn {
    my $thys = shift;
    my %args = (@_);

    $thys->set_args(%args);

    unless ( defined $thys->get("data") ) {
        die("Plotting data not specified\n");
    }

    my $data   = $thys->get("data");
    my $title  = $thys->get("title");
    my $xlabel = $thys->get("xlabel");
    my $ylabel = $thys->get("ylabel");


    if($data =~ /,/) {
        my @sets = split( /\|/, $data );
        my $sets = ~~ @sets;

        if ( $sets == 1 ) {
            $sets = ( $data =~ tr/,/,/ ) + 1;
            $data = sprintf( "c(%s)", shift @sets );
        } else {
            foreach (@sets) {
                if ( $sets < ( $_ =~ tr/,/,/ ) + 1 ) {
                    $sets = ( $data =~ tr/,/,/ ) + 1;
                }
            }
            $data = sprintf( "list(c(%s))", join( "),c(", @sets ) );
        }

        $thys->set( "sets", $sets );
    }

    my $color = $thys->process_color;

    my $plot =
        sprintf( "boxplot(%s,main=\"%s\",xlab=\"%s\",ylab=\"%s\",col=%s)",
        $data, $title, $xlabel, $ylabel, $color );

    $thys->set( "plot", $plot );
    $thys->exec_plot;

    return 0;
}
^ if 0;

1;    # Magic true value required at end of module
__END__

=head1 NAME

Rcmd::Plot - Rcmd wrapper for plotting graphs


=head1 VERSION

This document describes Rcmd::Plot version 0.0.1


=head1 SYNOPSIS

    use Rcmd::Plot;

    $plot = Rcmd::Plot->new(data => "<data string>",
                            format => "<graphic format>",
                            filename => "<output filename>");
    $plot->plot();
    $plot->bar();
    $plot->pie();
    $plot->box();
    $plot->hist();
  
=head1 DESCRIPTION

=head2 $plot = Rcmd::Plot->new()

    Name: $plot = Rcmd::Plot->new() - create an instance of Rcmd-Plot

    This module s a simple interface to plot graphs via the Rcmd module.

    Plotting options can be set by either passing arguments to the new()
    method or to each of the other plotting methods.

    Mandatory qualifers:
        data   -   Data to be plotted. Each value should be comma
                   splitted and groups should be designated with
                   a vertical bar.

    Optional qualifiers:
        width     - Width of graph. Default is 640
        height    - Height of graph. Default is 480
        title     - Title of the graph.
        format    - Output file format. Should be a valid command for
                    graphics in the R language.
        filename  - Output file name.
        color     - Line color, or fill color.
                    Plain words will be wrapped with single quotes.
        xlabel    - Label for x axis.
        ylabel    - Label for y axis.
        legend    - Vertical bar delimited string for legend names.
        legendbor - Border color for the legend.
        legendpos - Position of the legend.
        bgcolor   - Color for graph background.
        fontcolor - Color for graph text.
        overflow  - Set to True to draw outside plotting region.
        library   - External library calls (Must be installed).

    Variable qualifiers:
        $thys->scat():
        linestyle - Line style.
        linetype  - Line type.
        point     - Point shape for scatter plots.

        $thys->hist():
        breaks - Values to set breaks.
        
=head2 Rcmd::Plot->line()
    Performs a line plot with the given data.

=head2 Rcmd::Plot->scat()
    Performs a scatter plot with the given data.

=head2 Rcmd::Plot->bar()
    Performs a bar plot with the given data.

=head2 Rcmd::Plot->pie()
    Performs a pie chart plot with the given data.

=head2 Rcmd::Plot->box()
    Performs a box plot with the given data.

=head2 Rcmd::Plot->hist()
    Performs a histogram plot with the given data.

=head2 Rcmd::Plot->exec_plot()
    Perform a plot manually with the query in 'plot' member.

=head2 Rcmd::Plot->process_color()
    Converts the 'color' member to R format.

=head2 Rcmd::Plot->process_filename()
    Validates the filename from the given format.

=head2 Rcmd::Plot->process_linetype()
    Converts the 'linetype' member to R format.

=head2 Rcmd::Plot->process_point()
    Converts the 'point' member to R format.

=head2 Rcmd::Plot->query_legend()
    Creates R 'legend' query string.

=head2 Rcmd::Plot->query_params()
    Creates R 'par' query string.

=head2 Rcmd::Plot->set_args()
    Set multiple arguments.
    

=head1 INTERFACE 

Constructor:
$plot = Rcmd::Plot->new(<arguments>)

Plotting methods:
Same arguments as the constructors can be set in these methods
    $plot->scat(<arguments>);
    $plot->bar(<arguments>);
    $plot->pie(<arguments>);
    $plot->box(<arguments>);
    $plot->hist(<arguments>);

Access to a member:
    $plot->get("<name>")
    $plot->set("<name>", "<value>")

Setting arguments:
    $plot->set_args(<arguments>)

Manual plotting:
    $plot->exec_plot(<arguments>);

Destructor:
    $plot->DESTROY();


=head1 DIAGNOSTICS

=over

=item C<< Plotting data not specified\n >>

[Comes out when the data is not given]

=back


=head1 CONFIGURATION AND ENVIRONMENT

Rcmd::Plot requires no configuration files or environment variables.


=head1 DEPENDENCIES

Perl
-Rcmd (from G-language Genome Analysis Environment)
R language environment
-RColorBrewer package
-Vennerable package **Not in need yet


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-rcmd-plot@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Kotone Itaya  C<< <celery at g-language.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Kotone Itaya C<< <celery at g-language.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
