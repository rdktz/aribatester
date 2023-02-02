use Mojolicious::Lite ;
use Mojo::Exception;
use Mojolicious::Plugin::TemplateToolkit;
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
#app->renderer->default_handler('tt2');


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
  $c->app->log->debug("Headers:\n");
  $c->app->log->debug(Dumper $c->req->headers);
  if ($format && $format =~ /cxml/i) {
  	$c->render(template => 'cxml/dummy_response', format => 'xml', seconds=>$seconds);
  } elsif ($format && $format =~ /fg/i) {
  	$c->render(template => 'soap/fg_pr_response', format => 'xml', seconds=>$seconds);
  } else {
  	$c->render(template => 'foo/bar', format => 'xml', seconds=>$seconds);
  }
  #$c->rendered(200);
};

sub dump_req {
  my $c = shift;
  $c->app->log->debug("Headers:\n");
  $c->app->log->debug(Dumper $c->req->headers->to_string);
  my ($tmp, $tmpname) = File::Temp->new( UNLINK => 0, SUFFIX => '.xml' , DIR=> './xmllog', PERMS => 0666);
  $c->app->log->info("Dumping to $tmp");
  printf $tmp $c->req->content->asset->slurp;
  close $tmp;
}

sub dump_res {
  my ($c,$res) = @_;
  my ($tmp, $tmpname) = File::Temp->new( UNLINK => 0, SUFFIX => '_resp.xml' , DIR=> './xmllog', PERMS => 0666);
  $c->app->log->info("Dumping response to $tmp");
  printf $tmp $res;
  close $tmp;
}

post '/sleep/' => sub {
  my $c = shift;
  my $seconds = $c->param('seconds');
  my $format = $c->param('format') ;
  #$c->render(text => 'Ariba tester: use "seconds" param to indicate the HTTP OK response delay');
  $c->res->headers->content_type('text/xml');
  #$c->res->code(200);
  #$c->app->log->info("Received XML request");
  &dump_req($c);
  if ($format && $format =~ /cxml/i) {
  	$c->render(template => 'cxml/dummy_response', format => 'xml', seconds=>$seconds);
  } else {
  	$c->render(template => 'foo/bar', format => 'xml', seconds=>$seconds);
 }
  #$c->rendered(200);
};

post '/fg/pr' => sub {
	my $c = shift;
	&dump_req($c);
  	$c->render(template => 'soap/fg_pr_response', format => 'xml');
};


# TODO: parse the request and generate random PDF links using e.g. WWW::DuckDuckGo
#
post '/doc/url' => sub {
	my $c = shift;
	&dump_req($c);
  	$c->render(template => 'soap/doc_url_response', format => 'xml');
};

post '/vne/:approvable' => sub {
  my $c = shift;
  &dump_req($c);
  my $appr = $c->param('approvable') ;
  die "Unsupported approvable $appr" unless $appr =~ /^(invoice|ir|pr)$/;
  my $partition = $c->param('partition') || 'prealm_???' ;
  my $variant = $c->param('variant') || 'vrealm_???' ;
  my ($uniq) = $c->req->content->asset->slurp =~ /<UniqueName>((?:INV|PR)[^<]+)/gs;
  $c->app->log->info("Calling VnE for $appr [UniqueName=$uniq]");
  $c->stash(key=>$uniq);
  ## now here's the OK/NOK logic
  # if the unique name contains FAIL the VnE for INV should fail
  # if the unique name contains FAILURE the VnE for IR should fail
  # otherwise it should be an OK
  my $vne_tmpl_suff = 'OK';
  if ($appr =~ /^invoice$/ && $uniq =~ /FAIL$/i || $appr =~ /^ir$/ && $uniq =~/FAILURE$/i){
  	$vne_tmpl_suff = 'NOK';
  }

  #if ($event && $event =~ /ProcessInvoiceExternallyExport/){
	# use https://github.wdf.sap.corp/Ariba-Ond/Buyer/blob/2de50d41ff0a4275ae278bc8164620b7e51c3988/test-invoicing/test/ariba/invoicing/core/data/ValidateEnrich/generic/ValidateEnrich_Invoice_SuccessTemplate.xml
	# as the template
  	
	my $res = $c->render_to_string(	
				template => sprintf('soap/ariba_vne_%s_response_%s',$appr,$vne_tmpl_suff), 
				handler=>'tt2', 
				partition=>$partition, 
				variant=>$variant,
				format=>'xml'
			);
	&dump_res($c,$res);
	$c->render(data=>$res, format=>'xml');
};

app->start;


#<variant>vrealm_50261</variant>
#<partition>prealm_50261</partition>

__DATA__

@@ soap/doc_url_response.xml.ep
<?xml version="1.0"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Ariba:Sourcing:VARIBA">
  <soapenv:Body>
    <urn:DocumentURLOutBoundReply>
      <!--Optional:-->
      <urn:WSDocumentURLOutBoundResponse_Item>
        <!--Optional:-->
        <urn:item>
          <!--You may enter the following 5 items in any order-->
          <!--urn:ErrorMessage>?</urn:ErrorMessage-->
          <urn:Status>Draft</urn:Status>
          <urn:Suppliers>
            <urn:item>
			<urn:Supplier>
               <urn:ContactEmailAddress>az.zdzi@yahoo.com</urn:ContactEmailAddress>
               <urn:OrganizationId>Active Ingredients France - duplicate</urn:OrganizationId>
               <urn:ContactName>Radek 0000037001 Active Ing</urn:ContactName>
               <urn:UniqueName>1591708039175_radoslaw.kotowicz@sap.com</urn:UniqueName>
               <urn:Vendorkeys>
				 <urn:BusinessSystemId/>
				 <urn:LocationId/>
				 <urn:SiteId/>
                 <urn:VendorId>0000037001</urn:VendorId>
               </urn:Vendorkeys>
              </urn:Supplier>
			  <urn:Materials>
                <urn:item>
                  <urn:Plant>3000 New York</urn:Plant>
              <urn:Vendorkeys>
				<urn:BusinessSystemId/>
				<urn:LocationId/>
				<urn:SiteId/>
                <urn:VendorId>0000037001</urn:VendorId>
              </urn:Vendorkeys>
                  <urn:MaterialNumber>HT-S2011008</urn:MaterialNumber>
                  <urn:Name>16X DVD-ROM SATA 1st Drive</urn:Name>
                  <urn:DocumentUrl>http://test.com</urn:DocumentUrl>
                  <urn:DocumentUrlDescription>Ble ble ble</urn:DocumentUrlDescription>
                  <!--urn:ErrorMessage>?</urn:ErrorMessage-->
                </urn:item>
              </urn:Materials>
            </urn:item>
          </urn:Suppliers>
          <urn:Type>RFx</urn:Type>
          <urn:UniqueId>Doc3854728325</urn:UniqueId>
        </urn:item>
      </urn:WSDocumentURLOutBoundResponse_Item>
    </urn:DocumentURLOutBoundReply>
  </soapenv:Body>
</soapenv:Envelope>


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

@@ soap/fg_pr_response.xml.ep
<?xml version="1.0" encoding="UTF-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<soap:Header>
<Headers  xmlns="urn:Ariba:Buyer:vabcd">
<variant>vrealm_50261</variant>
<partition>prealm_50261</partition>
</Headers>
</soap:Header>
<soap:Body>
<ExternalReqForApprovalImportReply xmlns="urn:Ariba:Buyer:vabcd">
<ExternalReqForApprovalOutput_Item>
<item>
<ExternalReqId>BPLCWO00000068</ExternalReqId>
<ReferenceUrl>https://s1-eu.ariba.com/Buyer/Main/ad/webjumper?realm=bpsap-T&amp;itemID=B6tSATmBKpXNAHE</ReferenceUrl>
<StatusString>Submitted</StatusString>
<UniqueName>PR2006516-V2</UniqueName>
</item>
</ExternalReqForApprovalOutput_Item>
</ExternalReqForApprovalImportReply>
</soap:Body>
</soap:Envelope>


@@ soap/ariba_vne_pr_response_OK.xml.tt2
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
   <soap:Header/>
      <soap:Body>
	        </soap:Body>
			      </soap:Envelope>

@@ soap/ariba_vne_pr_response_OK.xml.tt2
<?xml version="1.0" encoding="UTF-8"?>
<soap-env:Envelope xmlns:soap-env="http://schemas.xmlsoap.org/soap/envelope/">
<soap-env:Header/>
<soap-env:Body>
<n0:ProcessRequisitionExternallyExportReply xmlns:n0="urn:Ariba:Buyer:vsap" xmlns:prx="urn:sap.com:proxy:Q01:/1SAI/TASAA0D58ABFE4828CF458F:740" partition="prealm_3636" variant="vrealm_3636">
<n0:Requisition_ProcessReqExtValidationStatusResponseImport_Item>
<n0:item>
<n0:EventDetails>
<n0:StatusResponse>Failure</n0:StatusResponse>
</n0:EventDetails>
<n0:UniqueName>[% key %]</n0:UniqueName>
</n0:item>
</n0:Requisition_ProcessReqExtValidationStatusResponseImport_Item>
<n0:Requisition_ProcessReqExtEnrichResponseImport_Item>
<n0:item>
<n0:LineItems>
<n0:item>
<n0:Accountings>
<n0:SplitAccountings>
<n0:item>
<n0:NumberInCollection>1</n0:NumberInCollection>
<n0:custom>
<n0:CustomString name="Division"/>
<n0:CustomString name="ProfitCenter">GB25600004</n0:CustomString>
</n0:custom>
</n0:item>
</n0:SplitAccountings>
</n0:Accountings>
<n0:NeedBy>2020-04-23T10:30:00Z</n0:NeedBy>
<n0:NumberInCollection>1</n0:NumberInCollection>
<n0:custom>
<n0:CustomString name="TaxJurisdictionCode"/>
</n0:custom>
</n0:item>
</n0:LineItems>
<n0:UniqueName>[% key %]</n0:UniqueName>
</n0:item>
</n0:Requisition_ProcessReqExtEnrichResponseImport_Item>
</n0:ProcessRequisitionExternallyExportReply>
</soap-env:Body>
</soap-env:Envelope>

@@ soap/ariba_vne_ir_response_OK.xml.tt2
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
   <soap:Header/>
   <soap:Body>
      </soap:Body>
	  </soap:Envelope>

@@ soap/ariba_vne_invoice_response_OK.xml.tt2
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Ariba:Buyer:[% variant %]">
   <soapenv:Header>
      <urn:Headers>
         <urn:variant>[% variant %]</urn:variant>
         <urn:partition>[% partition %]</urn:partition>
      </urn:Headers>
   </soapenv:Header>
   <soapenv:Body>
      <urn:ProcessInvoiceExternallyExportReply partition="[% partition %]" variant="[% variant %]">
         <urn:Invoice_ProcessInvoiceExtValidationStatusResponseImport_Item>
            <urn:item>
               <urn:EventDetails>
                  <urn:StatusResponse>SUCCESS</urn:StatusResponse>
               </urn:EventDetails>
               <urn:UniqueName>[% key %]</urn:UniqueName>
            </urn:item>
         </urn:Invoice_ProcessInvoiceExtValidationStatusResponseImport_Item>
      </urn:ProcessInvoiceExternallyExportReply>
   </soapenv:Body>
</soapenv:Envelope>


@@ soap/ariba_vne_invoice_response_NOK.xml.tt2
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:Ariba:Buyer:[% variant %]">
   <soapenv:Header>
      <urn:Headers>
         <urn:variant>[% variant %]</urn:variant>
         <urn:partition>[% partition %]</urn:partition>
      </urn:Headers>
   </soapenv:Header>
   <soapenv:Body>
      <urn:ProcessInvoiceExternallyExportReply partition="[% partition %]" variant="[% variant %]">
         <urn:Invoice_ProcessInvoiceExtValidationStatusResponseImport_Item>
            <urn:item>
               <urn:EventDetails>
                  <urn:StatusResponse>FAILURE</urn:StatusResponse>
               </urn:EventDetails>
               <urn:UniqueName>[% key %]</urn:UniqueName>
            </urn:item>
         </urn:Invoice_ProcessInvoiceExtValidationStatusResponseImport_Item>
         <urn:Invoice_ProcessInvoiceExtEnrichResponseImport_Item>
            <urn:item>
               <urn:UniqueName>[% key %]</urn:UniqueName>
               <urn:SupplierOrderInfo>
                  <urn:SupplierSalesOrderNumber>2017-10-24T21:46:55Z</urn:SupplierSalesOrderNumber>
               </urn:SupplierOrderInfo>
            </urn:item>
         </urn:Invoice_ProcessInvoiceExtEnrichResponseImport_Item>
         <urn:ValidationError_ValidateErrorImport_Item>
            <urn:item>
               <urn:Date>2017-10-24T21:46:55Z</urn:Date>
               <urn:ErrorDetails>
                  <urn:item>
                     <urn:ErrorCategory>100</urn:ErrorCategory>
                     <urn:ErrorCode>100</urn:ErrorCode>
                     <urn:ErrorMessage>Invalid Supplier Invoice Number</urn:ErrorMessage>
                     <urn:FieldName>InvoiceNumber</urn:FieldName>
                     <urn:LineNumber></urn:LineNumber>
                     <urn:SplitNumber></urn:SplitNumber>
                  </urn:item>
                  <urn:item>
                     <urn:ErrorCategory>100</urn:ErrorCategory>
                     <urn:ErrorCode>100</urn:ErrorCode>
                     <urn:ErrorMessage>Invalid Billing Address value</urn:ErrorMessage>
                     <urn:FieldName>BillingAddress</urn:FieldName>
                     <urn:LineNumber>1</urn:LineNumber>
                     <urn:SplitNumber></urn:SplitNumber>
                  </urn:item>
                  <urn:item>
                     <urn:ErrorCategory>100</urn:ErrorCategory>
                     <urn:ErrorCode>100</urn:ErrorCode>
                     <urn:ErrorMessage>Missing Attachment in the Invoice Line Item</urn:ErrorMessage>
                     <urn:FieldName>EnhancedAttachments</urn:FieldName>
                     <urn:LineNumber>2</urn:LineNumber>
                     <urn:SplitNumber></urn:SplitNumber>
                  </urn:item>
                  <urn:item>
                     <urn:ErrorCategory>100</urn:ErrorCategory>
                     <urn:ErrorCode>100</urn:ErrorCode>
                     <urn:ErrorMessage>Invalid CostCenter value</urn:ErrorMessage>
                     <urn:FieldName>CostCenter</urn:FieldName>
                     <urn:LineNumber>1</urn:LineNumber>
                     <urn:SplitNumber>1</urn:SplitNumber>
                  </urn:item>
               </urn:ErrorDetails>
               <urn:Id>[% key %]</urn:Id>
            </urn:item>
         </urn:ValidationError_ValidateErrorImport_Item>
      </urn:ProcessInvoiceExternallyExportReply>
   </soapenv:Body>
</soapenv:Envelope>
