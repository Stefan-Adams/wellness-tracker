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
  my ($self, $period, $measurement, $where) = @_;
  $where ||= {};
  $where->{date} = [-and => {'>=' => $period->start}, {'<' => $period->end}];
  my $results = $self->sqlite->db->query($self->sql->select('measurements', [qw(uid date v)], {k => $measurement, %$where}, [qw(uid date)]));
  BNT::Wellness::Collection->new($results->hashes->map(sub{$_ = BNT::Wellness::Model::Measurement->new($_)})->each);
  #_nested_collection(_grouped_hash($results));
}

1;
