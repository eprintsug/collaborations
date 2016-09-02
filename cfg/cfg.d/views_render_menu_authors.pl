######################################################################
##
## View menu render method for author view.
## Includes links to coauthor graphs.
##
## 2016/07/28 Martin Brändle, University of Zurich
##
#######################################################################
##
##  Copyright 2016 University of Zurich. All Rights Reserved.
##
##  The plug-ins are free software; you can redistribute them and/or modify
##  them under the terms of the GNU General Public License as published by
##  the Free Software Foundation; either version 2 of the License, or
##  (at your option) any later version.
##
##  The plug-ins are distributed in the hope that they will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with EPrints 3; if not, write to the Free Software
##  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
##
#######################################################################

$c->{render_view_menu_authors} = sub
{
	my( $repo, $menu, $sizes, $values, $fields, $has_submenu, $view ) = @_;

        if( scalar @{$values} == 0 )
        {
                if( !$repo->get_lang()->has_phrase( "Update/Views:no_items" ) )
                {
                        return $repo->make_doc_fragment;
                }
                return $repo->html_phrase( "Update/Views:no_items" );
        }

	# must be replaced with a better function
        my( $cols, $col_len ) = EPrints::Update::Views::get_cols_for_menu( $menu, scalar @{$values} );

        my $col_n = 0;
        
	my $f = $repo->make_doc_fragment;
	my $multi_cols;
	my $add_ul;

        if( $cols > 1 )
        {
		$multi_cols = $repo->make_element( "div", class=>"ep_view_cols ep_view_cols_$cols view_multi_cols" );
                $f->appendChild( $multi_cols );
        }
        else
        {
                $add_ul = $repo->make_element( "ul", class=>"ep_nodot" );
                $f->appendChild( $add_ul );
        }

        my $ds = $view->dataset;

        for( my $i=0; $i<@{$values}; ++$i )
        {
                if( $cols>1 && $i % $col_len == 0 )
                {
                        ++$col_n;
			my $col_quotient = 12 / $cols;
			# => 12 / 3 columns = col-lg-4 col-md-4 col-sm-4
			my $multi_cols_cell = $repo->make_element( "div", class=>"ep_view_col ep_view_col_$col_n view_multi_cols_cell col-lg-$col_quotient col-md-$col_quotient col-sm-$col_quotient" );
			$add_ul = $repo->make_element( "ul", class=>"ep_nodot" );
			$multi_cols_cell->appendChild( $add_ul );
			$multi_cols->appendChild( $multi_cols_cell );
                }
                my $value = $values->[$i];
                my $size = 0;
                my $id = $fields->[0]->get_id_from_value( $repo, $value );
                if( defined $sizes && defined $sizes->{$id} )
                {
                        $size = $sizes->{$id};
                }

		next if( $menu->{hideempty} && $size == 0  );

                my $fileid = $fields->[0]->get_id_from_value( $repo, $value );

		my $testsize = $sizes->{$fileid};

                my $li = $repo->make_element( "li", class=>"author-cells" );
		my $span_cell1 = $repo->make_element( "span", class=>"author-cell-left" );
		my $span_cell2 = $repo->make_element( "span", class=>"author-cell-right" );

                my $xhtml_value = $fields->[0]->get_value_label( $repo, $value );
                my $null_phrase_id = "viewnull_".$ds->base_id()."_".$view->{id};
                if( !EPrints::Utils::is_set( $value ) && $repo->get_lang()->has_phrase($null_phrase_id) )
                {
                        $xhtml_value = $repo->html_phrase( $null_phrase_id );
                }

                if( defined $sizes && (!defined $sizes->{$fileid} || $sizes->{$fileid} == 0 ))
                {
                        $li->appendChild( $xhtml_value );
                }
                else
                {
                        my $link = EPrints::Utils::escape_filename( $fileid );
                        if( $has_submenu ) { $link .= '/'; } else { $link .= '.html'; }
                        my $a = $repo->render_link( $link );
                        $a->appendChild( $xhtml_value );
			$span_cell1->appendChild( $a );
                        $li->appendChild( $span_cell1 );
                }

                if( defined $sizes && defined $sizes->{$fileid} )
                {
                        $span_cell1->appendChild( $repo->make_text( " (".$sizes->{$fileid}.")" ) );
			$span_cell2->appendChild( render_collaboration_link( $repo, $value ) );
                        $li->appendChild( $span_cell2 );
                }


                $add_ul->appendChild( $li );
        }
	while( $cols > 1 && $col_n < $cols )
        {
                ++$col_n;
		my $col_quotient = 12 / $cols;
                my $multi_cols_cell = $repo->make_element( "div", class=>"ep_view_col ep_view_col_$col_n view_multi_cols_cell col-lg-$col_quotient col-md-$col_quotient col-sm-$col_quotient" );
                $multi_cols->appendChild( $multi_cols_cell );
        }

        return $f;
};

sub render_collaboration_link
{
	my ($session, $author) = @_;

	my $author_family = $author->{family};
        my $author_given = $author->{given};
                
        utf8::encode($author_family);
        utf8::encode($author_given);
                
        my $author_name = $author_family;
        $author_name = $author_name . " " . $author_given if ($author_given ne '');	

	my $author_url = '/cgi/collaborations/view?author=' . $author_name;

	my $author_a = $session->make_element( "a", href=>$author_url, class=>"collaboration-url" );
	$author_a->appendChild( $session->html_phrase( "Plugin/Screen/Collaborations/View:link_title" ) );

	return $author_a;
}

