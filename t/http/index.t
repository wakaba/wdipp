use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child ('t_deps/lib');
use Tests;

Test {
  my $current = shift;
  return $current->client->request (path => [])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 404;
      ok $res->header ('strict-transport-security');
    } $current->c;
  });
} n => 2, name => '/ GET';

Test {
  my $current = shift;
  return $current->client->request (path => ['robots.txt'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->header ('x-rev'), $current->app_rev;
      ok $res->header ('x-rev');
      is $res->body_bytes, q{};
    } $current->c;
  });
} n => 4, name => '/robots.txt';

Test {
  my $current = shift;
  return $current->client->request (path => ['-', 'health', 'all'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 200;
      is $res->body_bytes, q{};
    } $current->c;
  });
} n => 2, name => '/-/health/all';

Test {
  my $current = shift;
  return $current->client->request (path => ['favicon.ico'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 204;
    } $current->c;
  });
} n => 1, name => '/favicon.ico';

Test {
  my $current = shift;
  return $current->client->request (path => ['hoge.fuga'])->then (sub {
    my $res = $_[0];
    test {
      is $res->status, 404;
    } $current->c;
  });
} n => 1, name => '/hoge.fuga';

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
