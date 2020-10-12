package WorkerState;
use strict;
use warnings;
use Path::Tiny;
use JSON::PS;
use Promise;
use Promised::Flow;
use Web::Driver::Client::Connection;

my $config_path = path ($ENV{CONFIG_FILE} // die "No |CONFIG_FILE|");
my $Config = json_bytes2perl $config_path->slurp;

$Config->{git_sha} = path (__FILE__)->parent->parent->child ('rev')->slurp;
$Config->{git_sha} =~ s/[\x0D\x0A]//g;

sub start ($%) {
  my ($class, %args) = @_;
  my ($r, $s) = promised_cv;
  my $obj = {clients => {}, config => $Config};
  $args{signal}->manakai_onabort (sub {
    return Promise->all ([
      (map { $_->close } values %{$obj->{clients}}),
    ])->finally ($s);
  });
  return [$obj, $r];
} # start

1;

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
