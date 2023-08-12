#! /usr/bin/perl
#
# tcgrep: tom christiansen's rewrite of grep
# tchrist@colorado.edu
# see usage for features
# yet to implement: -f
# v1.0: Thu Sep 30 16:24:43 MDT 1993
# v1.1: Fri Oct  1 08:33:43 MDT 1993
#
# Revision by Greg Bacon <gbacon@cs.uah.edu>
# Fixed up highlighting for those of us trapped in terminfo
# implemented -f
# v1.2: Fri Jul 26 13:37:02 CDT 1996

&init;
&parse_args;
&matchfile(@ARGV);

exit(2) if $Errors;
exit(0) if $Grand_Total;
exit(1);

######################################

sub init {
    ($me = $0) =~ s!.*/!!;
    $Errors = $Grand_Total = 0;
    $| = 1;

    %Compress = (
        'z',    gzcat,
        'gz',   gzcat,
        'Z',    zcat,
    );
}

sub matchfile {
    local($_,$file);
    local(@list);
    local($matches);
    local($total);

FILE: while (defined ($file = shift(@_))) {

        if (-d $file) {
            if (-l $file && @ARGV != 1) {
                warn "$me: \"$file\" is a symlink to a directory\n"
                    if $opt_T;
                next FILE;
                
            } 
            if (!$opt_r) {
                warn "$me: \"$file\" is a directory, but no -r given\n"
                    if $opt_T;
                next FILE;
            } 
            if (!opendir(DIR, $file)) {
                unless ($opt_q) {
                    warn "$me: can't opendir $file: $!\n";
                    $Errors++;
                }
                next FILE;
            } 
            @list = ();
            for (readdir(DIR)) {
                push(@list, "$file/$_") unless /^\.{1,2}$/;
            } 
            closedir(DIR);
            if ($opt_t) {
                local(@dates, $i);
                for (@list) { push(@dates, -M) } 
                @list = @list[sort { $dates[$a] <=> $dates[$b] } 0..$#dates];
            } else {
                @list = sort @list;
            } 
            &matchfile(@list);
            next FILE;
        } 

        if ($file eq '-') {
            warn "$me: reading from stdin\n" if -t STDIN && !$opt_q;
            $name = '<STDIN>';
        } else {
            $name = $file;
            unless (-f $file || $opt_a) {
                warn qq($me: skipping non-plain file "$file"\n) if $opt_T;
                next FILE;
            }

            ($ext) = $file =~ /\.([^.]+)$/;
            if ( $Compress{$ext} ) {
                $file = "$Compress{$ext} <$file |";
            } elsif (! (-T $file  || $opt_a)) {
                warn qq($me: skipping binary file "$file"\n) if $opt_T;
                next FILE;
            }
        }

        warn "$me: checking $file\n" if $opt_T;

        if (!open(FILE, $file)) {
            unless ($opt_q) {
                warn "$me: $file: $!\n";
                $Errors++;
            }
            next FILE;
        } 
        $total = 0;

        $matches = 0;

LINE:  while (<FILE>) {
            $matches = 0;

            study if @Patterns > 5;

            if ($opt_H) {
                for $Pattern (@Patterns) {
		    $matches += s/$Pattern/${SO}$&${SE}/g;
                }
            } elsif ($opt_v) {
                for $Pattern (@Patterns) {
		    $matches += !/$Pattern/;
                }
            } elsif ($opt_C) {
                for $Pattern (@Patterns) {
		    $matches++ while /$Pattern/g;
                }
            } else {
                for $Pattern (@Patterns) {
		    $matches++ if /$Pattern/;
                }
            }

            next LINE unless $matches;
            $total += $matches;
            if ($opt_p || $opt_P) {
                local($*);
                s/\n{2,}$/\n/ if $opt_p;
                s,$/$,,o      if $opt_P;
            } 
            print("$name\n"), next FILE if $opt_l;
            $opt_s || print $mult  && "$name:", 
                            $opt_n && "$.:", 
                            $_, 
                            ($opt_p||$opt_P) && ('-' x 20)."\n";
            next FILE if $opt_1;
        }  
    } continue {
        print $mult  && "$name:", $total, "\n" if $opt_c;
    } 
    $Grand_Total += $total;
}

sub usage { 
    die <<EOF
usage: $me [flags] [files]

Standard grep options:
    i   case insensitive 
    n   number lines
    c   give count of lines matching
    C   ditto, but >1 match per line possible
    w   word boundaries only
    s   silent mode
    x   exact matches only
    v   invert search sense (lines that DON'T match)
    h   hide filenames
    e   expression (for exprs beginning with -)
    f   file with expressions
    l   list filenames matching

Specials:
    1   1 match per file 
    H   highlight matches
    u   underline matches
    r   recursive on directories or dot if none
    t   process directories in `ls -t` order
    p   paragraph mode (default: line mode)
    P   ditto, but specify separator, e.g. -P '%%\\n'
    a   all files, not just plain text files 
    q   quiet about failed file and dir opens
    T   trace files as opened
EOF
}

sub parse_args {

    require 'getopts.pl';

    if ($_ = $ENV{TCGREP}) {
        s/^[^\-]/-$&/;
        unshift(@ARGV, $_);
    } 

    &Getopts("inqcClsue:f:xwhva1pHtrT-P:") || &usage;

    if ($opt_f) {
        open(PATFILE, $opt_f) || die qq($me: Can't open '$opt_f': $!);

       # make sure perl is down with these patterns...
        while ($pattern = <PATFILE>) {
            chop $pattern;
	    eval { /$pattern/, 1 } || die "$me: $opt_f:$.: bad pattern: $@";
	    push @Patterns, $pattern;
        }
        close PATFILE;
    } else {
	$pattern = $opt_e || shift(@ARGV) || &usage;
	eval { /$pattern/, 1 } || die "$me: bad pattern: $@";
	@Patterns = ($pattern);
    }

    if ($opt_H || $opt_u) {
        $ospeed = 13;  # bogus but shouldn't hurt; means 9600
        require 'termcap.pl';
        local($term) = ($ENV{TERM} || 'vt100');
        &Tgetent($term);
        ($SO, $SE) =  $opt_H ? @TC{'so','se'} : @TC{'us','ue'};

        unless ($SO || $SE) {
            ($SO, $SE) = $opt_H
                  ?
                  (`tput -T $term smso`, `tput -T $term rmso`)
                  :
                  (`tput -T $term smul`, `tput -T $term rmul`);
        }
    }

    if ($opt_i) {
        if ($] < 5) {
            @Patterns = grep(s/\w/[\u$&\l$&]/gi, @Patterns);
        } else {
            @Patterns = grep($_ = "(?i)$_", @Patterns);
        } 
    }

    $opt_p && ($/ = '', $* = 1);
    $opt_P && ($/ = eval(qq("$opt_P")), $*=1); # for -P '%%\n'
    $opt_w && (@Patterns = grep($_ = '\b' . $_ . '\b', @Patterns));
    $opt_x && (@Patterns = grep($_ = "^$_\$", @Patterns));
    $mult = 1 if ($opt_r || (@ARGV > 1) || -d $ARGV[0]) && !$opt_h;
    $opt_1 += $opt_l;
    $opt_H += $opt_u;
    $opt_c += $opt_C;
    $opt_s += $opt_c;
    $opt_1 += $opt_s && !$opt_c;

    @ARGV = ($opt_r ? '.' : '-') unless @ARGV;
    $opt_r = 1 if !$opt_r && grep(-d, @ARGV) == @ARGV;
}
