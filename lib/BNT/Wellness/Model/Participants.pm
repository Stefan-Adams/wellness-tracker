package BNT::Wellness::Model::Participants;
use Mojo::Base 'BNT::Wellness::Model';

sub clear_all {
  my $self = shift;
  return $self->sqlite->db->query("delete from measurements");
}

sub add {
  my ($self, $row) = @_;
  $self->sqlite->db->query($self->sql->insert('participants', {
    uid => $row->{participant_code},
    last_name => $row->{last_name},
    first_name => $row->{first_name},
    gender => $row->{gender},
  }));
}

sub fetch {
  my ($self, $measurement, $where) = @_;
  $where ||= {};
  Mojo::Collection->new($self->sqlite->db->query($self->sql->select('participants', [qw(uid date k v)], {k => $measurement, %$where}, [qw(uid date)]))->hashes->to_array);
}

1;
