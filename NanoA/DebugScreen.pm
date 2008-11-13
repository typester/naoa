package NanoA::DebugScreen;

use strict;
use warnings;

# dead copy from MENTA

*escape_html = \&NanoA::escape_html;

sub build {
    my $msg = shift;
    my $i = 1;
    my @trace;
    while ( my ($package, $filename, $line,) = caller($i) ) {
        last if $filename eq 'bin/cgi-server.pl';
        my $context = sub {
            my ( $file, $linenum ) = @_;
            my $code;
            if ( -f $file ) {
                my $start = $linenum - 3;
                my $end   = $linenum + 3;
                $start = $start < 1 ? 1 : $start;
                open my $fh, '<', $file or die "cannot open $file";
                my $cur_line = 0;
                while ( my $line = <$fh> ) {
                    ++$cur_line;
                    last if $cur_line > $end;
                    next if $cur_line < $start;
                    my @tag =
                        $cur_line == $linenum
                            ? (q{<b style="color: #000;background-color: #f99;">}, '</b>')
                                : ( '', '' );
                    $code .= sprintf( '%s%5d: %s%s',
                                      $tag[0], $cur_line,
                                      escape_html($line),
                                      $tag[1], );
                }
                close $file;
            }
            return $code;
        }->($filename, $line);
        push @trace, {level => $i, package => $package, filename => $filename, line => $line, context => $context };
        $i++;
    }
    die { message => $msg, trace => \@trace };
}

sub output {
    my $err = shift;
    
    warn $err->{message};
    
    print "Status: 500\r\n";
    print "Content-type: text/html; charset=utf-8\r\n";
    print "\r\n";
    
    my $body = do {
        my $msg = escape_html($err->{message});
        my $out = qq{<!doctype html><title>INTERNAL SERVER ERROR!!! HACKED BY MENTA</title><body style="background: red; color: white; font-weight: bold"><marquee behavior="alternate" scrolldelay="66" style="text-transform: uppercase"><span style="font-size: xx-large; color: black">&#x2620;</span> <span style="color: green">500</span> Internal Server Error <span style="font-size: xx-large; color: black">&#x2620;</span></marquee><p><span style="color: blue">$msg</span></p><ol>};
        for my $stack (@{$err->{trace}}) {
            $out .= '<li>' . escape_html(join(', ', $stack->{package}, $stack->{filename}, $stack->{line}))
                . qq(<pre style="background-color: #fee;color: #333;">$stack->{context}</pre></li>);
        }
        $out .= qq{</ol><p style="text-align: right; color: black"><strong>Regards,<br>MENTA</strong></p>\n};
        $out;
    };
    print $body;
}

1;
