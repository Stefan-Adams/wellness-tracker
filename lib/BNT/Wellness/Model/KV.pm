package BNT::Wellness::Model::KV;
use BNT::Wellness::Model -base;

use v5.20;
use features qw(signatures);

# "first" and "last" (based on date) value for each uid

# These are the primary fetching routines for Measurements.
# Everything uses a group by uid and a max/min (last/first) aggregate on date and returns the specific measurement requested.
# Limits the results to a specific period, if requested.

# TODO: How to better handle all the SQL here?  There's a lot of repetition.
# Oh well.  Move on.  Abstract later.

# Grab each uid's first $measurement from the group by
sub _first_or_last ($self, %args) {
  die "no agg requested" unless $args{agg};
  die "no key requested" unless $args{k};
  $args{period} ||= $self->config->current_period;
  my $sql_name = "first_or_last_$args{k}";
  $self->can($sql_name) or $sql_name = 'first_or_last'
  BNT::Wellness::Collection->new->stringify('v')->objectify($self->$sql_name(%args)->hashes);
}
sub first ($self, $agg, $k, $period) { $self->_first_or_last(min => (agg => $agg, k => $k, period => $period)) }
sub last ($self, $agg, $k, $period) { $self->_first_or_last(max => (agg => $agg, k => $k, period => $period)) }

1;

__DATA__
@@ reset_db.sql.ep
drop table if exists $table;
create table $table (id integer primary key autoincrement, uid text, date text, k text, v text);

@@ first_or_last.sql.ep
% $query->bind([$k, $period->start, $period->end]);
select uid,last_name,first_name,$agg(date) date,v from $table left join participants using (uid) where k = ? and date >= ? and date < ? group by uid order by last_name
