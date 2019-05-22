use Mojolicious::Lite ;
use Mojo::Exception;
#use Mojolicious::Plugin::Cache::Action;
use Test::More;
use Mojo::Log;
use strict;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Data::Dumper;

my $log = Mojo::Log->new(path => './logs/mojo.log', level => 'debug');


# PLGUINS
app->plugin(TemplateToolkit => {template => {INTERPOLATE => 1}});
app->renderer->paths(['/home/umbrait/projects/aribatester/']);

# Route leading to an action that renders some text
get '/sleep/' => sub {
  my $c = shift;
  my $seconds = $c->param('seconds') ;
  if (!(defined $seconds && $seconds =~ /\d+/)){
  	$c->reply->exception("Use the 'seconds' param");
	return;
  }
  sleep $seconds;
  #$c->render(text => 'Ariba tester: use "seconds" param to indicate the HTTP OK response delay');
  $c->res->headers->content_type('text/xml');
  $c->res->headers->header("X-AribaTest" => sprintf "Slept for %u seconds :)", $seconds);
  #$c->res->code(200);
  $c->render(template => 'foo/bar', format => 'xml', seconds=>$seconds);
  #$c->rendered(200);
};

app->start;


__DATA__

@@ foo/bar.xml.ep
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
   <soap:Body>
      </soap:Body>
	  </soap:Envelope>
