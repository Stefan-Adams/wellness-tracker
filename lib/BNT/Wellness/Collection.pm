package BNT::Wellness::Collection;
use Mojo::Base 'Mojo::Collection';

use Date::Simple 'date';
use Date::Range;

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

sub participant {
  my ($self, $name) = @_;
  $self->grep(sub{$_->Participant =~ $name});
}

sub ideal_survey_results {
  my ($self, $want) = @_;
  my $tally = $self->grep(sub{$_->ideal_survey_results($_->v, $want)})->size;
  $tally / $self->size;
}

sub group_by {
  my ($self, $key) = @_;
  die "group_by missing required key" unless $key;

  %_ = map { my $uid = $_; {$uid => $self->grep(sub{$_->uid eq $uid})->datesort} } $self->map('uid')->uniq->each;
  \%_;
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
