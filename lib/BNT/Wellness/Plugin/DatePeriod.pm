package BNT::Wellness::Plugin::DatePeriod;
use Mojo::Base 'Mojolicious::Plugin';

use Date::Period;

sub register {
  my ($self, $app, $conf) = @_;

  $app->helper(period1 => sub { Date::Period->new(shift->app->config->{periods}->{$conf->[0]}) });
  $app->helper(period2 => sub { Date::Period->new(shift->app->config->{periods}->{$conf->[1]}) });
}

1;
