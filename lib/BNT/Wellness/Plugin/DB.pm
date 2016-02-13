package BNT::Wellness::Plugin::DB;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::SQLite;
use Mojo::Util 'decamelize';

sub register {
  my ($self, $app, $conf) = @_;

  my ($base) = (__PACKAGE__ =~ /(.*?)::Plugin/);

  # create a helper method which makes it easy to access your models
  $app->helper(sqlite => sub { state $sqlite = Mojo::SQLite->new(shift->config('sqlite')) });
  $app->helper(model => sub {
    my $c = shift;
    my $model = "${base}::Model::".shift;
    Mojo::Loader::load_class($model);
    return $model->new(sqlite => $c->sqlite, @_);
  });

  # Migrate to latest version if necessary
  my $path = $app->home->rel_file(sprintf 'migrations/%s.sql', decamelize($base));
  $app->sqlite->migrations->name(decamelize($base))->from_file($path)->migrate;
}

1;
