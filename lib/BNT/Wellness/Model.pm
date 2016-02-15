package BNT::Wellness::Model;
use Mojo::Base -base;

use Mojo::Collection;

use BNT::Wellness::Collection;
use BNT::Wellness::Model::GenericRecord;

use SQL::Abstract;
use SQL::Interp;

has 'config'; # *::Model::Config, which has access to app's config
has 'sqlite';
has sql => sub { SQL::Abstract->new };
sub sql_interp { SQL::Interp::sql_interp(@_) }

##################

my (%COLUMNS, %LOADED, %PK);

sub import {
  my $class = shift;
  return unless my $flag = shift;

  if    ($flag eq '-base')   { $flag = $class }
  elsif ($flag eq '-strict') { $flag = undef }
  elsif ((my $file = $flag) && !$flag->can('new')) {
    $file =~ s!::|'!/!g;
    require "$file.pm";
  }
  if ($flag) {
    my $caller = caller;
    my $table = Mojo::Util::decamelize((split /::/, $caller)[-1]);
    $table =~ s!s?$!s!;    # user => users
    Mojo::Util::monkey_patch($caller, col      => sub { $caller->_define_col(@_) });
    Mojo::Util::monkey_patch($caller, columns  => sub { @{$COLUMNS{$caller} || []} });
    Mojo::Util::monkey_patch($caller, table    => sub { $table = $_[0] unless UNIVERSAL::isa($_[0], $caller); $table });
    Mojo::Util::monkey_patch($caller, pk       => sub { return UNIVERSAL::isa($_[0], $caller) ? $PK{$caller} : $caller->_define_pk(@_) });
    no strict 'refs';
    push @{"${caller}::ISA"}, $flag;
  }
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');
}
sub _define_col {
  my $class = ref($_[0]) || $_[0];
  push @{$COLUMNS{$class}}, ref $_[0] eq 'ARRAY' ? @{$_[1]} : $_[1];
  Mojo::Base::attr(@_);
}
sub _define_pk {
  my $class = ref($_[0]) || $_[0];
  $PK{$class} = $_[1];
  Mojo::Base::attr(@_);
}
sub _pk_or_first_column { $_[0]->pk || ($_[0]->columns)[0] }

sub clear_all {
  my $self = shift;
  my $table = $self->table;
  return $self->sqlite->db->query("delete from $table");
}

sub add {
  my $self = shift;
  my $data = shift;
  die "no record data provided to add" unless $data && ref $data eq 'HASH';
  return $self->sqlite->db->query($self->sql->insert($self->table, $data));
}

# "first" and "last" (based on date) value for each uid

# These are the primary fetching routines for Measurements.
# Everything uses a group by uid and a max/min (last/first) aggregate on date and returns the specific measurement requested.
# Limits the results to a specific period, if requested.

# TODO: How to better handle all the SQL here?  There's a lot of repetition.
# Oh well.  Move on.  Abstract later.

# Grab each uid's first $measurement from the group by
sub _first_or_last_kv {
  my ($self, $agg, $k, $period) = @_;
  die unless $k;
  my $table = $self->table;
  my $period ||= $self->config->current_period;
  my $results;
  my $method = "_first_or_last_kv_$type";
  if ( $self->can($method) ) {
    $results = $self->sqlite->db->query($self->$method($agg, $table, $k, $period));
  } else {
    $results = $self->sqlite->db->query(qq[select uid,last_name,first_name,$agg(date) date,v,'v' as '""' from $table left join participants using (uid) where k = ? and date >= ? and date < ? group by uid order by last_name], $k, $period->start, $period->end);
  }
  $self->_hashes_to_objects($results->hashes);
}

# Makes each row of data a BNT::Wellness::Model::GenericRecord object
# The stringify form of the object is determined by the '""' hashkey from the SQL statement
#   e.g.  select *,'uid' as '""'
# Would make access to the object as a string via the 'uid' method.
sub _hashes_to_objects {
  my $self = shift;
  my $hashes = shift;
  BNT::Wellness::Collection->new($hashes->map(sub{$_ = BNT::Wellness::Model::GenericRecord->new($_)})->each);
} 

##################

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
