package MooX::PluginRoles;

use strict;
use warnings;
use 5.008_005;

our $VERSION = '0.01';

use Moo::Role ();
use Try::Tiny;
use Path::Tiny;
use Path::Iterator::Rule 1.004;
use Carp;
use Module::Runtime 0.014 qw( require_module );

sub _find_moo_classes {
    my ( $base_dir, $plugin_dir ) = @_;
    my $iter = Path::Iterator::Rule->new->file->skip_dirs($plugin_dir)
      ->perl_module->contents_match(qr/\buse Moo\s*;/);
    my @dirs;
    for my $dir ($iter->all($base_dir)) {
        my $p = path($dir)->relative($base_dir);
        $p =~ s/[.]pm$//;
        $p =~ s{/}{::}g;
        push @dirs, $p;
    }
    return @dirs;
}

my %CLASS_PLUGINS;

sub _apply_roles {
    my ( $pkg, $file, $p_file, $p_line, $opts, $caller_opts ) = @_;

    $file =~ s/[.]pm$//;
    my $base_dir = path($file);

    my $plugins = $caller_opts->{plugins} || [];
    $plugins = [$plugins] unless ref $plugins;

    my $canonical = join '||', sort @{$plugins};

    my $spec = $CLASS_PLUGINS{$pkg};

    my $need_roles;

    if ($spec) {
        my $spec_canonical = $spec->{canonical} || '';
        if ( $spec_canonical ne $canonical ) {
            my $spec_plugins = join ', ', @{ $spec->{plugins} };
            $spec_plugins ||= 'no';
            croak "PluginRoles conflict: cannot use $pkg with @$plugins plugin(s): ",
              "used with $spec_plugins plugin(s) at:\n\t",
              join( "\n\t",
                map { $_->{file} . ', line ' . $_->{line} }
                  @{ $spec->{callers} } ),
              "\n";
        }
    }
    else {
        $spec = $CLASS_PLUGINS{$pkg} = {
            canonical => $canonical,
            plugins   => $plugins,
        };

        $need_roles = 1;
    }

    push @{$spec->{callers}}, { file => $p_file, line => $p_line };

    if ( $need_roles && @$plugins) {
        $DB::single = 1;
        my $plugin_dir = $caller_opts->{plugin_dir} || 'PluginRoles';
        my $plugin_path = $base_dir->child($plugin_dir);

        if ( !$plugin_path->is_dir ) {
            croak "plugin_dir $plugin_path does not exist";
        }

        my $plugin_base_classes = $caller_opts->{plugin_base_classes}
          || [ _find_moo_classes( $base_dir, $plugin_path ) ];

        for my $class (@$plugin_base_classes) {
            my $base_class = "$pkg::$class";
            my @class_plugins;
            for my $plugin (@$plugins) {
                my $role = join '::', $pkg, $plugin_dir, $plugin, $class;
                try {
                    require_module($role)
                }
                  and push @class_plugins, $role;
            }

            Moo::Role->apply_roles_to_package( $base_class, @class_plugins )
              if @class_plugins;
        }
    }
}

sub import {
    my ( $me, %opts ) = @_;    

    my ( $pkg, $file ) = caller;
    my ( $p_pkg, $p_file, $p_line ) = caller(3);

    {
        my $old = $pkg->can('import');

        no strict 'refs';
        no warnings 'redefine';

        *{"${pkg}::import"} = sub {
            my $caller_opts = { @_[ 1 .. $#_ ] };
            $old->(@_) if $old;
            _apply_roles( $pkg, $file, $p_file, $p_line, \%opts, $caller_opts );
        };
    }

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
