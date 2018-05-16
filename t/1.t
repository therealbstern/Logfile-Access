# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 49;
BEGIN { use_ok('Logfile::Access') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


my $log = new Logfile::Access;

ok ($log->parse(q{a1as20-p218.due.tli.de logname user [31/Mar/2001:23:14:46 +0200] "GET /g0010025.htm HTTP/1.0" 304 6543 "http://www.referer.de/persons.htm" "Mozilla/4.7 [de]C-CCK-MCD CSO 1.0  (Win98; U)"}), "parse()");

is ($log->remote_host(), "a1as20-p218.due.tli.de", "remote_host()");

is ($log->logname(), "logname", "logname()");
is ($log->user(), "user", "user()");

is ($log->date(), "31/Mar/2001", "date()");
is ($log->mday(), "31", "mday()");
is ($log->month(), "Mar", "month()");
is ($log->year(), "2001", "year()");
is ($log->time(), "23:14:46", "time()");
is ($log->hour(), "23", "hour()");
is ($log->minute(), "14", "minute()");
is ($log->second(), "46", "second()");
is ($log->offset(), "+0200", "offset()");

is ($log->method(), "GET", "method()");
is ($log->scheme(), undef, "scheme()");
is ($log->query_string(), undef, "query_string()");
is ($log->path(), "", "path()");
is ($log->mime_type(), "text/html", "mime_type()");
is ($log->object(), "/g0010025.htm", "object()");
is ($log->protocol(), "HTTP/1.0", "protocol()");

is ($log->response_code(), "304", "response_code()");
is ($log->content_length(), "6543", "content_length()");
is ($log->http_referer(), "http://www.referer.de/persons.htm", "http_referer()");
is ($log->http_user_agent(), "Mozilla/4.7 [de]C-CCK-MCD CSO 1.0  (Win98; U)", "http_user_agent()");

ok ($log->parse(q{66.202.26.100 test1 test2 [21/Jan/2002:12:22:33 -0400] "PUT /path/g0010025.jpg?key=banana HTTP/1.1" 200 16543 "http://www.referer.de/" "Mozilla/4.7"}), "parse()");

is ($log->remote_host(), "66.202.26.100", "remote_host()");

is ($log->logname(), "test1", "logname()");
is ($log->user(), "test2", "user()");

is ($log->date(), "21/Jan/2002", "date()");
is ($log->mday(), "21", "mday()");
is ($log->month(), "Jan", "month()");
is ($log->year(), "2002", "year()");
is ($log->time(), "12:22:33", "time()");
is ($log->hour(), "12", "hour()");
is ($log->minute(), "22", "minute()");
is ($log->second(), "33", "second()");
is ($log->offset(), "-0400", "offset()");

is ($log->method(), "PUT", "method()");
is ($log->scheme(), undef, "scheme()");
is ($log->query_string(), "key=banana", "query_string()");
is ($log->path(), "/path", "path()");
is ($log->mime_type(), "image/jpeg", "mime_type()");
is ($log->object(), "/path/g0010025.jpg?key=banana", "object()");
is ($log->protocol(), "HTTP/1.1", "protocol()");

is ($log->response_code(), "200", "response_code()");
is ($log->content_length(), "16543", "content_length()");
is ($log->http_referer(), "http://www.referer.de/", "http_referer()");
is ($log->http_user_agent(), "Mozilla/4.7", "http_user_agent()");
#is ($log->parse(q{66.202.26.100 test1 test2 [21/Jan/2002:12:22:33 -0400] "PUT /path/g0010025.jpg?key=banana HTTP/1.1" 200 16543 "http://www.referer.de/" "Mozilla/4.7"}), "parse()");
