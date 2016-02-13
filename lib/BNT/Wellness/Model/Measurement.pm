package BNT::Wellness::Model::Measurement;
use Mojo::Base -base;

use Date::Simple;

has [qw(uid date k v)];

sub new {
  my $self = shift->SUPER::new(@_);
  $self->date(Date::Simple->new($self->date)) if $self->date =~ /^\d{2,4}\W\d{2}\W\d{2,4}$/;
  $self;
}

1;
