######################################################################
#
#  Collaborations::Processor plugin - identify author collaborations
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

EPrints::Plugin::Collaborations::Processor - identify collaborations

=head1 DESCRIPTION

This plugin identifies author - coauthor collaborations

=head1 METHODS

=over 4

=item $plugin = EPrints::Plugin::Collaborations::Processor->new( %params )

Creates a new Collaborations Processor plugin.

=item process_record

Identifies the coauthor collaborations for a given eprint

=back

=cut

=back

=cut

package EPrints::Plugin::Collaborations::Processor;

use strict;
use warnings;

use utf8;
use Digest::MD5 qw(md5_hex);
use Data::Dumper;

use base 'EPrints::Plugin';

sub new
{
        my( $class, %params ) = @_;

        my $self = $class->SUPER::new( %params );

        $self->{name} = "Collaborations::Processor";
        $self->{visible} = "all";

        return $self;
}

#
# Pass 1- Get list of unique author names and determine their count of eprints
# 
sub create_full_author_list
{
	my ($self) = @_;

	my $dataset = $self->{dataset};

	$dataset->search->map( \&process_authors, $self );
	
	return;
}

sub process_authors
{
	my ($session, $dataset, $eprint, $param ) = @_;
	
	my $verbose = $param->{param}->{verbose};
	my $author_fields = $param->{author_fields};
	my $full_author_list = $param->{full_author_list};
	
	my $eprintid = $eprint->get_value( "eprintid" );
	
	print STDOUT "Create full author list: processing eprint $eprintid, " if $verbose;
	
	# deduplicate
	my $authors_unique = {};
	
	foreach my $field (@$author_fields)
	{
		my $authors = $eprint->get_value( $field );
		deduplicate( $authors_unique, $authors );
	}
	
	add_to_author_list( $full_author_list, $authors_unique );

	my $author_count = scalar(keys %$full_author_list);

	print STDOUT "$author_count authors\n" if $verbose;

	return;
}



#
# Pass 2 - Assign ids to author names
#
sub assign_author_ids
{
	my ($self) = @_;
	
	my $author_list = $self->{full_author_list};
	
	my $author_count = 0;
	
	foreach my $author_key (keys %$author_list)
	{
		$author_count++;
		$author_list->{$author_key}->{id} = $author_count;
	}
	
	$self->{full_author_count} = $author_count;
	
	return;
}

#
# Pass 3 - Prepare the list of authors to be processed
#
sub get_author_list
{
	my ($self, $eprint) = @_;
	
	my $verbose = $self->{param}->{verbose};
	my $author_fields = $self->{author_fields};
	my $author_list = $self->{author_list};
	
	my $eprintid = $eprint->get_value( "eprintid" );
	
	print STDOUT "Processing authors for eprint $eprintid, " if $verbose;
	
	# deduplicate
	my $authors_unique = {};
	
	foreach my $field (@$author_fields)
	{
		my $authors = $eprint->get_value( $field );
		deduplicate( $authors_unique, $authors );
	}
	
	add_to_author_list( $author_list, $authors_unique );

	my $author_count = scalar(keys %$author_list);

	print STDOUT "$author_count authors\n" if $verbose;
	
	return;
}

sub get_single_author
{
	my ($self, $name) = @_;
	
	my $verbose = $self->{param}->{verbose};
	my $full_author_list = $self->{full_author_list};
	
	print STDOUT "Processing author $name\n" if $verbose;
	
	#
	# We assume that the author name is defined in the same format as 
	# defined in the fields used for the creation of the collaboration data.
	# 
	my $author_md5 = md5_hex( $name );
	
	#
	# Check if we have a match in the full list
	#
	if (defined $full_author_list->{$author_md5} )
	{
		$self->{author_list}->{$author_md5} = $full_author_list->{$author_md5};
	}
	else
	{
		print STDOUT "No match found for author $name\n";
	}

	return;
}


#
# Pass 4 - For each author, determine its associated eprints and coauthors
#
sub create_coauthor_graphs
{
	my ($self) = @_;
	
	my $verbose = $self->{param}->{verbose};
	
	my $author_list = $self->{author_list};
	
	print STDOUT "Create author graphs\n" if $verbose;
	
	foreach my $author_key (keys %$author_list)
	{
		$self->create_coauthor_graph( $author_key );
	}
	
	return;
}


sub create_coauthor_graph
{
	my ($self, $author_key) = @_;

	my $session = $self->{session};
	my $dataset = $self->{dataset};
	my $verbose = $self->{param}->{verbose};
	my $author_fields = $self->{author_fields};
	
	my $graph = {};
	$graph->{author_key} = $author_key;
	$graph->{graph} = {};
	$graph->{param} = $self->{param};
	$graph->{author_fields} = $author_fields;
	$graph->{author_list} = $self->{author_list};
	$graph->{full_author_list} = $self->{full_author_list};
	$graph->{edge_count} = 0;
	
	my $author_id = $graph->{full_author_list}->{$author_key}->{id};
	$graph->{graph}->{active_node} = $author_id;
	
	my $author_family = $graph->{author_list}->{$author_key}->{family};
	my $author_given = $graph->{author_list}->{$author_key}->{given};
		
	utf8::decode($author_family);
	utf8::decode($author_given);
		
	$author_given =~ s/\s/\./g;
		
	my $author_name = $author_family;
	$author_name = $author_name . ', ' . $author_given if ($author_given ne '');
	
	if ($author_family =~ /\s/ )
	{
		$author_name = '"' . $author_name . '"';
	}
		
	my $search_expression = EPrints::Search->new( 
		session => $session,
		dataset => $dataset
	);
	
	my @search_fields;
	foreach my $field (@$author_fields)
	{
		push @search_fields, $dataset->get_field( $field )
	}
	
	$search_expression->add_field(
		fields => [ @search_fields ],
		value => $author_name,
		match => "IN",
		merge => "ANY"
	);
	
	my $eplist = $search_expression->perform_search;
	
	my $count = $eplist->count;
	
	print STDOUT "$count eprints for $author_name\n" if $verbose; 
		
	$eplist->map( \&process_coauthors, $graph );
	
	# Save graph as XML and create HTML fragment for loading the graph
	save_graph( $session, $graph );
	
	return;
}

#
# For a given eprint, process all coauthors
#
sub process_coauthors
{
	my ($session, $dataset, $eprint, $graph ) = @_;
	
	my $author_key = $graph->{author_key};
	my $eprintid = $eprint->get_value( "eprintid" );
	
	my $author_fields = $graph->{author_fields};
	
	foreach my $field (@$author_fields)
	{
		my $authors = $eprint->get_value( $field );
		process_nodes_edges( $authors, $eprintid, $graph );
	}
	
	return;
}

sub process_nodes_edges
{
	my ($authors, $eprintid, $graph) = @_;
	
	my $author_list = $graph->{full_author_list};
	my $edge_count = $graph->{edge_count};
	
	# Calculate the nodes
	foreach my $author (@$authors)
	{
		my $author_md5 = get_author_md5( $author );
		my $author_id = $author_list->{$author_md5}->{id};
		my $from = $author_id;
		
		if (defined $author_id)
		{
			my $item_count = $author_list->{$author_md5}->{item_count};
			my $author_name = get_author_name( $author_list->{$author_md5}, ", " );
			
			$graph->{graph}->{nodes}->{$author_id}->{id} = $author_id;
			$graph->{graph}->{nodes}->{$author_id}->{complete_name} = $author_name;
			$graph->{graph}->{nodes}->{$author_id}->{item_count} = $item_count;
			$graph->{graph}->{nodes}->{$author_id}->{link} = $author_name; 
			
			# Calculate the edges
			foreach my $author_to (@$authors)
			{
				my $author_md5_to = get_author_md5( $author_to );
				my $to = $author_list->{$author_md5_to}->{id};
				
				if ( defined $to && ( $to != $from ) )
				{
					$edge_count++;
					$graph->{graph}->{edges}->{$edge_count}->{from} = $from;
					$graph->{graph}->{edges}->{$edge_count}->{to} = $to;
					$graph->{graph}->{edges}->{$edge_count}->{ref} = $eprintid;
				}
			}
		}
	}
	
	$graph->{edge_count} = $edge_count;
	
	return;
}

sub save_graph
{
	my ( $session, $graph) = @_;

	my $dir = $session->get_repository->get_conf( "htdocs_path" )."/coauthor_data";

	write_graph_data( $session, $graph, $dir );
	
	return;
}

sub write_graph_data
{
	my ($session, $graph, $dir) = @_;
	
	my $author_key = $graph->{author_key};
	my $author_name = get_author_name( $graph->{author_list}->{$author_key}, " " );
	my $verbose = $graph->{param}->{verbose};
	
	print STDOUT "Writing graph for $author_name\n" if $verbose;

	my $target = $dir . "/" . EPrints::Utils::escape_filename( $author_name ) . ".xml";
	
	open my $xmlout, ">", $target or die "Cannot open > $target\n";
		
	print $xmlout '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
	print $xmlout '<graph>' . "\n";
	print $xmlout '<nodes>' . "\n";
	foreach my $author_id (keys %{$graph->{graph}->{nodes}})
	{
		my $name = $graph->{graph}->{nodes}->{$author_id}->{complete_name};
		my $item_count = $graph->{graph}->{nodes}->{$author_id}->{item_count};
		my $link = $graph->{graph}->{nodes}->{$author_id}->{link};
			
		print $xmlout '<n id="' . $author_id . '" t="' . $name . '" c="' . $item_count . '" a="' . $link . '"/>' . "\n";
	}
	print $xmlout '</nodes>' . "\n";
		
	print $xmlout '<edges>' . "\n";
	foreach my $edge_id (keys %{$graph->{graph}->{edges}})
	{
		my $from = $graph->{graph}->{edges}->{$edge_id}->{from};
 		my $to = $graph->{graph}->{edges}->{$edge_id}->{to};
		my $ref = $graph->{graph}->{edges}->{$edge_id}->{ref};
	
		print $xmlout '<e id="' . $edge_id . '" f="' . $from . '" t="' . $to .  '" r="' . $ref . '"/>' . "\n";
	}
		
	print $xmlout '</edges>' . "\n";
	
	print $xmlout '<active_node r="' . $graph->{graph}->{active_node} . '"/>' . "\n";
	print $xmlout '</graph>' . "\n";
	close $xmlout;
	
	return;
}

######################################################################
=pod

=item $cp->save_author_list()

Saves the full list of authors to an XML file 
(archives/{archive}/html/coauthor_data/author_list.xml)

=cut
######################################################################

sub save_author_list
{
	my ($self) = @_;
	
	my $repository = $self->{repository};
	my $author_list = $self->{full_author_list};
	my $dir = $repository->get_conf( "htdocs_path" )."/coauthor_data";
	
	my $verbose = $self->{param}->{verbose};
	
	print STDOUT "Writing full author list\n" if $verbose;

	my $target = $dir . "/author_list.xml";
	
	open my $xmlout, ">", $target or die "Cannot open > $target\n";
		
	print $xmlout '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
	
	my $count = scalar keys %$author_list;
	print $xmlout '<authors count="' . $count . '">' . "\n";
	
	foreach my $author_key (sort { $author_list->{$a}->{complete_name} cmp $author_list->{$b}->{complete_name} } keys %$author_list)
	{
		my $id = $author_list->{$author_key}->{id};
		my $name = $author_list->{$author_key}->{complete_name};
		my $family = $author_list->{$author_key}->{family};
		my $given = $author_list->{$author_key}->{given};
		my $item_count = $author_list->{$author_key}->{item_count};
		
		print $xmlout '<author id="' . $id . '" name="' . $name . '" family="' . $family . '" given="' . $given . 
			'" md5="' . $author_key . '" items="' . $item_count . '" />' . "\n";
	}
	
	print $xmlout '</authors>' . "\n";
	close $xmlout;
	
	return;
}

######################################################################
=pod

=item boolean $filter =  $cp->filter_author( $author )

Implements rules to filter out author names such as "et al", "et, al" 

=cut
######################################################################


sub filter_author
{
	my ($author) = @_;
	
	# field may have subtype name
	if ( defined $author->{name} )
	{
		$author = $author->{name};
	}
	
	my $family = $author->{family};
	my $given = $author->{given};
	
	return 0 if ($family =~ /^et al/);
	return 0 if ($family =~/^et$/ && $given =~ /al/ );
	
	return 1;
}


sub deduplicate
{
	my ( $authors_unique, $authors ) = @_;
	
	foreach my $author (@$authors)
	{
		my $author_md5 = get_author_md5( $author );
		
		if ( !defined $authors_unique->{$author_md5} )
		{
			$authors_unique->{$author_md5} = $author;
		}
	}
	
	return;
}

sub add_to_author_list
{
	my ($author_list, $authors_unique) = @_;
	
	foreach my $author_md5 (keys %$authors_unique) 
	{
		my $author = $authors_unique->{$author_md5};
		
		next if !filter_author( $author );
		
		# field may have subtype name
		if ( defined $author->{name} )
		{
			$author = $author->{name};
		}

		my $name = $author->{family};
		$name .= ' ' . $author->{given} if $author->{given};
		
		$author_list->{$author_md5}->{family} = $author->{family};
		$author_list->{$author_md5}->{given} = $author->{given};
		$author_list->{$author_md5}->{complete_name} = $name;
		$author_list->{$author_md5}->{item_count}++;
		$author_list->{$author_md5}->{id} = 0;
	}
	
	return;
}

######################################################################
=pod

=item $md5_hex = $cp->get_author_md5( $author )

Return a md5_hex string of the encoded author name 

=cut
######################################################################

sub get_author_md5
{
	my ($author) = @_;
	
	my $author_name = get_author_name( $author, ', ' );

	return md5_hex( $author_name );
}

######################################################################
=pod

=item $author_name = $cp->get_author_name( $author_list,$author_key,$separator )

Return an author name from the list using an author md5 key.

=cut
######################################################################

sub get_author_name
{
	my ($author,$separator) = @_;
	
	# field may have subtype name
	if ( defined $author->{name} )
	{
		$author = $author->{name};
	}
	
	my $family = $author->{family};
	my $given = $author->{given};
		
	utf8::encode($family);
	utf8::encode($given);
		
	my $author_name = $family;
	$author_name = $author_name . $separator . $given if ($given ne '');
	
	return $author_name;
}

1;
















