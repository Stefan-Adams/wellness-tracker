package BNT::Wellness::Model;
use Mojo::Base -base;

use Mojo::Collection;

use BNT::Wellness::Collection;
use BNT::Wellness::Model::GenericRecord;

use SQL::Abstract;
use SQL::Interp;

has 'config'; # Used only by Import routines
has 'sqlite';
has sql => sub { SQL::Abstract->new };
sub sql_interp { SQL::Interp::sql_interp(@_) }

##################

my (%COLUMNS);

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
    Mojo::Util::monkey_patch($caller, col => sub { $caller->_define_col(@_) });
    Mojo::Util::monkey_patch($caller, columns  => sub { @{$COLUMNS{$caller} || []} });
    Mojo::Util::monkey_patch($caller, table => sub { $table = $_[0] unless UNIVERSAL::isa($_[0], $caller); $table });
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

sub clear_all {
  my $self = shift;
  my $table = $self->table;
  return $self->sqlite->db->query("delete from $table");
}

sub add {
  my $self = shift;
  my $table = $self->table;
  #return $self->sqlite->db->query("insert into $table ...");
}

# "first" and "last" (based on date) value for each uid

# These are the primary fetching routines for Measurements.
# Everything uses a group by uid and a max/min (last/first) aggregate on date and returns the specific measurement requested.
# Limits the results to a specific period, if requested.

# TODO: How to better handle all the SQL here?  There's a lot of repetition.
# Oh well.  Move on.  Abstract later.

# Grab each uid's first $measurement from the group by
sub _first_or_last_kv {
  my ($self, $agg, $type, $period) = @_;
  die unless $type;
  my $table = $self->table;
  my $results;
  if ( $type eq 'bmi' ) {
    # Need to move this to the specific Model
    if ( $period ) {
      $results = $self->sqlite->db->query(qq[select *,((weight*703)/(height*height)) v from (select uid,last_name,first_name,$agg(date) date,v weight from measurements left join participants using (uid) where k='weight' and date >= '2015-02-01' and date < '2015-04-30' group by uid order by last_name) a left join (select uid,$agg(date) date,v height from measurements left join participants using (uid) where k='height' and date >= '2015-02-01' and date < '2015-04-30' group by uid order by last_name) b using (uid)]);
    } else {
      $results = $self->sqlite->db->query(qq[select *,((weight*703)/(height*height)) v from (select uid,last_name,first_name,$agg(date) date,v weight from measurements left join participants using (uid) where k='weight' group by uid order by last_name) a left join (select uid,$agg(date) date,v height from measurements left join participants using (uid) where k='height' group by uid order by last_name) b using (uid)]);
    }
  } else {
    if ( $period ) {
      $results = $self->sqlite->db->query(qq[select uid,last_name,first_name,$agg(date) date,v from $table left join participants using (uid) where k = ? and date >= ? and date < ? group by uid order by last_name], $type, $period->start, $period->end);
    } else {
      $results = $self->sqlite->db->query(qq[select uid,last_name,first_name,$agg(date) date,v from $table left join participants using (uid) where k = ? group by uid order by last_name], $type);
    }
  }
  $self->_hashes_to_objects($results->hashes);
}

##################

# Makes each row of data a BNT::Wellness::Model::GenericRecord object
sub _hashes_to_objects {
  my $self = shift;
  my $hashes = shift;
  BNT::Wellness::Collection->new($hashes->map(sub{$_ = BNT::Wellness::Model::GenericRecord->new($_)})->each);
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
