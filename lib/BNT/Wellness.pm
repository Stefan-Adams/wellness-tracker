package BNT::Wellness;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  # Configuration
  $self->plugin('Config');
  $self->secrets($self->config('secrets'));

  # Load Custom Plugins and Commands
  $self->plugin('Namespaces');
  $self->plugin('DB');
  $self->plugin('Routes');
}

1;
