package MooX::PluginRoles::Core;

use Moo;

use Module::Pluggable::Object 4.9;
use Eval::Closure;
use Module::Runtime;
use namespace::clean;

my %SPEC_PLUGINS;

has pkg => (
    is       => 'ro',
    required => 1,
);

has base_classes => (
    is       => 'ro',
    required => 1,
);

has plugin_dir => (
    is       => 'ro',
    required => 1,
);

has class_plugin_roles => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_class_plugin_roles',
);

sub _build_class_plugin_roles {
    my $self = shift;

    my %class_plugin_roles;

    my $pkg        = $self->pkg;
    my $plugin_dir = $self->plugin_dir;

    my $search_path = join '::', $pkg, $plugin_dir;
    my $finder = Module::Pluggable::Object->new( search_path => $search_path );

    for my $found ( $finder->plugins ) {
        my ( $plugin, $base_class ) =
          $found =~ / ^ $search_path :: ([^:]+) :: (.*) $ /x;
        my $class = join '::', $pkg, $base_class;
        $class_plugin_roles{$class}->{$plugin} = $found;
    }

    return \%class_plugin_roles;
}

my $wrapper_code = <<'EOF';
use Moo::Role;
around new => sub {
    my ( $orig, $class, @args ) = @_;
    my ($caller) = caller(2);

    for my $client ( @{ $core->_clients } ) {
        if ( $caller =~ /^$client->{pkg}(?:$|::)/ ) {
            if ( my $new_class = $spec_plugins->{$client->{spec}}->{$class} ) {
                return $new_class->new(@args);
            }
            last;
        }
    }

    return $class->$orig(@args);
};
EOF

sub _wrap_base_class {
    my ( $self, $base_class ) = @_;

    Module::Runtime::use_module($base_class);

    my $wrapper_role = 'MooX::PluginRoles::Wrapped::' . $base_class;
    return if $base_class->does($wrapper_role);

    my $eval = eval_closure(
        source => [ 'sub {', "package $wrapper_role;", $wrapper_code, '}', ],
        environment => {
            '$core'         => \$self,
            '$spec_plugins' => \\%SPEC_PLUGINS,
        },
    );

    $eval->();

    Moo::Role->apply_roles_to_package( $base_class, $wrapper_role );

    return;
}

# create plugin roles for given plugins, and return spec and role mapping
sub _spec_plugins {
    my ( $self, $plugins ) = @_;

    my $spec = join '||', sort @$plugins;

    my $classes = $SPEC_PLUGINS{$spec};

    if ( !$classes ) {
        my $cpr = $self->class_plugin_roles;
        for my $base_class ( @{ $self->base_classes } ) {
            my $class = join '::', $self->pkg, $base_class;
            my $pr = $cpr->{$class}
              or next;
            $self->_wrap_base_class($class);    # idempotent
            my @roles = grep { defined } map { $pr->{$_} } @$plugins
              or next;
            $classes->{$class} =
              Moo::Role->create_class_with_roles( $class, @roles );
        }

        $SPEC_PLUGINS{$spec} = $classes;
    }
    return ( $spec, $classes );
}

has _clients => (
    is      => 'rw',
    default => sub { []; },
);

sub add_client {
    my ( $self, %client_args ) = @_;

    # FIXME - validate arguments
    my ( $spec, $classes ) = $self->_spec_plugins( $client_args{plugins} );

    my $client = {
        spec    => $spec,
        classes => $classes,
        pkg     => $client_args{pkg},
        file    => $client_args{file},
        line    => $client_args{line},
    };

    # store clients sorted by descending package length, so that searching
    # will find the longest match
    $self->_clients(
        [
            sort { length $b->{pkg} <=> length $a->{pkg} }
              ( @{ $self->_clients }, $client ),
        ]
    );

    return;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

MooX::PluginRoles::Core - core plugin functionality

=head1 SYNOPSIS

  # do not use

=head1 DESCRIPTION

C<MooX::PluginRoles::Core> implements the core PluginRoles logic for
the class that defines the plugin system (UGLY - rephrase)

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
