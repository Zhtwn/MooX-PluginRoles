# NAME

MooX::PluginRoles - add plugins via sets of Moo roles

# SYNOPSIS

    # base class that accepts plugins
    package MyPkg;

    use Moo;                  # optional
    use MooX::PluginRoles (
      plugin_dir      => 'Plugins',   # default
      plugin_role_dir => 'Roles',     # default
      plugin_classes  => [ 'Foo' ],   # must be Moo classes
    );

    # class within MyPkg that can be extended by plugin roles
    package MyPkg::Foo;
    use Moo;

    # class that is excluded from extending with plugin roles
    package MyPkg::NotMe;
    use Moo;

    # Readable plugin - provides role with read method for Foo class
    package MyPkg::Plugins::Readable::Roles::Foo;
    use Moo::Role;

    sub read { ...  }

    # Writeable plugin - provides role with write method for Foo class
    package MyPkg::Plugins::Writeable::Roles::Foo;
    use Moo::Role;

    sub write { ...  }

    # client using just the Readable plugin
    package ClientReadOnly;
    use MyPkg plugins => ['Readable'];

    $p = MyPkg->new();
    $p->read;             # succeeds

    # client using both Readable and Writeable plugins
    package ClientReadWrite;
    use MyPkg plugins => ['Readable', 'Writeable'];

    $p = MyPkg->new;
    $p->read;             # succeeds
    $p->write('quux');    # succeeds

# STATUS

This is an alpha release of `MooX::PluginRoles`. The API is simple
enough that it is unlikely to change much, but one never knows until
users start testing the edge cases.

The implementation works well, but is still a bit rough. It needs
more work to detect and handle error cases better, and likely needs
optimization as well.

# DESCRIPTION

`MooX::PluginRoles` is a plugin framework that allows plugins to be
specified as sets of Moo roles that are applied to the Moo classes in
the calling namespace.

Within the Moo\* frameworks, it is simple to extend the behavior of a
single class by applying one or more roles. `MooX::PluginRoles` extends
that concept to a complete namespace.

## Nomenclature

- base class

    The base class is the class that uses `MooX::PluginRoles` to provide
    plugins. It specifies where to find the plugins (`plugin_dir` and
    `plugin_role_dir`), and which classes may be extended (`plugin_classes`)

- client package

    The client package is the package that uses the base class, and
    specifies which plugins should be used (`plugins`).

- extendable classes

    The extendable classes are the classes listed by the base class in
    `plugin_classes`. These classes must be in the namespace of the base
    class, and plugin roles will be applied to them.

- plugin

    A plugin provides roles that will be applied to the extendable classes.

Each plugin creates the needed roles in a hierarchy that matches the
base class hierarchy. For instance, if a client uses the base class
`MyBase` with the plugin `P`, and `MyBase` lists `C` as an
extendable class, then the plugin role `MyBase::Plugins::P::Roles::C`
will be applied to the extendable class `MyBase::C`.

    package MyBase;
    use MooX::PluginRoles ( plugin_classes => ['C'] );

    package MyBase::C;
    has name => ( is => 'ro' );

    # role within P plugin for MyBase::C class
    package MyBase::Plugins::P::Roles::C;
    has old_name => ( is => 'ro' );

    package MyClient;
    use MyBase ( plugins => ['MyP'] );

    $c = MyBase::C->new();
    say $c->name;         # succeeds
    say $c->old_name;     # succeeds

At this point, when `MyBase::C->new()` is called, and the calling
package starts with `MyClient::`, the constructor will return an
instance of an anonymous class created by applying the `P` plugin
role to the `C` extendable class.

A plugin is free to create additional packages as needed, as long
as they are not in the `::Roles` directory.

## Parameters in base class

- plugin\_dir

    Directory that contains the plugins. Defaults to `"Plugins"`

- plugin\_role\_dir

    Directory within `plugin_dir` that contains the roles. Defaults to
    `"Roles"`

- plugin\_classes

    Classes within the base class namespace that may be extended by
    plugin roles, as an ArrayRef of class names relative to the
    base class's namespace.

    NOTE: Defaults to an empty list, so no classes will be extended
    unless they are explicitly listed here.

## Parameters in client

- plugins

    ArrayRef of plugins that should be applied to the base class when
    it is being used in this client.

## Internals

When `MooX::PluginRoles` is used, adds a wrapper around the caller's
`import` method that creates a [MooX::PluginRoles::Base](https://metacpan.org/pod/MooX::PluginRoles::Base) instance for
the caller, and saves it in a class-scoped hash.

The `Base` instance finds the available plugins and roles, creates
anonymous classes with the plugin roles applied, and creates an
anonymous role for each base class that wraps the `new` method so that
the proper anonymous class can be used to create the instances.

`Module::Pluggable::Object` is used to find the roles within each
plugin.

# LIMITATIONS

The plugin roles will only work if the immediate caller of the
`new` constructor is in the namespace of the client that used the
base class.

# SEE ALSO

- [Moo](https://metacpan.org/pod/Moo) and [Moo::Role](https://metacpan.org/pod/Moo::Role)

    Moo object-orientation system

- [MooX::Role::Pluggable](https://metacpan.org/pod/MooX::Role::Pluggable), [MooX::Object::Pluggable](https://metacpan.org/pod/MooX::Object::Pluggable)

    Packages that apply plugin roles to instances of a single Moo class

- [MooX::Roles::Pluggable](https://metacpan.org/pod/MooX::Roles::Pluggable)

    Package that applies plugin roles to a single Moo class

- [MooseX::Object::Pluggable](https://metacpan.org/pod/MooseX::Object::Pluggable)

    Package that applies plugin roles to instances of a single Moose class

# AUTHOR

Noel Maddy <zhtwnpanta@gmail.com>

# COPYRIGHT

Copyright 2016 Noel Maddy

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
