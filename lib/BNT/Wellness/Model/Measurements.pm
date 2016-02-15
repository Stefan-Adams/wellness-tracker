package BNT::Wellness::Model::Measurements;
use BNT::Wellness::Model -base;

col [qw(uid date k v)];

sub first { shift->_first_or_last_kv(min => @_) }
sub last { shift->_first_or_last_kv(max => @_) }

sub _first_or_last_kv_bmi {
  my ($self, $agg, $table, $k, $period) = @_;
  qq[select *,((weight*703)/(height*height)) v from (select uid,last_name,first_name,$agg(date) date,v weight from measurements left join participants using (uid) where k='weight' and date >= ? and date < ? group by uid order by last_name) a left join (select uid,$agg(date) date,v height from measurements left join participants using (uid) where k='height' and date >= ? and date < ? group by uid order by last_name) b using (uid)], $period->start, $period->end, $period->start, $period->end
}

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
