#!/usr/bin/perl
#
# Copyright (C) 2008 Luke Reeves
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# USA
#

package Insipid::Database;

use strict;
use warnings;

use Insipid::Config;
use Insipid::Schemas;

use DBI qw/:sql_types/;;
use vars qw($version);

use Exporter ();
our (@ISA, @EXPORT);
	
@ISA = qw(Exporter);
@EXPORT = qw($dbname $dbuser $dbpass $dsn $dbh $dbtype get_option 
	install $version $tag_url $feed_url $full_url $snapshot_url
	export_options $dbprefix);
	
our ($dsn, $dbh, $dbname, $dbuser, $dbpass, $snapshot_url,
	$dbtype, $tag_url, $feed_url, $full_url, $dbprefix);

$dbname = getconfig('dbname');
$dbuser = getconfig('dbuser');
$dbpass = getconfig('dbpass');

if(defined(getconfig('dbtype'))) {
	$dbtype = getconfig('dbtype');
} else {
	$dbtype = 'mysql';
}

$dsn = "DBI:$dbtype:dbname=$dbname;host=localhost";
$dbh = DBI->connect($dsn, $dbuser, $dbpass, { 'RaiseError' => 0}) or die $DBI::errstr;

my %options;

sub export_options {
	my ($writer) = (@_);
	my ($sth);
	
	$writer->startTag('options');
	$sth = $dbh->prepare("select name, value from $tbl_options");
	$sth->execute();
	while(my $row = $sth->fetchrow_hashref) {
		if($row->{name} ne 'version') {
			$writer->emptyTag('option', 
				'name' => $row->{name},
				'value' => $row->{value});
		}
	}
	
	$writer->endTag('options');
}

sub dbupgrade {
	my ($sql, $sth);

	$sql = "update $tbl_options set value = ? where (name = ?)";
	$sth = $dbh->prepare($sql);
	$sth->execute($version, 'version');

	$sql = "insert into $tbl_options(name, value, description) 
			values(?, ?, ?)";
	$sth = $dbh->prepare($sql);
	$sth->execute('version', $version, 'Internal Insipid version');
	$sth->execute('use_rewrite', 'yes', 'Use mod_rewrite - disable this if you do not want to use mod_rewrite.');

	# Delete the old sessions table
	$sql = 'drop table sessions';
	$sth = $dbh->prepare($sql);
	$sth->execute();

	# Create the new session table if it's not there.
	$sql = "create table $tbl_authentication (
			session_id varchar(32),
			create_time int,
			primary key(session_id))";
	$sth = $dbh->prepare($sql);
	$sth->execute();
	if($dbh->errstr) {
		print STDERR $dbh->errstr;
	}

	# For Postgresql we have to do some horrible magic to get all of the
	# tags to be case-insensitive.
	if($dbtype eq 'Pg') {
		$sql = "create unique index lower_name_idx ON $tbl_tags ((lower(name)))";
		$sth = $dbh->prepare($sql);
		$sth->execute();
		
		if($dbh->errstr =~ /duplicated values/) {
			print STDERR "Coalescing the tags.\n";
		
			# Now for the tricky part of collapsing the tags. 
			# First we find all duplicates, then update the one with *less*
			# candidates to the title with the *most* candidates
			$sql = "select $tbl_tags.name, count(*) 
				   from $tbl_bookmarks  
				   inner join $tbl_bookmark_tags on
					($tbl_bookmarks.id = $tbl_bookmark_tags.bookmark_id)
				   inner join $tbl_tags on
					($tbl_tags.id = $tbl_bookmark_tags.tag_id)
				   group by $tbl_tags.name
				   order by $tbl_tags.name";
			$sth = $dbh->prepare($sql);
			$sth->execute();
			
			# Now we populate an ordered list (to find dupes), and a hash 
			# (for the votes)
			my @tagnames;
			my %tagvotes;
				   
		}
	}	
	
	return;
}

sub get_option {
	my ($name) = (@_);

	if(keys (%options) == 0) {
		reload_options();
	}
	
	# FORCE UPGRADE FOR DEV WORK
	dbupgrade();

	# Determine if we need to upgrade the database
	if($version ne $options{'version'}) {
		print STDERR "Upgrading schema from $options{'version'} to $version.\n";
		dbupgrade();
		reload_options();
	}

	return $options{$name};
}

sub reload_options {
	my $sql = "select name, value from $tbl_options";
	my $sth = $dbh->prepare($sql);
	$sth->execute() or die $DBI::errstr;

	while(my $hr = $sth->fetchrow_hashref) {
		$options{$hr->{'name'}} = $hr->{'value'};
	}
}

# This configures the URLs in the application to support mod_rewrite or
# a webserver sans mod_rewrite.
if(get_option('use_rewrite') eq 'yes') {
	$tag_url  	= $site_url . '/bookmarks/';
	$feed_url 	= $site_url . '/feeds/bookmarks';
	$full_url 	= $site_url . '/bookmarks';
	$snapshot_url	= $site_url . '/snapshot/';
} else {
	$tag_url  	= 'insipid.cgi?tag=';
	$feed_url 	= $site_url . '/insipid.cgi?op=rss&tag=';
	$full_url 	= $site_url . '/insipid.cgi';
	$snapshot_url	= 'insipid.cgi?op=viewsnapshot&md5=';
}


1;
__END__
