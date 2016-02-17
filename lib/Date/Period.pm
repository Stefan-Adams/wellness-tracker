package Date::Period;
use Mojo::Base -base;

use Date::Simple 'date';

has [qw(start end)];

# If the first parameter is an arrayref use that, otherwise use the first two elements;
# Make these elements available via start and end attributes
sub new {
  my $self = shift->SUPER::new;
  die "Incomplete date range\n" unless @_;
  my $period = ref $_[0] eq 'ARRAY' ? $_[0] : \(shift, shift);
  my ($start, $end) = @$period;
  die "Incomplete date range\n" unless $start && $end;
  $self->start(date($start));
  $self->end(date($end));
}

1;
