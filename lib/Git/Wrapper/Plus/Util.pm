use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Git::Wrapper::Plus::Util;
BEGIN {
  $Git::Wrapper::Plus::Util::AUTHORITY = 'cpan:KENTNL';
}
$Git::Wrapper::Plus::Util::VERSION = '0.003000';
# ABSTRACT: Misc plumbing tools for Git::Wrapper::Plus

use Sub::Exporter::Progressive -setup => {
  exports => [qw( exit_status_handler )],
  groups  => {
    default => [qw( exit_status_handler )],
  },
};

use Try::Tiny qw( try catch );
use Scalar::Util qw(blessed);

































sub exit_status_handler {
  my ( $callback, $status_map ) = @_;
  my $return = 1;
  try {
    $callback->();
  }
  catch {
    ## no critic (ErrorHandling::RequireUseOfExceptions)
    undef $return;
    if ( not ref $_ ) {
      die $_;
    }
    if ( not blessed $_ ) {
      die $_;
    }
    if ( not $_->isa('Git::Wrapper::Exception') ) {
      die $_;
    }
    for my $status ( sort keys %{$status_map} ) {
      if ( $status == $_->status ) {
        $return = $status_map->{$status}->($_);
        return;
      }
    }
    die $_;
  };
  return 1 if $return;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Wrapper::Plus::Util - Misc plumbing tools for Git::Wrapper::Plus

=head1 VERSION

version 0.003000

=head1 FUNCTIONS

=head2 C<exit_status_handler>

C<Git::Wrapper> throws exceptions in a few cases, and some of these
cases are considered normal flow control for C<Git::Wrapper::Plus>.

For instance, some functions in C<git> emit no output, and return an exit code.

C<Git::Wrapper> treats that circumstance as a fatal exception!.

Its messy getting all the right C<try/catch> stuff going, and checking
for the object type, and then checking if the exception type is recognized or not,
and only then determining if the status was white-listed.

So:

    use Git::Wrapper::Plus::Util qw(exit_status_handler);

    my $ok = exit_status_handler ( $code , {
        1 => sub { undef }
    });

The above code normally executes C<$code>, and returns C<1> if no exception occurred.

If an exception occurred, and it is not a C<Git::Wrapper::Exception>, it is simply re-thrown.

And for any status codes listed in the map, the attached C<sub> is executed, and C<exit_status_handler>
propagates its return value.

Any other circumstances ( like a status code not existing in the map ) are simply re-thrown.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
