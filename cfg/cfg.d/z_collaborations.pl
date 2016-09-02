#
# This configuration is used for the Collaborations plugin
# It specifies the contributor fields that are used to evaluate the author collaborations
#

$c->{collaboration_fields} = [
  'creators_abbrv',
  'editors_abbrv'
];

$c->{collaborations} = {};

#
# by default, anyone can view the author collaborations. Comment out to enable only users with the special '+collaborations/view' role 
push @{$c->{public_roles}}, "+collaborations/view";

# The method below is called by the /cgi/collaborations/* scripts which handle the delivery of collaboration graph
$c->{collaborations}->{allow} = sub {
	my( $session, $priv ) = @_;

	return 0 unless( defined $priv );

# Un-comment the following block if you want to restrict access to collaboration graphs (e.g. to restricted users) 
# BUT you still want some collaboration graphs to display on the summary pages
#
#       if( $session->get_online )
#       {
#               # Allow any requests coming from a summary page
#               my $referer = EPrints::Apache::AnApache::header_in(
#                                        $session->get_request,
#                                        'Referer' );
#               if( defined $referer )
#               {
#                       my $hostname = $session->config( 'host' ) or return 0;
#
#                       return 1 if( $referer =~ /^https?:\/\/$hostname\/\d+\/?$/ );
#               }
#       }

	return 1 if( $session->allow_anybody( $priv ) );
	return 0 if( !defined $session->current_user );
	return $session->current_user->allow( $priv );
};

# Hide the link to collaborations page by default
$c->{plugins}->{"Screen::Collaborations::View"}->{appears}->{key_tools} = undef;

