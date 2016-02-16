package BNT::Wellness::Model::Config;
use BNT::Wellness::Model -base;

use constant DB_CONFIG => 0;

has 'config'; # app config (e.g. moniker.conf)

has current_period => sub { state $current_period = Date::Period->new(DB_CONFIG ? shift->get('db_current_period') : shift->config->{periods}->[0]) };

sub get {
  my ($self, $key) = @_;
  $self->sqlite->db->query(qq(select v from config where k = ?", $key))->hash->{v};
}

1;
