#!/usr/bin/perl
use strict;
use warnings;
use Wanage::HTTP;
use Warabe::App;
use JSON::PS;
use Web::URL::Encoding;

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env (shift);
  my $app = Warabe::App->new_from_http ($http);
  $app->execute_by_promise (sub {
    my $path = $app->http->url->{path};

    if ($path eq '/abcde') {
      return $app->send_plain_text (q{abcde});
    }
    
    return $app->send_error (404);
  });
};

=head1 LICENSE

Copyright 2020 Wakaba <wakaba@suikawiki.org>.

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
