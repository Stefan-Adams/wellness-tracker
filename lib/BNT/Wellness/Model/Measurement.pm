package BNT::Wellness::Model::Measurement;
use Mojo::Base -base;

use Date::Simple;

use overload '""' => sub { $_[0]->can('v') ? $_[0]->v : $_[0] }, fallback => 1;

#has [qw(uid date k v)];

sub new {
  my $self = shift->SUPER::new;
  local %_ = %{+shift};
  foreach ( keys %_ ) {
    next unless length $_{$_};
    $_{$_} = sub { Date::Simple->new($_{$_}) } if $_{$_} =~ /^\d{2,4}\W\d{2}\W\d{2,4}$/;
    has $_;
    $self->$_($_{$_});
  }
  $self;
}

1;
