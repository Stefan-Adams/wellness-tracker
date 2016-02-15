package BNT::Wellness::Plugin::Routes;
use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($self, $app, $conf) = @_;

  my $r = $app->routes;
  $r->get('/' => sub { shift->redirect_to('reports') });
  $r->post('/admin/period/current')->to('period#current'); # Sets date1, date2 in database#config#period as date1~date2
  $r->get('/reports')->to('reports#index');
  #$r->get('/' => sub { shift->redirect_to('posts') });
  #$r->get('/posts')->to('posts#index');
  #$r->get('/posts/create')->to('posts#create')->name('create_post');
  #$r->post('/posts')->to('posts#store')->name('store_post'); 
  #$r->get('/posts/:id')->to('posts#show')->name('show_post');
  #$r->get('/posts/:id/edit')->to('posts#edit')->name('edit_post');  
  #$r->put('/posts/:id')->to('posts#update')->name('update_post');   
  #$r->delete('/posts/:id')->to('posts#remove')->name('remove_post');
}

1;
