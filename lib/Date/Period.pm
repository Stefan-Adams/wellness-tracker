package Date::Period;
use Mojo::Base -base;

use Date::Simple 'date';

has [qw(start end)];

sub new {
  my $self = shift->SUPER::new;
  my $period = shift;
  my ($start, $end) = @$period;
  die "Incomplete date range\n" unless $start && $end;
  $self->start(date($start));
  $self->end(date($end));
}

1;
