package BNT::Wellness::Plugin::DB;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::SQLite;
use Mojo::Util 'decamelize';

my ($base) = (__PACKAGE__ =~ /^(.+)::Plugin/);

sub register {
  my ($self, $app, $conf) = @_;

  # create a helper method which makes it easy to access your models
  # the model Config is passed to all models, EXCEPT the config model,
  # and in the case of the Config model, it's passed the app's config (moniker.conf)
  # Confused?  Sorry.
  $app->helper(sqlite => sub { state $sqlite = Mojo::SQLite->new(shift->config('sqlite')) });
  $app->helper('db.config' => sub {
    my $c = shift;
    return BNT::Wellness::Model::Config->new(sqlite => $c->sqlite, app_config => $c->config, @_)
  });
  $app->helper('db.participants' => sub {
    my $c = shift;
    return BNT::Wellness::Model::Participants->new(sqlite => $c->sqlite, config => $c->db->config, @_)
  });
  $app->helper('db.kv' => sub {
    my $c = shift;
    my $kv = join '::', $base, 'Model', 'KV', shift;
    Mojo::Loader::load_class($kv);
    return $kv->new(sqlite => $c->sqlite, config => $c->db->config, @_);
  });

  # Migrate to latest version if necessary
  my $path = $app->home->rel_file(sprintf 'migrations/%s.sql', $app->moniker);
  $app->sqlite->migrations->name($app->moniker)->from_file($path)->migrate;
}

1;
