use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->client->request (path => ['notfounderror'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 404;
      is $res->body_bytes, '404';
    } $current->c;
  });
} n => 2, name => 'No processor';

Test {
  my $current = shift;
  return $current->client->request (path => ['processornotfound'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 500;
      is $res->header ('content-type'), 'text/plain; charset=us-ascii';
      is $res->body_bytes, "500 Bad process";
    } $current->c;
  });
} n => 3, name => 'File not found';

Test {
  my $current = shift;
  return $current->client->request (path => ['processorthrows'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 500;
      is $res->header ('content-type'), 'text/plain; charset=us-ascii';
      is $res->body_bytes, "500 Failed";
    } $current->c;
  });
} n => 3, name => 'throws';

Test {
  my $current = shift;
  return $current->client->request (path => ['processorrejects'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 500;
      is $res->header ('content-type'), 'text/plain; charset=us-ascii';
      is $res->body_bytes, "500 Failed";
    } $current->c;
  });
} n => 3, name => 'rejects';

Test {
  my $current = shift;
  return $current->client->request (path => ['badresult'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 500;
      is $res->header ('content-type'), 'text/plain; charset=us-ascii';
      is $res->body_bytes, "500 Bad result";
    } $current->c;
  });
} n => 3, name => 'Bad result';

Test {
  my $current = shift;
  return $current->client->request (path => ['processorresolves'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 403;
      is $res->header ('content-type'), 'text/plain; charset=utf-8';
      is $res->body_bytes, "Response あいうえお";
    } $current->c;
  });
} n => 3, name => 'resolves';

Test {
  my $current = shift;
  return $current->client->request (path => ['test1'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 400;
      is $res->header ('content-type'), 'text/plain; charset=utf-8';
      is $res->body_bytes, "Default response あいうえお";
    } $current->c;
  });
} n => 3, name => 'test1';

RUN;

=head1 LICENSE

Copyright 2016-2020 Wakaba <wakaba@suikawiki.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Affero General Public License for more details.

You does not have received a copy of the GNU Affero General Public
License along with this program, see <https://www.gnu.org/licenses/>.

=cut
