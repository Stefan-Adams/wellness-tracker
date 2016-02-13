package BNT::Wellness::Model::Survey;
use Mojo::Base -base;

use Date::Simple;

has Q => sub {[
  [1 => 4],  
  [2 => 7],  
  [3 => 1],
  [4 => 1],  
  [5 => 3],
  [6 => 3],  
  [7 => 3],  
  [8 => 3],
  [9 => 7],  
  [10 => 3],
  [11 => 6],  
  [12 => 4],  
  [13 => 4],  
  [14 => 4],  
  [15 => 4],  
  [16 => 4],  
  [17 => 3],  
  [18 => 4],  
  [19 => 4],  
  [20 => 4],  
]};

has [qw(uid date k v)];

sub new {
  my $self = shift->SUPER::new(@_);
  $self->date(Date::Simple->new($self->date)) if $self->date =~ /^\d{2,4}\W\d{2}\W\d{2,4}$/;
  $self;
}

sub ideal_survey_results { shift; _bin2dec(shift) & _bin2dec(shift) }

sub _bin2dec {
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

1;
