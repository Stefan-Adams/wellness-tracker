package BNT::Wellness::Model::GenericRecord;
use Mojo::Base -base;

use 5.020;
use features qw(signatures);

# This Model stringifies to the method defined by the '""' stringify hashkey and converts anything that looks like a date to a Date::Simple
# Every key that it is given it makes accessible as an attribute
# TODO: better date detection

use Date::Simple;

use overload '""' => sub ($self) { my $method = $self->stringify; $method && $self->can($method) ? $self->$method : $self }, fallback => 1;

has 'stringify';

sub new {
  my $self = shift->SUPER::new;
  local %_ = %{+shift};
  $_ and $self->stringify($_) for delete $_{'""'};
  foreach ( keys %_ ) {
    has $_;
    next unless length $_{$_};
    $_{$_} = sub { Date::Simple->new($_{$_}) } if $_{$_} =~ /^\d{2,4}\W\d{2}\W\d{2,4}$/;
    $self->$_($_{$_});
  }
  $self;
}

1;
