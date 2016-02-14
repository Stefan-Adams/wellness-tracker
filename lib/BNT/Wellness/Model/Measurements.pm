package BNT::Wellness::Model::Measurements;
use Mojo::Base 'BNT::Wellness::Model';

has uid_col => 'participant_code';
has date_col => 'measurement_date';
has types => sub { [qw(weight height waist wrist body_fat body_water muscle_mass visceral_fat bmr metabolic_age bone_mass physique)] };

use BNT::Wellness::Model::Measurement;

sub clear_all {
  my $self = shift;
  return $self->sqlite->db->query("delete from measurements");
}

sub add {
  my ($self, $row) = @_;
  foreach my $type ( grep { $row->{$_} } @{$self->types} ) {
    $self->sqlite->db->query($self->sql->insert('measurements', {uid => $row->{$self->uid_col}, date => $row->{$self->date_col}, k => $type, v => $row->{$type}}));
    #BNT::Wellness::Model::Measurement->new(db => $self->sqlite->db, uid => $row->{$self->uid_col}, date => $row->{$self->date_col}, k => $type, v => $row->{$type})->save;
  }
}

sub fetch {
  my ($self, $measurement, $period, $where) = @_;
  die unless $measurement;
  $where ||= {};
  $where->{date} = [-and => {'>=' => $period->start}, {'<' => $period->end}];
  my $results = $self->sqlite->db->query($self->sql->select('measurements', [qw(uid date v)], {k => $measurement, %$where}, [qw(uid date)]));
  _hashes_to_objects($results->hashes);
  #_nested_collection(_grouped_hash($results));
}

sub first {
  my ($self, $measurement, $period) = @_;
  die unless $measurement;
  my $results;
  if ( $period ) {
    if ( $measurement eq 'bmi' ) {
      $results = $self->sqlite->db->query(q[select *,((weight*703)/(height*height)) v from (select uid,last_name,first_name,min(date) date,v weight from measurements left join participants using (uid) where k='weight' and date >= '2015-02-01' and date < '2015-04-30' group by uid order by last_name) a left join (select uid,min(date) date,v height from measurements left join participants using (uid) where k='height' and date >= '2015-02-01' and date < '2015-04-30' group by uid order by last_name) b using (uid)]);
    } else {
      $results = $self->sqlite->db->query(q[select uid,last_name,first_name,min(date) date,v from measurements left join participants using (uid) where k = ? and date >= ? and date < ? group by uid order by last_name], $measurement, $period->start, $period->end);
    }
  } else {
    if ( $measurement eq 'bmi' ) {
      $results = $self->sqlite->db->query(q[select *,((weight*703)/(height*height)) v from (select uid,last_name,first_name,min(date) date,v weight from measurements left join participants using (uid) where k='weight' group by uid order by last_name) a left join (select uid,min(date) date,v height from measurements left join participants using (uid) where k='height' group by uid order by last_name) b using (uid)]);
    } else {
      $results = $self->sqlite->db->query(q[select uid,last_name,first_name,min(date) date,v from measurements left join participants using (uid) where k = ? group by uid order by last_name], $measurement);
    }
  }
  _hashes_to_objects($results->hashes);
}

sub last {
  my ($self, $measurement, $period) = @_;
  die unless $measurement;
  my $results;
  if ( $period ) {
    if ( $measurement eq 'bmi' ) {
      $results = $self->sqlite->db->query(q[select *,((weight*703)/(height*height)) v from (select uid,last_name,first_name,max(date) date,v weight from measurements left join participants using (uid) where k='weight' and date >= '2015-02-01' and date < '2015-04-30' group by uid order by last_name) a left join (select uid,max(date) date,v height from measurements left join participants using (uid) where k='height' and date >= '2015-02-01' and date < '2015-04-30' group by uid order by last_name) b using (uid)]);
    } else {
      $results = $self->sqlite->db->query(q[select uid,last_name,first_name,max(date) date,v from measurements left join participants using (uid) where k = ? and date >= ? and date < ? group by uid order by last_name], $measurement, $period->start, $period->end);
    }
  } else {
    if ( $measurement eq 'bmi' ) {
      $results = $self->sqlite->db->query(q[select *,((weight*703)/(height*height)) v from (select uid,last_name,first_name,max(date) date,v weight from measurements left join participants using (uid) where k='weight' group by uid order by last_name) a left join (select uid,max(date) date,v height from measurements left join participants using (uid) where k='height' group by uid order by last_name) b using (uid)]);
    } else {
      $results = $self->sqlite->db->query(q[select uid,last_name,first_name,max(date) date,v from measurements left join participants using (uid) where k = ? group by uid order by last_name], $measurement);
    }
  }
  _hashes_to_objects($results->hashes);
}

sub _hashes_to_objects {
  my $hashes = shift;
  BNT::Wellness::Collection->new($hashes->map(sub{$_ = BNT::Wellness::Model::Measurement->new($_)})->each);
}

1;
