package BNT::Wellness::Model::Surveys;
use Mojo::Base 'BNT::Wellness::Model';

use BNT::Wellness::Model::Survey;

has uid_col => 'participant_code';
has date_col => 'survey_date';
has types => sub { [qw(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20)] };

sub clear_all {
  my $self = shift;
  return $self->sqlite->db->query("delete from surveys");
}

sub add {
  my ($self, $row) = @_;
  foreach my $type ( grep { $row->{$_} } @{$self->types} ) {
    $self->sqlite->db->query($self->sql->insert('surveys', {uid => $row->{$self->uid_col}, date => $row->{$self->date_col}, k => $type, v => $row->{$type}}));
    #BNT::Wellness::Model::Measurement->new(db => $self->sqlite->db, uid => $row->{$self->uid_col}, date => $row->{$self->date_col}, k => $type, v => $row->{$type})->save;
  }
}

sub fetch {
  my ($self, $period, $survey, $where) = @_;
  $where ||= {};
  $where->{date} = [-and => {'>=' => $period->start}, {'<' => $period->end}];
  my $results = $self->sqlite->db->query($self->sql->select('surveys', [qw(uid date v)], {k => $survey, %$where}, [qw(uid date)]));
  BNT::Wellness::Collection->new($results->hashes->map(sub{$_ = BNT::Wellness::Model::Survey->new($_)})->each);
  #_nested_collection(_grouped_hash($results));
}

1;
