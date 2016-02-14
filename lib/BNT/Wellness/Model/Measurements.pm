package BNT::Wellness::Model::Measurements;
use BNT::Wellness::Model -base;

col [qw(uid date k v)];

sub first { shift->_first_or_last_kv(min => @_) }
sub last { shift->_first_or_last_kv(max => @_) }

### Probably drop this?

sub fetch {
  my ($self, $measurement, $period, $where) = @_;
  die unless $measurement;
  $where ||= {};
  $where->{date} = [-and => {'>=' => $period->start}, {'<' => $period->end}];
  my $results = $self->sqlite->db->query($self->sql->select('measurements', [qw(uid date v)], {k => $measurement, %$where}, [qw(uid date)]));
  $self->_hashes_to_objects($results->hashes);
  #_nested_collection(_grouped_hash($results));
}

1;
