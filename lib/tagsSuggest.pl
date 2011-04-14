#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use Insipid::Config;
use Insipid::Database;
use Insipid::Sessions;

my $cgi = new CGI();
print $cgi->header(-type => "text/html", -charset => "utf-8");

# Retrieve all related tags as the user adds a tag. This is to reduce
# the mental guess-work for the type of user who loathes creating
# redundant tags. Invoke this subroutine via js in a text input event.
#
# @param $in:string - First letters of the tag to match.
# @return $out:string - HTML-formatted list of tags.
my ($in) = shift;

if ($in =~ /^[0-9a-z:_]+/i)
{
	my ($sql, $sth);

	# The user has typed in the first two letters, look for a match.
	# Order suggestions by popularity.
	$sql = "select $tbl_tags.name,count(*) from $tbl_tags
		inner join $tbl_bookmark_tags on
			($tbl_tags.id = $tbl_bookmark_tags.tag_id)
		where ($tbl_tags.name LIKE '$in%')
		group by $tbl_tags.name
		order by count( * ) desc";
	$sth = $dbh->prepare($sql);
	$sth->execute();

	# external wrappers div.suggestlist>ul> ... /ul/div
	if($sth->rows ne 0) 
	{
		my $out = "";
		#$out .= "Content-Type: text/html; charset=UTF-8\n\n";
		while(my @r = $sth->fetchrow_array()) {
			$out .= "<li>$r[0]</li>";
		}
		print $out;
	}
}
