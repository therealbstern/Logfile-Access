A module for parsing common log format web server access log files.

# Synopsis

```perl
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
```

# Description

General Functions

* `new`: Defines new logfile row object.
* `parse`: Parses a common log format line.  Returns `undef` on error.
* `print`: Outputs the data as a common log format line.

## Read/Write Accessor Functions

None of these error-check their input. If you feed this module garbage, you're
going to get garbage back.

* `remote_host`: Sets or gets the remote host in the current object.
* `logname`: Sets or gets the `logname` in the current object, which is almost
  always `-` because almost no one runs an IDENT server (and no one should trust
  someone else's IDENT server anyway).
* `user` Sets or gets the username, which is usually `-` unless your webserver
  is performing some kind of authentication.
* `date`: Sets or gets the Common Logile Format date (dd/mmm/yyyy).
* `day`: Sets or gets the day of the month, without leading zeroes.  (It will
  accept leading zeroes but removes them before storing them.)
* `month`: Sets or gets the abbreviated name of the month.
* `year`: Sets or gets the year. This doesn't look for leading zeroes,
  because we're not living in the 1st millenium AD.
* `time`: Sets or gets the time (and expects HH:MM:SS).
* `hour`: Sets or gets the hour.  Does the same thing as `day` with regards to
  leading zeroes.
* `minute`: Sets or gets the minute, but otherwise just like `day`.
* `second`: Sets or gets the seconds, but otherwise just like `day`.
* `offset`: Sets or gets the GMT offset.
* `method`: Sets or gets the request method.
* `scheme`: Returns the request object scheme.
* `object`: Sets or gets the full request, path, object, query, and all.  This
  *does* return `/` if that was the request.  Like the accessors below, it
  doesn't do any URI decoding.
* `protocol`: Sets or gets the request protocol.
* `response_code`: Sets or gets the numeric response code.
* `content_length`: Sets or gets the content length in bytes.
* `http_referer`: Sets or gets the HTTP referrer, or `undef`.  Note that the
  function is named "referer" with a total of 3 Rs, to match the misspelling of
  the HTTP header.
* `http_user_agent`: Sets or gets the HTTP User Agent string.  Returns `undef`
  if the UA wasn't provided.

## Read-Only Accessors

None of these do any decoding, which lets you decide if you want to decode the
strings.  (Previous versions of the module didn't decode URIs properly anyway.)

* `query_string`: Returns the query string from the request object, if any.
  Returns `undef` if there is no query string.
* `path`: Returns the request path (i.e., everything after the last `/` and
  before the query string, if any).  Returns `undef` in the event that the
  request was for `/`.
* `filename`: Returns the name of the requested object, without any directory
  information (nor any query string).  Returns `undef` if the request was for a
  directory and did not specify a file (or, more strictly, an object).
* `anchor`: Returns the name of the anchor of the request (everything after the
  first '#', if any).  Returns `undef` if no anchor was given.
* `mime_type`: returns the object's mime type, if any.  Returns `undef` if the
  system `mime.types` file didn't identify the extension of the file.  *Note*:
  the system's `mime.types` file can be specified by setting
  `$Logfile::Access::MimePath` before calling `new`.

## Removed Functions

If you need these back, open an issue on GitHub at
<https://github.com/therealbstern/Logfile-Access/issues>.

* `load_mime_types`: Loaded mime types for filename extensions.

  Rationale for removal: "new" calls this, and it always bailed out early if it
  was called again, so it never did nothing useful for users of this module.

* `class_a`: Returned the Class A of the `remote_host`.
* `class_b`: Returned the Class B of the `remote_host`.
* `class_c`: Returned the Class C of the `remote_host`.

  Rationale for removal: You're probably better off calling `split` if you want
  any of these, and no one uses classful routing anymore anyway.

* `domain`: Returned the domain of the `remote_host`.
* `tld`: Returned the top level domain of the `remote_host`.

  Rationale for removal: You're probably better off calling `split`, the tests
  for whether or not the host had a TLD were wrong, and these things are never
  going to get simpler.

* `country_name`: Returned the country name.

  Rationale for removal: Removing this removed a dependency upon
  `Locale::Country`, these kinds of GeoIP databases are usually wrong unless
  you're paying for the data, and anyway, you're better off using your favorite
  GeoIP module anyway.

* `unescape_object`: Returned the unescaped object string.
* `escape_object`: Returned the escaped object string.

  Rationale for removal: Removing this removed a dependency upon `URI::Encode`
  and it didn't always do the right thing anyway.  If you need the objects
  decoded, you're better off in control of the decoding yourself.

# Exported Names

None.

# Prerequisites

Perl 5.10 or higher.  You almost certainly already have it.

# See Also

<http://www.apache.org/>

<https://en.wikipedia.org/wiki/Common_Log_Format>

# Authors

- David Tiberio, `<dtiberio5@hotmail.com>` through version 1.30.
- Ben Stern, `<bas-github@fortian.com>` starting with version 2.00.

Copyright and License

Copyright 2004 David Tiberio, dtiberio5@hotmail.com

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Copyright 2018 Ben Stern

Since version 2.0.0, "the same terms as Perl itself" means the GPL, version 2,
since that's how Perl is licensed (as of the writing of this documentation), so
this is licensed under the terms of the GNU Public License, version 2. You
should have received a file named "LICENSE" with this module. If you did not,
you can find one at `<https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>`
(or by writing to 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA).
