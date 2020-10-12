#!perl
use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->child ('t_deps/lib');
use lib glob path (__FILE__)->parent->parent->child ('t_deps/modules/*/lib');

BEGIN {
  $ENV{WEBUA_DEBUG} //= 0;
  $ENV{WEBSERVER_DEBUG} //= 0;
  $ENV{PROMISED_COMMAND_DEBUG} //= 0;
}

use Web::Host;

use WDIPPSS;

my $RootPath = path (__FILE__)->parent->parent->absolute;
my $LocalPath = $RootPath->child ('local/local-server');

my $config_path = $RootPath->child ('config/local.json');
{
  my $local_config_path = $RootPath->child ('local/local-keys.json');
  if ($local_config_path->is_file) {
    $config_path = $local_config_path;
  }
}
my $processors_path = $LocalPath->child ('processors');

WDIPPSS->run (
  data_root_path => $LocalPath,
  app_host => Web::Host->parse_string ('0'),
  app_port => 12521,
  app_config_path => $config_path,
  processors_path => $processors_path,
)->then (sub {
  my $v = $_[0];
  warn sprintf "\n\nURL: <%s>\n\n",
      $v->{data}->{app_local_url}->stringify;
  
  return $v->{done};
})->to_cv->recv;

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
