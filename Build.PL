use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Rcmd::Plot',
    license             => 'artistic2',
    dist_author         => 'Kotone Itaya <celery at g-language.org>',
    dist_version_from   => 'lib/Rcmd/Plot.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Rcmd-Plot-*' ],
);

$builder->create_build_script();
