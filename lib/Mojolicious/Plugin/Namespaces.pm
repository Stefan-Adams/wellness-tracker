package Mojolicious::Plugin::Namespaces;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $conf) = @_;

  my $package = ref $app;

  unshift @{$app->plugins->namespaces}, "${package}::Plugin";
  unshift @{$app->commands->namespaces}, "${package}::Command";
}

1;
