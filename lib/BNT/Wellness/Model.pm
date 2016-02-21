package BNT::Wellness::Model;
use Mojo::Base -base;

use Mojo::Loader 'data_section';

use BNT::Wellness::Collection;
use BNT::Wellness::Model::GenericRecord;

has 'config'; # *::Model::Config, which has access to app's config
has 'sqlite';
has bind => sub { [] };

use SQL::Abstract;
use SQL::Interp;
has sql_abstract => sub { SQL::Abstract->new };
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

##################

#sub clear_all {
#  my $self = shift;
#  my $table = $self->table;
#  return $self->sqlite->db->query("delete from $table");
#}

sub add {
  my $self = shift;
  my $data = shift;
  die "no record data provided to add" unless $data && ref $data eq 'HASH';
  return $self->sqlite->db->query($self->sql->insert($self->table, $data));
}

sub fetch {
  my ($self, $measurement, $period, $where) = @_;
  die unless $measurement;
  $where ||= {};
  $where->{date} = [-and => {'>=' => $period->start}, {'<' => $period->end}];
  my $results = $self->sqlite->db->query($self->sql->select('measurements', [qw(uid date v)], {k => $measurement, %$where}, [qw(uid date)]));
  $self->_hashes_to_objects($results->hashes);
}

sub AUTOLOAD {
  my $self = shift;
  my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  $self->_sql_from_data($method, @_);
}

sub _sql_from_data {
  my ($self, $name, %args) = @_;
  $args{table} ||= $self->table;
  my $query = BNT::Wellness::Model::query->new(table => $self->table);
  $query->sql(Mojo::Template->new->name("template $name from ${\(ref $self)} DATA section")->render(data_section(ref $self, $name), table => $self->table, %args, query => $query));
  return $self->sqlite->db->query($query->generate);
}

##################

use Mojo::Collection;

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
#_nested_collection(_grouped_hash($results));
sub _nested_collection {
  my $hash = shift;
  return $hash unless ref $hash eq 'HASH';
  my $c = Mojo::Collection->new;
  foreach ( keys %$hash ) {
    push @$c, Mojo::Collection->new({$_ => _nested_collection($hash->{$_})});
  }
  $c;
}

package BNT::Wellness::Model::query;
use Mojo::Base -base;

has sql => '';
has bind => sub { [] };
sub generate ($self) { $self->sql, @{$self->bind} } 

1;

__DATA__
@@ clear_all.sql.ep
delete from $table