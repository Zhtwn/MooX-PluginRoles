package MooX::PluginRoles::Core;

use Moo;

use Moo::Role ();
use Module::Pluggable::Object 4.9;
use Module::Runtime 0.014 qw( require_module );
use Carp;
use namespace::clean;

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

has plugins => (
    is       => 'ro',
    required => 1,
);

has canonical_plugins => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_canonical_plugins',
);

sub _build_canonical_plugins {
    my $self = shift;
    return join '||', sort @{ $self->plugins };
}

sub plugins_compatible {
    my ( $self, $plugins ) = @_;
    $plugins = join '||', sort @{$plugins};
    return $plugins eq $self->canonical_plugins;
}

has _callers => (
    is       => 'ro',
    init_arg => undef,
    default  => sub { [] },
);

sub add_caller {
    my ( $self, $file, $line ) = @_;
    push @{ $self->_callers }, { file => $file, line => $line };
}

sub caller_list {
    my $self = shift;
    return map { $_->{file} . ', line ' . $_->{line} } @{ $self->_callers };
}

has _plugin_roles => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build__plugin_roles',
);

sub _build__plugin_roles {
    my $self = shift;

    my %plugin_roles;

    my $pkg        = $self->pkg;
    my $plugin_dir = $self->plugin_dir;

    my $search_path = join '::', $pkg, $plugin_dir;
    my $finder = Module::Pluggable::Object->new( search_path => $search_path );

    for my $found ( $finder->plugins ) {
        my ( $plugin, $base_class ) =
          $found =~ /^${search_path}::([^:]+)::(.*)$/;
        $plugin_roles{$plugin}->{$base_class} = $found;
    }

    return \%plugin_roles;
}

has _applied => (
    is       => 'rw',
    init_arg => undef,
    default  => undef,
);

sub apply_plugins {
    my $self = shift;

    return if $self->_applied;

    my $pkg          = $self->pkg;
    my $plugin_roles = $self->_plugin_roles;
    my $base_classes = $self->base_classes;

    my %new_roles;

    for my $plugin ( @{ $self->plugins } ) {
        my $roles = $plugin_roles->{$plugin}
          or next;

        for my $class (@$base_classes) {
            my $new_role = $roles->{$class}
              or next;
            require_module($new_role);
            push @{ $new_roles{"${pkg}::$class"} }, $new_role;
        }
    }

    Moo::Role->apply_roles_to_package( $_, @{ $new_roles{$_} } )
      for keys %new_roles;

    $self->_applied(1);

    return;
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

MooX::PluginRoles::Core;

=head1 SYNOPSIS

  # do not use

=head1 DESCRIPTION

MooX::PluginRoles::Core implements the core PluginRoles logic

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2016- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
