package BNT::Wellness::Command::report;
use Mojo::Base 'Mojolicious::Command';

has description => 'run reports';
has usage => sub { shift->extract_usage };

sub run {
  my $self = shift;

  foreach my $table ( @_ ) {
    my $model = "BNT::Wellness::Model::$table";
    Mojo::Loader::load_class($model);
    $model = $model->new(sqlite => $self->app->sqlite);
    $self->app->render(text => 123);
  }
}

1;
