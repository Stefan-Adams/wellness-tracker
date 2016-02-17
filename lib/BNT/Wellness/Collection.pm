package BNT::Wellness::Collection::group_by;
use Mojo::Base -base;

has [qw(pk collection)];

sub AUTOLOAD {
  my $self = shift;
  my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  $self->collection->$method(@_);
}

#sub first { shift->collection->first }
#sub last { shift->collection->last }

package BNT::Wellness::Collection::Objectify;
use Mojo::Base -base;

use 5.020;
use features qw(signatures);

# This Model stringifies to the method defined by the '""' stringify hashkey and converts anything that looks like a date to a Date::Simple
# If no stringify method is provided, the stringified form of the object returns the number of keys
# Every key that it is given it makes accessible as an attribute
# TODO: better date detection

use Date::Simple;

use overload '""' => sub ($self) { my $method = $self->stringify; $method && $self->can($method) ? $self->$method : keys %$self }, fallback => 1;

has 'stringify';

sub new {
  my $self = shift->SUPER::new;
  local %_ = %{+shift};
  $_ and $self->stringify($_) for delete $_{'""'};
  foreach ( keys %_ ) {
    has $_;
    next unless length $_{$_};
    $_{$_} = sub { Date::Simple->new($_{$_}) } if $_{$_} =~ /^\d{2,4}\W\d{2}\W\d{2,4}$/;
    $self->$_($_{$_});
  }
  $self;
}

package BNT::Wellness::Collection;
use Mojo::Base 'Mojo::Collection';

use Date::Simple 'date';
use Date::Range;

has 'stringify';

# Makes each row of data a BNT::Wellness::Collection::GenericRecord object
# The stringify form of the object is determined by the '""' hashkey from the SQL statement
#   e.g.  select *,'uid' as '""'
# Would make access to the object as a string via the 'uid' method.
sub objectify {
  my $self = shift;
  my $collection = shift;
  if ( ref $collection->isa('Mojo::Collection') ) {
    my $record = "${package}::Objectify";
    return $self->new(@$self, $collection->map(sub{$_ = $record->new({@_, stringify => $self->stringify, %$_})})->each);
  }
}

sub item { shift->slice(shift)->first }
sub shift { shift @{$_[0]} }
sub unshift { unshift @{$_[0]}, $_[1..-1] }
sub pop { pop @{$_[0]} }
sub push { push @{$_[0]}, @_[1..-1] }

sub datesort { $_[0]->sort(sub{no warnings; $a->date <=> $b->date}) }

sub within_periods {
  my ($self, $csv) = (shift, shift);
  my $grep = $self->grep(sub{!$_->date || ($_->date >= $csv->period1->start && $_->date <= $csv->period1->end) || ($_->date >= $csv->period2->start && $_->date <= $csv->period2->end)});
  if ( grep { $_ == 1 } @_ ) {
    $grep = $grep->grep(sub{!$_->date || $_->date >= $csv->period1->start && $_->date <= $csv->period1->end});
  } elsif ( grep { $_ == 2 } @_ ) {
    $grep = $grep->grep(sub{!$_->date || $_->date >= $csv->period2->start && $_->date <= $csv->period2->end});
  }
  $grep;
}

sub pk { my ($self, $pk) = @_; $self->grep(sub{$_->pk eq $pk})->first }

sub participant {
  my ($self, $name) = @_;
  $self->grep(sub{$_->Participant =~ $name});
}

sub ideal_survey_results {
  my ($self, $want) = @_;
  my $tally = $self->grep(sub{$_->ideal_survey_results($_->v, $want)})->size;
  $tally / $self->size;
}

#% warn $measurements->fetch(weight => $c->period1)->group_by('uid')->pk('89295')->first;
#% warn $measurements->fetch(weight => $c->period1)->group_by('uid')->pk('89295')->last;
#% warn $measurements->fetch(weight => $c->period1)->group_by('uid')->first->last;
sub group_by {
  my ($self, @key) = @_;
  return $self unless $key[0];

  my $key = shift @key;
  my $package = join '::', __PACKAGE__, 'group_by';
  BNT::Wellness::Collection->new(map { my $pk = $_; $package->new(pk => $pk, collection => $self->grep(sub{$_->$key eq $pk})->datesort) } $self->map(sub{$_->$key})->uniq->each)->group_by('', @key);
  #\%_;

  #%_ = map { my $uid = $_; {$uid => $self->grep(sub{$_->uid eq $uid})->datesort} } $self->map('uid')->uniq->each;
  #\%_;
#warn Data::Dumper::Dumper(\%_);
}

sub latest {
  my $self = shift;
local $_ =  $self->reduce(sub{
    my $c = $a->grep(sub{$_->uid eq $b->uid})->map(sub{
warn sprintf "%s -=- %s\n", $b->date, $_->date;
      $_ = $b if $b->date >= $_->date
    });
    $c->size or do { push @$c, $b if length($b->v); };
    $c;
  }, __PACKAGE__->new);
warn $_->size;
$_->map('v');
}

sub earliest {
  my ($self, $method, $key) = @_;
  $key ||= 'Participant_Code';
  $self->reduce(sub{
    $a = $a->grep(sub{$_->$key eq $b->$key})->map(sub{
warn sprintf "%s -=- %s\n", $b->date, $_->date;
      $_ = $b if $b->date <= $_->date;
    });
    $a->size or do { push @$a, $b if length($b->$method); };
    $a;
  }, __PACKAGE__->new)->map($method);
}

###

sub daterange {
  my $self = $_[0];
  @_ = map { ref $_ ? $_ : Date::Simple->new($_) } @_;
  my $dates = Date::Range->new($_[1] ? (@_) : ($_[0], $_[0]));
  $self->grep('Date')->grep(sub{$_->Date >= $dates->start && $_->Date <= $dates->end})->datesort;
}

sub exists { my ($self, $key) = @_; $self->grep(sub{ref && $_->can($key)}) }
sub Has { my ($self, $key) = @_; $self->grep(sub{ref && $_->can($key) && length($_->$key)}) }

#sub date {
#  my ($self, $date) = @_;
#  $self->grep('Date')->grep(sub{$_->Date <= Date->new($date)})->last
#}

sub hashgrep {
  my ($self, $key, $cb) = (@_);
  return $self->new(grep { $_->$key =~ $cb } @$self) if ref $cb eq 'Regexp';
  return $self->new(grep { $_->$key->$cb(@_) } @$self);
}

1;
