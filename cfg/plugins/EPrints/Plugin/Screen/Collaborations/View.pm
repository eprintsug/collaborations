######################################################################
#
#  Screen:Collaborations::View plugin - Author collaborations page
#
######################################################################
#
#  Copyright 2016 University of Zurich. All Rights Reserved.
#
#  Martin Brändle
#  Zentrale Informatik
#  Universität Zürich
#  Stampfenbachstr. 73
#  CH-8006 Zürich
#
#  The plug-ins are free software; you can redistribute them and/or modify
#  them under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  The plug-ins are distributed in the hope that they will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with EPrints 3; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
######################################################################



=head1 NAME

EPrints::Plugin::Screen::Collaborations::View

=cut

package EPrints::Plugin::Screen::Collaborations::View;

@ISA = ( 'EPrints::Plugin::Screen' );

use strict;

sub new
{
	my ( $class, %params ) = @_;

	my $self = $class->SUPER::new(%params);

	return $self;
}

sub can_be_viewed
{
	my ( $self ) = @_;

	my $session = $self->{session};

	if( defined $session && $session->can_call( 'collaborations', 'allow' ) )
	{
		return $session->call( ['collaborations', 'allow'], $session, 'collaborations/view' );
	} 

	return 0;
}


sub render_title
{
	my ( $self ) = @_;
	
	return $self->html_phrase( "title" );
}


sub render
{
	my ( $self ) = @_;

	my $session = $self->{session};
	my $repository = $self->{repository};
	my $xml = $repository->xml;
	my $processor = $self->{processor};
	
	my $author = $processor->{repository}->{query}->{param}->{author}[0];
	
	my $frag = $session->make_doc_fragment;
	
	if (defined $author)
	{
		# for compatibility, strip off .html and underscores (can be removed later)
		$author =~ s/\.html//;
		$author =~ s/_/ /g;
		
		# check whether there is a collaboration XML file for this author
		my $target = $session->get_repository->get_conf( "htdocs_path" )."/coauthor_data/" . $self->get_author_filename( $author );
		
		if (-e $target)
		{
			my $help = $self->html_phrase( "help" );
			my $author_pin = $session->xml->create_text_node( $author );
			my $author_filename = $self->get_author_filename( $author );
			
			my $canvas = $session->make_element( "canvas",
				id => "ConWheel",
				"data-processing-mydata" => $author_filename,
				"data-processing-sources" => "/coauthors/ConWheel.pde",
				class => "conwheel"
			);
			
			$canvas->appendChild( $self->html_phrase( "no_canvas_support" ) );

			my $page = $self->html_phrase( "page_template",
				author_name => $author_pin,
				canvas => $canvas,
				help => $help
			);
			
			$frag->appendChild( $page );
			
		}
		else
		{
			my $author_pin = $session->xml->create_text_node( $self->get_author_filename( $author ) );
			$frag->appendChild(
				$session->render_message( "warning", 
					$self->html_phrase(
						"missing_authordata",
						author => $author_pin
					)
				)
			);
		}
	}
	else
	{
		$frag->appendChild( 
			$session->render_message( "warning", $self->html_phrase( "missing_author" ) )
        );
	}
	
	return $frag;
}


sub get_author_filename
{
	my ( $self, $author ) = @_;
	
	my $initials = "";
	
	my @name_parts = split( /,\s/, $author );
	my $family = $name_parts[0];
	my $given = $name_parts[1];
	
	my $author_filename = $family;
	
	# get the initials
	if (defined $given)
	{
		my @given_names = split( /\s/, $given );
		
		my $first = 1;
		foreach my $given_name (@given_names)
		{
			my $initial = substr($given_name,0,1);
			if ($first)
			{
				$initials = $initial;
				$first = 0;
			}
			else
			{
				$initials .= " " . $initial;
			}
		}
		
		$author_filename .= " " . $initials;
	}
	
	return EPrints::Utils::escape_filename( $author_filename ) . ".xml";
}

1;
