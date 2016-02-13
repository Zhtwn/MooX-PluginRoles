package MooX::PluginRoles;

use strict;
use warnings;
use 5.008_005;

our $VERSION = '0.01';

use MooX::PluginRoles::Core;
use Carp;
use namespace::clean;

my %PLUGIN_CORES;

sub _register_plugins {
    my ( $pkg, $file, $p_file, $p_line, $opts, $caller_opts ) = @_;

    my $plugins = $caller_opts->{plugins} || [];

    my $core = $PLUGIN_CORES{$pkg} ||= MooX::PluginRoles::Core->new(
        pkg          => $pkg,
        base_classes => $opts->{plugin_base_classes},
        plugin_dir   => $caller_opts->{plugin_dir} || 'PluginRoles',
        plugins      => $plugins,
    );

    if ( !$core->plugins_compatible($plugins) ) {
        my $spec_plugins = join ', ', @{ $core->plugins };
        croak
          "PluginRoles conflict: cannot use $pkg with @$plugins plugin(s):\n\t",
          "Already used with $spec_plugins plugin(s) at:\n\t\t",
          join( "\n\t\t", $core->caller_list ),
          "\n";
    }

    $core->add_caller( $p_file, $p_line );

    $core->apply_plugins;

    return;
}

sub import {
    my ( $me, %opts ) = @_;    

    my ( $pkg, $file ) = caller;
    my ( $p_pkg, $p_file, $p_line ) = caller(3);

    {
        my $old = $pkg->can('import');

        no strict 'refs';          ## no critic (ProhibitNoStrict)
        no warnings 'redefine';    ## no critic (ProhibitNoWarnings)

        *{"${pkg}::import"} = sub {
            my $caller_opts = { @_[ 1 .. $#_ ] };
            $old->(@_) if $old;
            _register_plugins( $pkg, $file, $p_file, $p_line, \%opts, $caller_opts );
        };
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
