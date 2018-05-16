package Logfile::Access;

# $Id: Access.pm,v 2.00 2004/10/25 18:58:12 therealbstern Exp $

use 5.010; # Perl 5.10 brought named capture groups.
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ();
our @EXPORT = ();
our $VERSION = '2.00';

our $MimePath = '/etc/httpd/mime.types';

sub new {
    my $self = {};

    bless $self;
    $self->load_mime_types;
    return $self;
}

my %mime_type = ();

sub load_mime_types {
    return if scalar keys %mime_type;

    if (open (IN, '<', $MimePath)) {
        while (<IN>) {
            next if /^\s*#/;
            s/#.*//;
            s/\s*$//;
            chomp;
            my @data = split /\s+/;
            my $type = shift @data;
            foreach my $extension (@data) {
                next unless $extension =~ /\w/;
                $mime_type{lc $extension} = $type;
            }
        }
        close IN;
    } else {
        die "Unable to open $MimePath: $!\n";
    }
}

use constant HOST => q{(?<host>\S+)};
use constant IDENT => q{(?<ident>\S+)};
use constant USER => q{(?<user>\S+)};
use constant DATE => q{(?<day>\d{2})\/(?<month>\w{3})\/(?<year>\d{4})};
use constant TIME => q{(?<hrs>[0-2]\d):(?<mins>[0-5]\d):(?<secs>[0-6]\d)};
use constant OFFSET => q{(?<zone>[-+]\d{4})};
use constant METHOD => q{(?<method>\S+)};
use constant OBJECT => q{(?<request>[^\s]+)};
use constant PROTOCOL => q{(?<proto>\w+\/[\d\.]+)};
use constant STATUS => q{(?<status>\d+|-)};
use constant CONTENT_LENGTH => q{(?<length>\d+|-)};
use constant HTTP_REFERER => q{(?<referer>[^"]+)}; # [sic]
use constant HTTP_USER_AGENT => q{(?<agent>[^"]+)};

sub parse {
    my $self = shift;
    my $row = shift;

    chomp $row;

    if ($row =~ /^@{[HOST]} @{[IDENT]} @{[USER]} \[@{[DATE]}:@{[TIME]} @{[OFFSET]}\] \"@{[METHOD]} @{[OBJECT]} @{[PROTOCOL]}\" @{[STATUS]} @{[CONTENT_LENGTH]}( \"?@{[HTTP_REFERER]}\"? \"?@{[HTTP_USER_AGENT]}\"?)?$/) {
        $$self{'remote_host'} = $+{'host'};
        $$self{'logname'} = $+{'ident'};
        $$self{'user'} = $+{'user'};
        $$self{'date'} = join('/', $+{'day'}, $+{'month'}, $+{'year'});
        $$self{'day'} = $+{'day'};
        $$self{'month'} = $+{'month'};
        $$self{'year'} = $+{'year'};
        $$self{'time'} = join(':', $+{'hrs'}, $+{'mins'}, $+{'secs'});
        $$self{'hour'} = $+{'hrs'};
        $$self{'minute'} = $+{'mins'};
        $$self{'second'} = $+{'secs'};
        $$self{'offset'} = $+{'zone'};
        $$self{'method'} = $+{'method'};
        $$self{'object'} = $+{'request'};
        $$self{'protocol'} = $+{'proto'};
        $$self{'response_code'} = $+{'status'};
        $$self{'content_length'} = $+{'length'};
        $$self{'http_referer'} = $+{'referer'};
        $$self{'http_user_agent'} = $+{'agent'};

        $$self{'day'} =~ s/^0//;
        $$self{'hour'} =~ s/^0//;
        $$self{'minute'} =~ s/^0//;
        $$self{'second'} =~ s/^0//;

        return 1;
    } else {
        return undef;
    }
}

sub print {
    my $self = shift;

    my $datetime = '[' . $$self{'date'} . ':' . $$self{'time'} . ' ' . $$self{'offset'} . ']';
    my $object = '"' . join(' ', $$self{'method'}, $$self{'object'}, $$self{'protocol'}) . '"';
    print join(' ', $$self{'remote_host'}, $$self{'logname'}, $$self{'user'}, $datetime, $object, $$self{'response_code'}, $$self{'content_length'});
    
    print ' "' . $$self{http_referer} . '" "' . $$self{http_user_agent} . '"'
        if $$self{http_referer} and $$self{http_user_agent};

    print "\n";
}

sub get_set_stuff($$;$) {
    my ($self, $what, $val) = @_;
    if (defined $val) {
        $$self{$what} = $val;
    }
    return $$self{$what};
}

sub remote_host     { return get_set_stuff(shift, 'remote_host',     shift); }
sub logname         { return get_set_stuff(shift, 'logname',         shift); }
sub user            { return get_set_stuff(shift, 'user',            shift); }
sub date            { return get_set_stuff(shift, 'date',            shift); }
sub time            { return get_set_stuff(shift, 'time',            shift); }
sub offset          { return get_set_stuff(shift, 'offset',          shift); }
sub method          { return get_set_stuff(shift, 'method',          shift); }
sub scheme          { return get_set_stuff(shift, 'scheme',          shift); }
sub protocol        { return get_set_stuff(shift, 'protocol',        shift); }
sub response_code   { return get_set_stuff(shift, 'response_code',   shift); }
sub content_length  { return get_set_stuff(shift, 'content_length',  shift); }
sub http_referer    { return get_set_stuff(shift, 'http_referer',    shift); }
sub http_user_agent { return get_set_stuff(shift, 'http_user_agent', shift); }
sub object          { return get_set_stuff(shift, 'object',          shift); }

sub get_set_date($$;$) {
    my ($self, $what, $val) = @_;

    if (defined $val) {
        $val =~ s/^0// if length $val > 1;
        $$self{$what} = $val;
        $$self{date} = sprintf('%0.2d/%3.3s/%0.4d', $$self{day}, $$self{month}, $$self{year});
    }
    return $$self{$what};
}

sub query_string {
    my $self = shift;

    return $1 if $$self{object} =~ /\?(.*)(#.*)?/;
    return undef;
}

sub path {
    my $self = shift;

    return $1 if $$self{object} =~ /(.*)\//;
    return undef;
}

sub filename {
    my $self = shift;

    if (my $name = $$self{object}) {
        $name =~ s/[?#].*//;
        return $1 if $name =~ /.*\/(.*)/;
    }

    return undef;
}

sub anchor {
    my $self = shift;

    return $1 if $$self{object} =~ /#(.*)/;
    return undef;
}

sub mday  { return get_set_date(shift, 'day',   shift); }
sub day   { return get_set_date(shift, 'day',   shift); }
sub month { return get_set_date(shift, 'month', shift); }
sub year  { return get_set_date(shift, 'year',  shift); }

sub get_set_time($$;$) {
    my ($self, $what, $val) = @_;

    if (defined $val) {
        $val =~ s/^0// if length $val > 1;
        $$self{$what} = $val;
        $$self{time} = sprintf('%0.2d:%0.2d:%0.2d', $$self{hour}, $$self{minute}, $$self{second});
    }
    return $$self{$what};
}

sub hour   { return get_set_time(shift, 'hour',   shift); }
sub minute { return get_set_time(shift, 'minute', shift); }
sub second { return get_set_time(shift, 'second', shift); }

sub mime_type {
    my $self = shift;

    my $object = $self->filename;
    if (defined $object and ($object =~ /.*\.(.*)[?#]?/)) {
        my $extension = lc $1;
        return $mime_type{$extension};
    }
    return undef;
}

1;
__END__

=head1 NAME

Logfile::Access - Perl extension for common log format web server logs

=head1 SYNOPSIS

  use Logfile::Access;

  # This is the default, but it shows how to set it anyway.
  $Logfile::Access::MimePath = '/etc/httpd/mime.types';

  my $log = new Logfile::Access;

  if (open IN, '<', $filename) {
      while (<IN>) {
          $log->parse($_);
          print 'Host: ' . $log->remote_host . "\n";
      }
      close IN;
  }

=head1 ABSTRACT

A module for parsing common log format web server access log files.

=head1 DESCRIPTION

=cut

=head2 General Functions

=over

=item * new: Defines new logfile row object.

=item * parse: Parses a common log format line.  Returns C<undef> on error.

=item * print: Outputs the data as a common log format line.

=back

=head2 Read/Write Accessor Functions

None of these error-check their input.  If you feed this module garbage, you're
going to get garbage back.

=over

=item * remote_host: Sets or gets the remote host in the current object.


=item * logname: Sets or gets the C<logname> in the current object, which is
        almost always '-' because almost no one runs an IDENT server (and no one
        should trust someone else's IDENT server anyway).

=item * user: Sets or gets the user name, which is usually '-' unless your
        webserver is performing some kind of authentication.

=item * date: Sets or gets the Common Logile Format date (dd/mmm/yyyy).

=item * day: Sets or gets the day of the month, without leading zeroes.  (It
      will accept leading zeroes but removes them before storing them.)

=item * month: Sets or gets the abbreviated name of the month.

=item * year: Sets or gets the year.  This doesn't look for leading zeroes,
      because we're not living in the 1st millenium AD.

=item * time: Sets or gets the time (and expects HH:MM:SS).

=item * hour: Sets or gets the hour.  Does the same thing as C<day> with
      regards to leading zeroes.

=item * minute: Sets or gets the minute, but otherwise just like C<day>.

=item * second: Sets or gets the seconds, but otherwise just like C<day>.

=item * offset: Sets or gets the GMT offset.

=item * method: Sets or gets the request method.

=item * scheme: Returns the request object scheme.

=item * object: Sets or gets the full request, path, object, query, and all.
      This I<does> return '/' if that was the request.  Like the accessors
      below, it doesn't do any URI decoding.

=item * protocol: Sets or gets the request protocol.

=item * response_code: Sets or gets the numeric response code.

=item * content_length: Sets or gets the content length in bytes.

=item * http_referer: Sets or gets the HTTP referrer.  Note that the function is
      named C<referer> with a total of 3 Rs, to match the misspelling of the HTTP
      header.

=item * http_user_agent: Sets or gets the HTTP User Agent string.

=back

=head2 Read-Only Accessors

None of these do any decoding, which lets you decide if you want to decode the
strings.  (Previous versions of the module didn't decode URIs properly anyway.)

=over

=item * query_string: Returns the query string from the request object, if any.
      Returns false if there is no query string.

=item * path: Returns the request path, if any (i.e., everything after the last
      '/' and before the query string).

=item * filename: Returns the name of the requested object, without any directory
      information (nor any query string).

=item * anchor: Returns the name of the anchor of the request (everything after
      the first '#', if any).

      I<Note>: the system's C<mime.types> file can be specified by setting
      C<$Logfile::Access::MimePath> before calling C<new>.

=back

=head2 Removed Functions

If you need these back, open an issue on GitHub
(L<https://github.com/therealbstern/Logfile-Access/issues>).

=over

=item * load_mime_types: Loaded mime types for filename extensions.

=over

Rationale for removal: C<new> calls this, and it always bailed out early if it
was called again, so it never did nothing useful for users of this module.

=back

=item * class_a: Returned the Class A of the C<remote_host>.

=item * class_b: Returned the Class B of the C<remote_host>.

=item * class_c: Returned the Class C of the C<remote_host>.

=over

Rationale for removal: You're probably better off calling C<split> if that's
what you want, and no one uses classful routing anymore anyway.

=back

=item * domain: Returned the domain of the remote_host.

=item * tld: Returned the top level domain of the remote_host.

=over

Rationale for removal: You're probably better off calling C<split>, the tests
for whether or not the host had a TLD were wrong, and these things are never
going to get simpler.

=back

=item * country_name: Returned the country name.

=over

Rationale for removal: Removing this removed a dependency upon Locale::Country,
these kinds of GeoIP databases are usually wrong unless you're paying for the
data, and anyway, you're better off using your favorite GeoIP module anyway.

=back

=item * unescape_object: Returned the unescaped object string.

=item * escape_object: Returned the escaped object string.

=over

Rationale for removal: Removing this removed a dependency upon L<URI::Encode>
and it didn't always do the right thing anyway.  If you need the objects
decoded, you're better off in control of the decoding yourself.

=back

=back

=head1 EXPORTED NAMES

None.

=head1 PREREQUISITES

Perl 5.10 or higher.  You almost certainly already have it.

=head1 SEE ALSO

L<http://www.apache.org/>

L<https://en.wikipedia.org/wiki/Common_Log_Format>

=head1 AUTHORS

David Tiberio, L<E<lt>dtiberio5@hotmail.comE<gt>> through version 1.30.

Ben Stern, L<E<lt>bas-github@fortian.comE<gt>> starting with version 2.00.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 David Tiberio, dtiberio5@hotmail.com

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

Copyright 2018 Ben Stern

Since version 2, "the same terms as Perl itself" means the GPL, version 2, since
that's how Perl is licensed (as of the writing of this documentation), so this
is licensed under the terms of the GNU Public License, version 2.  You should
have received a file named "LICENSE" with this module.  If you did not, you can
find one at L<https://www.gnu.org/licenses/old-licenses/gpl-2.0.html> (or by
writing to 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA).

=cut
