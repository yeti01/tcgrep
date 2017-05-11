=begin metadata

Xref: feenix.metronet.com comp.unix.questions:11476
Newsgroups: comp.unix.questions
Path: feenix.metronet.com!news.utdallas.edu!wupost!howland.reston.ans.net!pipex!uunet!boulder!wraeththu.cs.colorado.edu!tchrist
From: Tom Christiansen <tchrist@cs.Colorado.EDU>
Subject: Re: grep with highlight capability anyone?
Message-ID: <CE5G42.77u@Colorado.EDU>
Originator: tchrist@wraeththu.cs.colorado.edu
Sender: news@Colorado.EDU (USENET News System)
Reply-To: tchrist@cs.colorado.edu (Tom Christiansen)
Organization: University of Colorado, Boulder
References: <1993Sep28.173028.27194@bellahs.com>
Date: Thu, 30 Sep 1993 04:21:37 GMT
Lines: 148

From the keyboard of gfong@bellahs.com (Gary Fong RD):
:UNIXians,
:Does there exist a command as powerful as grep which
:highlights/reversevideo/bolds the matching string/expression?

I use the -H flag in the following program.  Usages
Perl regexps, meaning more like egrep than grep. 
See the usage for other features, like recursion, 
match-once, textfile only, and paragraph mode.

--tom

=end metadata

=cut

#!/usr/bin/perl
#
# tcgrep: tom christiansen's rewrite of grep
# tchrist@colorado.edu
# see usage for features
# yet to implement: -f

require 'getopts.pl';
&Getopts("inqclse:f:xwhv1pHtr") || &usage;

die "-f unsupported" if $opt_f;

$Pattern = $opt_e || shift || &usage;

eval { /$Pattern/, 1 } || die "$0: bad pattern: $@";

if ($opt_H) {
    $ospeed = 13;  # bogus but shouldn't hurt; means 9600
    require 'termcap.pl';
    &Tgetent($ENV{TERM} || 'vt100');
}

$opt_i && $Pattern =~ s/\w/[\u$&\l$&]/gi;
$opt_p && ($/ = '');
$opt_w && ($Pattern = '\b' . $Pattern . '\b');
$opt_x && ($Pattern = "^$Pattern\$");
$opt_1 += $opt_l;
$mult = 1 if ($opt_r || @ARGV > 1) && !$opt_h;

@ARGV = ($opt_r ? '.' : '-') unless @ARGV;

$Errors = $Total = 0;

&match(@ARGV);
print $Total, "\n" if $opt_c;

exit(2) if $Errors;
exit(0) if $Total;
exit(1);

######################################

sub match {
    local($_,$file);
    local(@list);
    local($matches);

    #warn "match /$Pattern/ @_\n";

FILE: 
    while ($file = shift) {

	if (-d $file) {
	    next FILE if -l $file;
	    if (!$opt_r) {
		warn "$0: $file is a directory, but no -r given\n";
		next FILE;
	    } 
	    if (!opendir(DIR, $file)) {
		unless ($opt_q) {
		    warn "$0: can't opendir $file: $!\n";
		    $Errors++;
		}
		next FILE;
	    } 
	    @list = ();
	    for (sort readdir(DIR)) {
		push(@list, "$file/$_") unless /^\.{1,2}$/;
	    } 
	    closedir(DIR);
	    &match(@list);
	    next FILE;
	} 

	#warn "checking $file\n";
	if (!open(FILE, $file)) {
	    unless ($opt_q) {
		warn "$0: $file: $!\n";
		$Errors++;
	    }
	    next FILE;
	} 

	if ($_ ne '-') {
	    next FILE unless -f FILE || $opt_d;
	    next FILE unless -T FILE || $opt_b;
	} else {
	    warn "$0: reading from stdin\n" if -t STDIN;
	} 
	$matches = 0;
LINE:  
	while (<FILE>) {
	    $matches = 0;
	    if ($opt_H) {
		$matches = s/$Pattern/$TC{'so'}$&$TC{'se'}/go;
	    } elsif ($opt_v) {
		$matches = !/$Pattern/o;
	    } else {
		$matches++ while /$Pattern/go; 	
	    }
	    next LINE unless $matches;
	    $Total += $matches;
	    print "$FILE\n", next FILE if $opt_l;
	    print $mult && "$file: ", $opt_n && "$.:", $_ unless $opt_s;
	    next FILE if $opt_1;
	} 
    }
}

sub usage { 
    die <<EOF
usage: $0 [flags] [files]
    i	case insensitive 
    n	number lines
    c	give count of matches 
    w 	word boundaries only
    s	silent mode
    x   exact matches only
    v	invert search sense (lines that DON'T match)
    h	hide filenames
    e	expression (for exprs beginning with -)
    f	file with expressions [unimplemented]
    l	list filenames matching
    1	1 match per file 
    r	recursive on directories or dot if none
    p	paragraph mode (default: line mode)
    b	binary files also (default: text only)
    d	device and special files also (default: files only)
    q	quiet about failed file and dir opens
    H	highlight matches
EOF
}
-- 
    Tom Christiansen      tchrist@cs.colorado.edu       
		    Consultant
	Boulder Colorado  303-444-3212
