# -*- Perl -*-
use strict;
use warnings;
use Path::Tiny;
use Promise;
use Promised::Flow;
use JSON::PS;
use Wanage::HTTP;
use Warabe::App;

use WorkerState;

my $config_path = path ($ENV{CONFIG_FILE} // die "No |CONFIG_FILE|");
my $Config = json_bytes2perl $config_path->slurp;

$Config->{git_sha} = path (__FILE__)->parent->parent->child ('rev')->slurp;
$Config->{git_sha} =~ s/[\x0D\x0A]//g;

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  my $app = Warabe::App->new_from_http ($http);
  $app->execute_by_promise (sub {
    warn sprintf "ACCESS: [%s] %s %s FROM %s %s\n",
        scalar gmtime,
        $app->http->request_method, $app->http->url->stringify,
        $app->http->client_ip_addr->as_text,
        $app->http->get_request_header ('User-Agent') // '';

    $app->http->set_response_header
        ('Strict-Transport-Security',
         'max-age=10886400; includeSubDomains; preload')
        unless $Config->{is_live};

    my $path = $app->path_segments;

    if ($path->[0] eq 'robots.txt') {
      $app->http->set_response_header ('X-Rev' => $Config->{git_sha});
      $app->http->set_response_last_modified (1556636400);
      if ($Config->{is_live} or
          $Config->{is_test_script} or
          $app->bare_param ('is_live')) {
        return $app->send_plain_text ("");
      } else {
        return $app->send_plain_text ("User-agent: *\x0ADisallow: /\x0A");
      }
    }
    
    if ($path->[0] eq 'favicon.ico') {
      return $app->throw_error (204);
    }

    return Promise->resolve->then (sub {
      return $app->send_error (404, reason_phrase => 'Page not found');
    })->catch (sub {
      return if UNIVERSAL::isa ($_[0], 'Warabe::App::Done');
      if (ref $_[0] eq 'HASH') {
        warn "ERROR: ".(perl2json_bytes_for_record $_[0])."\n";
      } else {
        warn "ERROR: $_[0]\n";
      }
      return $app->send_error (500);
    });
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

You should have received a copy of the GNU Affero General Public
License along with this program.  If not, see
<https://www.gnu.org/licenses/>.

=cut
