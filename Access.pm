package Logfile::Access;

# $Id: Access.pm,v 2.0.2 2004/10/25 18:58:12 therealbstern Exp $

use 5.010; # Perl 5.10 brought named capture groups.
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = ();
our @EXPORT = ();
our $VERSION = '2.03';

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
        $$self{'content_length'} = 0 if $+{'length'} eq '-';
        $$self{'http_referer'} = $+{'referer'};
        $$self{'http_user_agent'} = $+{'agent'};

        $$self{'day'} =~ s/^0//;
        $$self{'year'} =~ s/^0//;
        $$self{'hour'} =~ s/^0//;
        $$self{'minute'} =~ s/^0//;
        $$self{'second'} =~ s/^0//;

        return 1;
    } else {
        return undef;
    }
}

sub print($) {
    my $self = shift;

    printf('%s %s %s [%s] "%s %s %s" %s %s',
        $$self{remote_host}, $$self{logname}, $$self{user}, $self->datetime,
        $$self{method}, $$self{object}, $$self{protocol}, $$self{response_code},
        $$self{content_length});
    printf(' "%s" %s"', $$self{http_referer}, $$self{http_user_agent})
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

sub remote_host($;$) { return get_set_stuff(shift, 'remote_host', shift); }
sub logname($;$) { return get_set_stuff(shift, 'logname', shift); }
sub user($;$) { return get_set_stuff(shift, 'user', shift); }
sub date($;$) { return get_set_stuff(shift, 'date', shift); }
sub time($;$) { return get_set_stuff(shift, 'time', shift); }
sub offset($;$) { return get_set_stuff(shift, 'offset', shift); }
sub method($;$) { return get_set_stuff(shift, 'method', shift); }
sub protocol($;$) { return get_set_stuff(shift, 'protocol', shift); }
sub response_code($;$) { return get_set_stuff(shift, 'response_code', shift); }
sub content_length($;$) {
    return get_set_stuff(shift, 'content_length', shift);
}
sub http_referer($;$) { return get_set_stuff(shift, 'http_referer', shift); }
sub http_user_agent($;$) {
    return get_set_stuff(shift, 'http_user_agent', shift);
}
sub object($;$) { return get_set_stuff(shift, 'object', shift); }

sub datetime($;$) {
    my ($self, $val) = @_;

    if (defined $val) {
        my @fields = split /[\s\/:]/, $val;
        $$self{day} = $fields[0];
        $$self{month} = $fields[1];
        $$self{year} = $fields[2];
        $$self{date} = sprintf('%0.2d/%3.3s/%0.4d',
            $fields[0], $fields[1], $fields[2]);
        $$self{hour} = $fields[3];
        $$self{minute} = $fields[4];
        $$self{second} = $fields[5];
        $$self{time} = sprintf('%0.2d:%0.2d:%0.2d',
            $fields[3], $fields[4], $fields[5]);
        $$self{offset} = $fields[6];
        foreach (qw(day year hour minute second)) {
            $$self{$_} =~ s/^0+//;
        }
    }
    return $$self{date} . ':' . $$self{time} . ' ' . $$self{offset};
}

sub query_string($) {
    my $self = shift;

    return $1 if $$self{object} =~ /\?(.*)/;
    return undef;
}

sub path($) {
    my $self = shift;

    return $1 if $$self{object} =~ /(.*)\//;
    return undef;
}

sub filename($) {
    my $self = shift;

    if (my $name = $$self{object}) {
        $name =~ s/[?#].*//;
        return $1 if $name =~ /.*\/(.*)/;
    }

    return undef;
}

sub anchor($) {
    my $self = shift;

    my $val = $$self{object};
    $val = s/\?.*//;
    return $1 if $val =~ /#(.*)/;
    return undef;
}

sub get_set_date($$;$) {
    my ($self, $what, $val) = @_;

    if (defined $val) {
        $val =~ s/^0// if length $val > 1;
        $$self{$what} = $val;
        $$self{date} = sprintf('%0.2d/%3.3s/%0.4d',
            $$self{day}, $$self{month}, $$self{year});
        $$self{$what} =~ s/^0+//; # Doesn't do anything to months, but wevs.
    }
    return $$self{$what};
}

sub mday($;$)  { return get_set_date(shift, 'day',   shift); }
sub day($;$)   { return get_set_date(shift, 'day',   shift); }
sub month($;$) { return get_set_date(shift, 'month', shift); }
sub year($;$)  { return get_set_date(shift, 'year',  shift); }

sub get_set_time($$;$) {
    my ($self, $what, $val) = @_;

    if (defined $val) {
        $val =~ s/^0// if length $val > 1;
        $$self{$what} = $val;
        $$self{time} = sprintf('%0.2d:%0.2d:%0.2d',
            $$self{hour}, $$self{minute}, $$self{second});
        $$self{$what} =~ s/^0+//;
    }
    return $$self{$what};
}

sub hour($;$)   { return get_set_time(shift, 'hour',   shift); }
sub minute($;$) { return get_set_time(shift, 'minute', shift); }
sub second($;$) { return get_set_time(shift, 'second', shift); }

sub mime_type($) {
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

Logfile::Access - Perl module for parsing Common Log Format webserver logs

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

A module for parsing common log format webserver access log files.

=head1 DESCRIPTION

Common Log Format is (as discussed on Wikipedia at L<https://en.wikipedia.org/wiki/Common_Log_Format>):

C<127.0.0.1 user-identifier frank [10/Oct/2000:13:55:36 -0700] "GET /apache_pb.gif HTTP/1.0" 200 2326>

Another example:

C<127.0.0.1 - - [10/Oct/2000:13:55:36 +0000] "GET /a/apache_pb.html?foo=bar HTTP/1.1" 302 - "http://localhost/index.html" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36">

=head2 Long Explanation

This ends up being fairly long after C<perldoc> formats it, so if you want to skip it and get to the function explanations, the next section is named L<General Functions>.

The mapping between these example lines and the fields that this module provides is:

=over

=item * C<remote_host>: 127.0.0.1 (in both examples)

=item * C<logname>

=over

=item * user-identifier

=item * -

=back

=item * C<user>

=over

=item * frank

=item * -

=back

=item * C<date>: 10/Oct/2000

=over

=item * C<day>: 10

=item * C<month>: Oct

=item * C<year>: 2000

=back

=item * C<time>: 13:55:36

=over

=item * C<hour>: 13

=item * C<minute>: 55

=item * C<second>: 36

=back

=item * C<offset>

=over

=item * -0700

=item * +0000

=back

=item * C<method>: GET

=item * C<object>: /apache_pb.gif

=over

=item * C<path>: /a

=item * C<filename>: apache_pb.html`

=item * C<anchor>: foo

=item * C<query>: bar=quux

=back

=item * C<protocol>

=over

=item * HTTP/1.0

=item * HTTP/1.1

=back

=item * C<response_code>

=over

=item * 200

=item * 302

=back

=item * C<content_length>

=over

=item * 2326

=item * 0

=back

=item * C<http_referer>

=over

=item * C<undef>

=item * http://localhost/index.html

=back

=item * C<http_user_agent>

=over

=item * C<undef>

=item * Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36

=back

=back

=head2 General Functions

=over

=item * new: Creates a new logfile parser object.

=item * parse: Parses a common log format line.  Returns C<undef> on error.

=item * print: Outputs the data as a common log format line.

=back

=head2 Read/Write Accessor Functions

Few of these error-check their input.  If you feed this module garbage, you're
likely going to get garbage back.

=over

=item * remote_host: Sets or gets the remote host in the current object.

=item * logname: Sets or gets the C<logname> in the current object, which is
        almost always '-' because almost no one runs an IDENT server (and no one
        should trust someone else's IDENT server anyway).  (See
        L<https://tools.ietf.org/html/rfc1413> if you want to know more about
        IDENT anyway.)

=item * user: Sets or gets the username, which is usually C<-> unless your
        webserver is performing some kind of authentication.

=item * date: Sets or gets the Common Logile Format date (dd/mmm/yyyy).

=item * day: Sets or gets the day of the month, without leading zeroes.  (It
        will accept leading zeroes but removes them before storing them.)

=item * month: Sets or gets the abbreviated name of the month.  If you pass this
        a number, it will put in a number, so don't do that.

=item * year: Sets or gets the year.  Does the same thing as C<day> with regards
        to leading zeroes, in case you have a webserver log from more than a
        thousand years ago.

=item * time: Sets or gets the time (and expects HH:MM:SS).

=item * hour: Sets or gets the hour.  Does the same thing as C<day> with regards
        to leading zeroes.

=item * minute: Sets or gets the minute, but otherwise just like C<day>.

=item * second: Sets or gets the seconds, but otherwise just like C<day>.

=item * offset: Sets or gets the GMT offset.

=item * datetime: Sets or gets the full date/time stamp (with zone).

=item * method: Sets or gets the request method (C<GET>, C<POST>, etc.).

=item * object: Sets or gets the full request, path, object, query, and all.
        This I<does> return C</> if that was the request.  Like the accessors
        below, it doesn't do any URI decoding.

=item * protocol: Sets or gets the request protocol.

=item * response_code: Sets or gets the numeric response code.

=item * content_length: Sets or gets the content length in bytes.

=item * http_referer: Sets or gets the HTTP referrer.  Note that the function
        spells "referer" with a total of 3 Rs, to match the misspelling of the
        HTTP header.

=item * http_user_agent: Sets or gets the HTTP User Agent string.

=back

=head2 Read-Only Accessors

None of these do any decoding, which lets you decide if you want to decode the
strings.  (Previous versions of the module didn't decode URIs properly anyway.)

=over

=item * query_string: Returns the query string from the request object, if any.
        Returns false if there is no query string.

=item * path: Returns the request path, if any (i.e., everything after the last
        C</> and before the query string).

=item * filename: Returns the name of the requested object, without any
        directory information (nor any query string).

=item * anchor: Returns the name of the anchor of the request (everything after
      the first '#', if any, and before the first '?', if any).

=item * mime_type: Returns the object's mime type, if any.  Returns `undef` if
        the system C<mime.types> file didn't identify the extension of the file.
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

=item * scheme: Returned the request object scheme.

=item * unescape_object: Returned the unescaped object string.

=item * escape_object: Returned the escaped object string.

=over

Rationale for removal: Removing these removed a dependency upon L<URI::Encode>
and it didn't always do the right thing anyway.  If you need the objects
decoded, you're better off in control of the decoding yourself.  If you want the
scheme, it's pretty easy to get from the C<object>.

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

David Tiberio, L<dtiberio5@hotmail.com>, through version 1.30.

Ben Stern, L<bas-github@fortian.com>, starting with version 2.00.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 David Tiberio, dtiberio5@hotmail.com

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. 

Copyright 2018 Ben Stern

Since version 2.00, "the same terms as Perl itself" means the GPL, version 2,
since that's how Perl is licensed (as of the writing of this documentation), so
this is licensed under the terms of the GNU Public License, version 2.  You
should have received a file named "LICENSE" with this module.  If you did not,
you can find one at L<https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
(or by writing to 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA).

=cut
