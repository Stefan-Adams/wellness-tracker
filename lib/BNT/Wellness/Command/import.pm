package BNT::Wellness::Command::import;
use Mojo::Base 'Mojolicious::Command';

use Mojo::IOLoop::Client;
use Mojolicious;

use File::Spec::Functions 'catfile';
use File::Basename;
use Text::CSV;
use Lingua::EN::Inflect::Number 'to_S';

has description => 'import data from CSV files';
has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;

  foreach my $table ( @_ ) {
    my $file = ((grep { /(^|\s*-\s*)$table\.tsv$/ } @{$self->app->home->list_files('import')})[0]);
    my $rows = _slurp($self->app->home->rel_file("import/$file"));
    my $model = "BNT::Wellness::Model::$table";
    Mojo::Loader::load_class($model);
    $model = $model->new(sqlite => $self->app->sqlite);
    $model->clear_all or next;
    $model->add($_) foreach @$rows;
  }
}

sub _slurp {
  my $file = shift;
  my $table = basename $file;
  $table =~ s/.*? - (.*?)\.tsv/$1/;
  $table =~ s/ /_/g;
  warn "Loading	Importing $table...\n";
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
  return $table, \@rows;
}

1;
