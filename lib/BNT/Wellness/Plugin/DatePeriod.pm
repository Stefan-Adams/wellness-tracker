package BNT::Wellness::Plugin::DatePeriod;
use Mojo::Base 'Mojolicious::Plugin';

use Date::Period;

sub register {
  my ($self, $app, $conf) = @_;

  #my $period = $self->app->model('Config')->get('current_period');
  my $period = join ',', @{$app->config->{periods}->{$conf->[0]}};
  $app->helper(current_period => sub { Date::Period->new([split /,/, $period, 2]) });
  $app->helper(period1 => sub { Date::Period->new(shift->app->config->{periods}->{$conf->[0]}) });
  $app->helper(period2 => sub { Date::Period->new(shift->app->config->{periods}->{$conf->[1]}) });
}

1;
