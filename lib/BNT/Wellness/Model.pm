package BNT::Wellness::Model;
use Mojo::Base -base;

use BNT::Wellness::Collection;

use SQL::Abstract;
use SQL::Interp;

has 'sqlite';
has sql => sub { SQL::Abstract->new };
sub sql_interp { SQL::Interp::sql_interp(@_) }

has uid_col => 'participant_code';

sub report {
  my $self = shift;
  say "R E P O R T";
}

# Does not support arbitrary grouping depth.  How do to so?
sub _grouped_hash {
  my $results = shift;
  my $data = {};
  while ( my $next = $results->hash ) {
    $data->{$next->{uid}}->{$next->{date}} = $next;
  }
  $data;
}

# Cool little recursion sub, not sure about the value of it. 
sub _nested_collection {
  my $hash = shift;
  return $hash unless ref $hash eq 'HASH';
  my $c = Mojo::Collection->new;
  foreach ( keys %$hash ) {
    push @$c, Mojo::Collection->new({$_ => _nested_collection($hash->{$_})});
  }
  $c;
}

1;
