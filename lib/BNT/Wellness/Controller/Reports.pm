package BNT::Wellness::Controller::Reports;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $self = shift;
  $self->render(measurements => $self->model('Measurements'), surveys => $self->model('Surveys'));
}

1;
