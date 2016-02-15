package BNT::Wellness::Plugin::DB;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::SQLite;
use Mojo::Util 'decamelize';

sub register {
  my ($self, $app, $conf) = @_;

  # create a helper method which makes it easy to access your models
  # the model Config is passed to all models, EXCEPT the config model,
  # and in the case of the Config model, it's passed the app's config (moniker.conf)
  # Confused?  Sorry.
  $app->helper(sqlite => sub { state $sqlite = Mojo::SQLite->new(shift->config('sqlite')) });
  $app->helper(model => sub {
    my $c = shift;
    my $model = _model_class(shift);
    return $model->new(sqlite => $c->sqlite, @_) if $model eq 'Config';
    return $model->new(sqlite => $c->sqlite, config => $c->model('Config', config => $c->config), @_);
  });

  # Migrate to latest version if necessary
  my $path = $app->home->rel_file(sprintf 'migrations/%s.sql', $app->moniker);
  $app->sqlite->migrations->name($app->moniker)->from_file($path)->migrate;
}

sub _model_class {
  my ($base) = (__PACKAGE__ =~ /^(.+)::Plugin/);
  $base = "${base}::Model";
  my $model = join '::', $base, shift;
  Mojo::Loader::load_class($model);
  return $model;
}  

1;
