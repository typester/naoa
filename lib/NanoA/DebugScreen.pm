package NanoA::DebugScreen;

use strict;
use warnings;

# original taken from MENTA

sub build {
    my $msg = shift;
    my @trace;
    for (my $i = 1; my ($package, $file, $line) = caller($i); $i++) {
        push @trace, {
            file => $file,
            line => $line,
            func => '',
        };
        if (my @c = caller($i + 1)) {
            $trace[-1]->{func} = $c[3]
                if $c[3];
        }
    }
    if ($msg =~ / at ([^ ]+) line (\d+)\./
            && ($1 ne $trace[0]->{file} || $2 != $trace[0]->{line})) {
        unshift @trace, {
            file => $1,
            line => $2,
        };
    }
    @trace = map {
        +{
            level   => $_ + 1,
            %{$trace[$_]},
        }
    } 0..$#trace;
    
    +{ message => $msg, trace => \@trace };
}

sub build_context {
    my ($file, $linenum) = @_;
    my $code;
    if (-f $file) {
        my $start = $linenum - 3;
        my $end   = $linenum + 3;
        $start = $start < 1 ? 1 : $start;
        open my $fh, '<:utf8', $file
            or die "cannot open $file:$!";
        my $cur_line = 0;
        while (my $line = <$fh>) {
            ++$cur_line;
            last if $cur_line > $end;
            next if $cur_line < $start;
            $line =~ s|\t|        |g;
            my @tag = $cur_line == $linenum
                ? (q{<b style="color: #000;background-color: #f99;">}, '</b>')
                    : ('', '');
            $code .= sprintf(
                '%s%5d: %s%s', $tag[0], $cur_line, NanoA::escape_html($line),
                $tag[1],
            );
        }
        close $file;
    }
    return $code;
}

sub output {
    my $err = shift;
    
    warn $err->{message};
    
    print "Status: 500\r\n";
    print "Content-type: text/html; charset=utf-8\r\n";
    print "\r\n";
    
    my $body = do {
        my $msg = NanoA::escape_html($err->{message});
        my $out = qq{<!doctype html><title>INTERNAL SERVER ERROR!!!</title><body style="background: red; color: white; font-weight: bold"><marquee behavior="alternate" scrolldelay="66" style="text-transform: uppercase"><span style="font-size: xx-large; color: black">&#x2620;</span> <span style="color: green">500</span> Internal Server Error <span style="font-size: xx-large; color: black">&#x2620;</span></marquee><p><span style="color: blue">$msg</span></p><ol>};
        for my $stack (@{$err->{trace}}) {
            $out .= join(
                '',
                '<li>',
                $stack->{func},
                ' at ',
                $stack->{file} ? NanoA::escape_html($stack->{file}) : '',
                ', ',
                $stack->{line},
                q(<pre style="background-color: #fee;color: #333;">),
                build_context($stack->{file}, $stack->{line}),
                q(</pre></li>),
            );
        }
        $out .= qq{</ol><p style="text-align: right; color: black"><strong>Regards,<br>NanoA</strong></p>\n};
        $out;
    };
    utf8::encode($body);
    print $body;
}

"ENDOFMODULE";
