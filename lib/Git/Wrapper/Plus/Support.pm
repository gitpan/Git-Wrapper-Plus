use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Git::Wrapper::Plus::Support;
BEGIN {
  $Git::Wrapper::Plus::Support::AUTHORITY = 'cpan:KENTNL';
}
$Git::Wrapper::Plus::Support::VERSION = '0.003100';
# ABSTRACT: Determine what versions of things support what

use Moo qw( has );

















has 'git' => ( is => ro =>, required => 1 );

has 'versions' => ( is => ro =>, lazy => 1, builder => 1 );
has 'version'  => ( is => ro =>, lazy => 1, builder => 1 );

sub _build_versions {
  my ( $self, ) = @_;
  require Git::Wrapper::Plus::Versions;
  return Git::Wrapper::Plus::Versions->new( git => $self->git );
}

## no critic (ProhibitPackageVars)

our $command_db = {
  'for-each-ref' => [
    {
      'min'      => '1.4.4',
      'min_tag'  => '1.4.4-rc1',
      'min_sha1' => '9f613ddd21cbd05bfc139d9b1551b5780aa171f6',
    },
  ],
  'init' => [
    {
      'min'      => '1.5.0',
      'min_tag'  => '1.5.0-rc1',
      'min_sha1' => '515377ea9ec6192f82a2fa5c5b5b7651d9d6cf6c',
    },
  ],
  'update-cache' => [
    {
      'min'      => '0.99',
      'min_tag'  => '0.99',
      'min_sha1' => 'e83c5163316f89bfbde7d9ab23ca2e25604af290',
      'max'      => '1.0.0',
      'max_tag'  => '1.0.0',
      'max_sha1' => 'ba922ccee7565c949b4db318e5c27997cbdbfdba',
    },
  ],
  'update-index' => [
    {
      'min'      => '0.99.7',
      'min_tag'  => '0.99.7',
      'min_sha1' => '215a7ad1ef790467a4cd3f0dcffbd6e5f04c38f7',
    },
  ],
  'ls-remote' => [
    {
      'min'      => '0.99.2',
      'min_tag'  => '0.99.2',
      'min_sha1' => '0fec0822721cc18d6a62ab78da1ebf87914d4921',
    },
  ],
  'peek-remote' => [
    {
      'min'      => '0.99.2',
      'min_tag'  => '0.99.2',
      'min_sha1' => '18705953af75aed190badfccdc107ad0c2f36c93',
    },
  ],
};

my (@GIT_ZERO_LIST) = qw( init-db cat-file show-diff write-tree read-tree commit-tree );

for my $cmd (@GIT_ZERO_LIST) {
  $command_db->{$cmd} = [
    {
      'min'      => '0.99',
      'min_tag'  => '0.99',
      'min_sha1' => 'e83c5163316f89bfbde7d9ab23ca2e25604af290',
    },
  ];
}























sub supports_command {
  my ( $self, $command ) = @_;
  if ( not exists $command_db->{$command} ) {
    return;
  }
  for my $pair ( @{ $command_db->{$command} } ) {
    if ( exists $pair->{min} and not exists $pair->{max} ) {
      if ( $self->versions->newer_than( $pair->{min} ) ) {
        return 1;
      }
      return 0;
    }
    if ( exists $pair->{max} and not exists $pair->{min} ) {
      if ( $self->versions->older_than( $pair->{max} ) ) {
        return 1;
      }
      return 0;
    }
    if ( not exists $pair->{max} and not exists $pair->{min} ) {
      warn 'Bad quality command db entry with no range control';
      next;
    }
    next unless $self->versions->newer_than( $pair->{min} );
    next unless $self->versions->older_than( $pair->{max} );
    return 1;
  }
  return 0;
}





































our $behavior_db = {
  'add-updates-index' => [
    {
      'min'      => '1.5.0',
      'min_tag'  => '1.5.0-rc0',
      'min_sha1' => '366bfcb68f4d98a43faaf17893a1aa0a7a9e2c58',
    },
  ],
  'can-checkout-detached' => [
    {
      'min'      => '1.5.0',
      'min_tag'  => '1.5.0-rc1',
      'min_sha1' => 'c847f537125ceab3425205721fdaaa834e6d8a83',
    },
  ],
  '2-arg-cat-file' => [
    {
      'min_sha1' => 'bf0c6e839c692142784caf07b523cd69442e57a5',
      'min_tag'  => '0.99',
      'min'      => '0.99',
    },
  ],
};

sub supports_behavior {
  my ( $self, $beh ) = @_;
  if ( not exists $behavior_db->{$beh} ) {
    return;
  }
  for my $pair ( @{ $behavior_db->{$beh} } ) {
    if ( exists $pair->{min} and not exists $pair->{max} ) {
      if ( $self->versions->newer_than( $pair->{min} ) ) {
        return 1;
      }
      return 0;
    }
    if ( exists $pair->{max} and not exists $pair->{min} ) {
      if ( $self->versions->older_than( $pair->{max} ) ) {
        return 1;
      }
      return 0;
    }
    if ( not exists $pair->{max} and not exists $pair->{min} ) {
      warn 'Bad quality behavior db entry with no range control';
      next;
    }
    next unless $self->versions->newer_than( $pair->{min} );
    next unless $self->versions->older_than( $pair->{max} );
    return 1;
  }
  return 0;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Support - Determine what versions of things support what

=head1 VERSION

version 0.003100

=head1 SYNOPSIS

    use Git::Wrapper::Plus::Support;

    my $support = Git::Wrapper::Plus::Support->new(
        git => <git::wrapper>
    );
    if ( $support->supports_command( 'for-each-ref' ) ) {

    }
    if ( $support->supports_behavior('add-updates-index') ) {

    }

=head1 METHODS

=head2 C<supports_command>

Determines if a given command is supported on the current git.

This works by using a hand-coded table for interesting values
by processing C<git log> for git itself.

Returns C<undef> if the status of a command is unknown ( that is, has not been added
to the map yet ), C<0> if it is not supported, and C<1> if it is.

    if ( $supporter->supports_command('for-each-ref') ) ) {
        ...
    } else {
        ...
    }

B<Currently indexed commands>

    for-each-ref init init-db

=head2 C<supports_behavior>

Indicates if a given command behaves in a certain way

This works by using a hand-coded table for interesting values
by processing C<git log> for git itself.

Returns C<undef> if the status of a commands behavior is unknown ( that is, has not been added
to the map yet ), C<0> if it is not supported, and C<1> if it is.

    if ( $supporter->supports_behavior('add-updates-index') ) ) {
        ...
    } else {
        ...
    }

B<Current behaviors>

=head4 C<add-updates-index>

Older versions of git required you to do:

    git update-index $FILE

Instead of

    git add $FILE

To update content.

=head4 C<can-checkout-detached>

Not all versions of Git can checkout a detached head.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
