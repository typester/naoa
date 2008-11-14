package CGI::Simple::Cookie;

# Original version Copyright 1995-1999, Lincoln D. Stein. All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module as you
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.

# This version Copyright 2001, Dr James Freeman. All rights reserved.
# Renamed, strictified, and generally hacked code. Now 30% shorter.
# Interface remains identical and passes all original CGI::Cookie tests

use strict;
use vars '$VERSION';
$VERSION = '1.106';
use CGI::Simple::Util qw(rearrange unescape escape);
use overload '""' => \&as_string, 'cmp' => \&compare, 'fallback' => 1;

# fetch a list of cookies from the environment and return as a hash.
# the cookies are parsed as normal escaped URL data.
sub fetch {
  my $self = shift;
  my $raw_cookie = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
  return () unless $raw_cookie;
  return $self->parse( $raw_cookie );
}

sub parse {
  my ( $self, $raw_cookie ) = @_;
  return () unless $raw_cookie;
  my %results;
  my @pairs = split "; ?", $raw_cookie;
  for my $pair ( @pairs ) {
    $pair =~ s/^\s+|\s+$//;    # trim leading trailing whitespace
    my ( $key, $value ) = split "=", $pair;
    next unless defined $value;
    my @values = map { unescape( $_ ) } split /[&;]/, $value;
    $key = unescape( $key );

    # A bug in Netscape can cause several cookies with same name to
    # appear.  The FIRST one in HTTP_COOKIE is the most recent version.
    $results{$key} ||= $self->new( -name => $key, -value => \@values );
  }
  return wantarray ? %results : \%results;
}

# fetch a list of cookies from the environment and return as a hash.
# the cookie values are not unescaped or altered in any way.
sub raw_fetch {
  my $raw_cookie = $ENV{HTTP_COOKIE} || $ENV{COOKIE};
  return () unless $raw_cookie;
  my %results;
  my @pairs = split "; ?", $raw_cookie;
  for my $pair ( @pairs ) {
    $pair =~ s/^\s+|\s+$//;    # trim leading trailing whitespace
    my ( $key, $value ) = split "=", $pair;

    # fixed bug that does not allow 0 as a cookie value thanks Jose Mico
    # $value ||= 0;
    $value = defined $value ? $value : '';
    $results{$key} = $value;
  }
  return wantarray ? %results : \%results;
}

sub new {
  my ( $class, @params ) = @_;
  $class = ref( $class ) || $class;
  my ( $name, $value, $path, $domain, $secure, $expires ) = rearrange(
    [
      'NAME', [ 'VALUE', 'VALUES' ],
      'PATH',   'DOMAIN',
      'SECURE', 'EXPIRES'
    ],
    @params
  );
  return undef unless defined $name and defined $value;
  my $self = {};
  bless $self, $class;
  $self->name( $name );
  $self->value( $value );
  $path ||= "/";
  $self->path( $path )       if defined $path;
  $self->domain( $domain )   if defined $domain;
  $self->secure( $secure )   if defined $secure;
  $self->expires( $expires ) if defined $expires;
  return $self;
}

sub as_string {
  my $self = shift;
  return "" unless $self->name;
  my $name   = escape( $self->name );
  my $value  = join "&", map { escape( $_ ) } $self->value;
  my @cookie = ( "$name=$value" );
  push @cookie, "domain=" . $self->domain   if $self->domain;
  push @cookie, "path=" . $self->path       if $self->path;
  push @cookie, "expires=" . $self->expires if $self->expires;
  push @cookie, "secure"                    if $self->secure;
  return join "; ", @cookie;
}

sub compare {
  my ( $self, $value ) = @_;
  return "$self" cmp $value;
}

# accessors subs
sub name {
  my ( $self, $name ) = @_;
  $self->{'name'} = $name if defined $name;
  return $self->{'name'};
}

sub value {
  my ( $self, $value ) = @_;
  if ( defined $value ) {
    my @values
     = ref $value eq 'ARRAY' ? @$value
     : ref $value eq 'HASH'  ? %$value
     :                         ( $value );
    $self->{'value'} = [@values];
  }
  return wantarray ? @{ $self->{'value'} } : $self->{'value'}->[0];
}

sub domain {
  my ( $self, $domain ) = @_;
  $self->{'domain'} = $domain if defined $domain;
  return $self->{'domain'};
}

sub secure {
  my ( $self, $secure ) = @_;
  $self->{'secure'} = $secure if defined $secure;
  return $self->{'secure'};
}

sub expires {
  my ( $self, $expires ) = @_;
  $self->{'expires'} = CGI::Simple::Util::expires( $expires, 'cookie' )
   if defined $expires;
  return $self->{'expires'};
}

sub path {
  my ( $self, $path ) = @_;
  $self->{'path'} = $path if defined $path;
  return $self->{'path'};
}

"ENDOFMODULE";
