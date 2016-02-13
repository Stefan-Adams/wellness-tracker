package Date::Period;
use Mojo::Base -base;

use Date::Simple 'date';

has [qw(start end)];

sub new {
  my $self = shift->SUPER::new;
  die "Incomplete date range\n" unless $_[0]->[0] && $_[0]->[1];
  $self->start(date($_[0]->[0]));
  $self->end(date($_[0]->[1]));
}

1;
