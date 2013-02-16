use Test::More tests => 7;

use Rcmd::Plot;

my $plot;
ok $plot = Rcmd::Plot->new("data" => "1,2,2,3,3,3,4,4,4,4");
is $plot->scat, 0;
is $plot->pie,  0;
is $plot->bar,  0;
is $plot->box,  0;
is $plot->hist, 0;
is $plot->DESTROY, 0;
unlink glob "*.ps";
done_testing();
