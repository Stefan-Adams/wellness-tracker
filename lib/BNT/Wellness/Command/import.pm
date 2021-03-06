package BNT::Wellness::Command::import;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Util qw(decode slurp);
use Mojo::IOLoop::Client;
use Mojolicious;

use File::Spec::Functions 'catfile';
use File::Basename;
use Text::CSV;
use Lingua::EN::Inflect::Number 'to_S';

has description => 'empty table and import data from CSV files';
has usage => sub { shift->extract_usage };

has 'config';

sub run {
  my $self = shift;

  foreach my $model ( @_ ) {
    my $file = ((grep { /(^|\s*-\s*)$model\.tsv$/ } @{$self->app->home->list_files('import')})[0]);
    $file = $self->app->home->rel_file("import/$file");
    my ($conf_file) = ($file =~ /^(.+)\.[^\.]+$/);
    $self->config($self->load($conf_file));
    $model = lc($model);
    $model = $file =~ /\bkv\b/i ? $self->app->db->kv($model) : $self->app->db->$model;
    $model->reset_db or next;
    my $rows = _slurp($file);
    $self->_import_record($_ => $model) foreach @$rows;
  }
}

sub _import_record {
  my ($self, $row, $model) = @_;

  my %cols;
  foreach ( @{$self->config->{col}} ) {
    if ( !ref || ref eq 'ARRAY' ) {
      foreach my $col ( ref ? @$_ : $_ ) {
        $cols{$_} = $row->{$_};
      }
    } elsif ( ref eq 'HASH' ) {
      foreach my $col ( keys %$_ ) {
        $cols{$_->{$col}} = $row->{$col};
      }
    }  
  }    

  if ( $self->config && $self->config->{kv} ) {
    # Is given a full row of data
    # Adds multiple records to the database, one record per field of data given.  uid and date are repeated per record.  A record type is set and its value.
    foreach my $kv ( grep { $row->{$_} } @{$self->config->{kv}} ) {
      $model->add({%cols, k => $kv, v => $row->{$kv}});
    }
  } else {
    $model->add(\%cols);
  }
}
 
sub load {
  my ($self, $file) = @_;
  $app->log->debug(qq{Reading configuration file "$file"});
  return $self->parse(decode('UTF-8', slurp $file), $file);
}

sub parse {
  my ($self, $content, $file) = @_;

  # Run Perl code in sandbox
  my $config = eval 'package BNT::Wellness::Command::import::Sandbox; no warnings;'
    . "sub app; local *app = sub { \$app }; use Mojo::Base -strict; $content";
  die qq{Can't load configuration from file "$file": $@} if $@;
  die qq{Configuration file "$file" did not return a hash reference.\n}
    unless ref $config eq 'HASH';

  return $config;
}

sub _slurp {
  my $file = shift;
  my $model = basename $file;
  $model =~ s/.*? - (.*?)\.tsv/$1/;
  $model =~ s/ /_/g;
  warn "Loading	Importing $model...\n";
  my $csv = Text::CSV->new ( { binary => 1, sep_char => "\t" } )  # should set binary attribute.
                  or die "Cannot use CSV: ".Text::CSV->error_diag ();

  open my $fh, "<:encoding(utf8)", $file or die "$file: $!";
  my $head = $csv->getline( $fh );
  foreach ( @$head ) {
    s/%//g;
    s/\s*\(.*//;
    #s/^(\d+)$/q_$1/;
    s/ /_/g;
    s/^_+|_+$//g;
    $_ = lc($_);
  }
  my @rows;
  while ( my $row = $csv->getline( $fh ) ) {
      my %hash;
      @hash{@$head} = @$row; #map { /^\d{1,4}\W\d{1,2}\W\d{1,4}$/ ? Date->new($_) || $_ : $_ } @$row;
      push @rows, \%hash;
  }
  $csv->eof or $csv->error_diag();
  close $fh;
  return $model, \@rows;
}

1;
