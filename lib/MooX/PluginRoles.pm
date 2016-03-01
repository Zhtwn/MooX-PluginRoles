package MooX::PluginRoles;

use strict;
use warnings;
use 5.008_005;

our $VERSION = '0.01';

use MooX::PluginRoles::Core;
use Eval::Closure;
use namespace::clean;

my %PLUGIN_CORES;

sub _register_plugins {
    my %args = @_;

    my $core = $PLUGIN_CORES{ $args{pkg} } ||= MooX::PluginRoles::Core->new(
        pkg          => $args{pkg},
        base_classes => $args{base_classes},
        plugin_dir   => $args{plugin_dir},
    );

    $core->add_client(
        pkg     => $args{client_pkg},
        file    => $args{client_file},
        line    => $args{client_line},
        plugins => $args{plugins},
    );

    return;
}

sub import {
    my ( $me, %opts ) = @_;

    my ($pkg) = caller;

    {
        my $old_import = $pkg->can('import');

        no strict 'refs';          ## no critic (ProhibitNoStrict)
        no warnings 'redefine';    ## no critic (ProhibitNoWarnings)

        my $code = <<'EOF';
        sub {
            # FIXME - validate args
            #   base options:
            #     plugin_dir (valid package name part)
            #     plugin_base_classes (arrayref of >0 class names)
            #   client options:
            #     plugins (arrayref of 0 or more plugin path names)
            my $caller_opts = { @_[ 1 .. $#_ ] };
            $old_import->(@_)
              if $old_import;
            my ( $client_pkg, $client_file, $client_line ) = caller;
            MooX::PluginRoles::_register_plugins(
                %$caller_opts,
                pkg => $pkg,
                client_pkg => $client_pkg,
                client_file => $client_file,
                client_line => $client_line,
                plugin_dir => $opts{plugin_dir} || 'PluginRoles',
                plugins => $caller_opts->{plugins} || [],
                base_classes => $opts{plugin_base_classes} || [],
            );
        }
EOF
        *{"${pkg}::import"} = eval_closure(
            source      => $code,
            environment => {
                '$pkg'        => \$pkg,
                '$old_import' => \$old_import,
                '%opts'       => \%opts,
            }
        );
    }

    return;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

MooX::PluginRoles - add plugins via Moo roles

=head1 SYNOPSIS

  use MooX::PluginRoles;

=head1 DESCRIPTION

MooX::PluginRoles is

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
