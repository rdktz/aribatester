use Mojolicious::Lite ;
use Mojo::Exception;
#use Mojolicious::Plugin::Cache::Action;
use Test::More;
use Mojo::Log;
use File::Temp;
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
  my $format = $c->param('format') ;
  if (!(defined $seconds && $seconds =~ /\d+/)){
  	$c->reply->exception("Use the 'seconds' param");
	return;
  }
  sleep $seconds;
  #$c->render(text => 'Ariba tester: use "seconds" param to indicate the HTTP OK response delay');
  $c->res->headers->content_type('text/xml');
  $c->res->headers->header("X-AribaTest" => sprintf "Slept for %u seconds :)", $seconds);
  #$c->res->code(200);
  $c->app->log->debug("Received XML request");
  $c->app->log->debug(Dumper $c->req->content);
  if ($format && $format =~ /cxml/i) {
  	$c->render(template => 'cxml/dummy_response', format => 'xml', seconds=>$seconds);
  } else {
  	$c->render(template => 'foo/bar', format => 'xml', seconds=>$seconds);
  }
  #$c->rendered(200);
};

post '/sleep/' => sub {
  my $c = shift;
  my $seconds = $c->param('seconds') ;
  my $format = $c->param('format') ;
  #$c->render(text => 'Ariba tester: use "seconds" param to indicate the HTTP OK response delay');
  $c->res->headers->content_type('text/xml');
  #$c->res->code(200);
  $c->app->log->info("Received XML request");
  #$c->app->log->debug(Dumper $c->req->content);
  my ($tmp, $tmpname) = File::Temp->new( UNLINK => 0, SUFFIX => '.xml' , DIR=> './xmllog', PERMS => 0666);
  $c->app->log->info("Dumping to $tmpname / $tmp");
  printf $tmp $c->req->content->asset->slurp;
  close $tmp;
  
  if ($format && $format =~ /cxml/i) {
  	$c->render(template => 'cxml/dummy_response', format => 'xml', seconds=>$seconds);
  } else {
  	$c->render(template => 'foo/bar', format => 'xml', seconds=>$seconds);
 }
  #$c->rendered(200);
};


app->start;


__DATA__

@@ foo/bar.xml.ep
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
   <soap:Body>
      </soap:Body>
	  </soap:Envelope>

@@ cxml/dummy_response.xml.ep
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE cXML
  SYSTEM "http://xml.cxml.org/schemas/cXML/1.2.046/cXML.dtd">
<cXML payloadID="05ded391-6f61-9b54-baf3-0ce92cb5cd6c"
      timestamp="2021-01-26T12:04:45+00:00"
      version="1.2.046">
   <Response>
      <Status code="200" text="Success">Success</Status>
   </Response>
</cXML>

