package CurrentTest;
use strict;
use warnings;
use Path::Tiny;
use Promise;
use Promised::Flow;
use Promised::File;
use JSON::PS;
use Web::Encoding;
use Web::URL;
use Web::URL::Encoding;
use Web::Transport::BasicClient;
use ServerSet::ReverseProxyProxyManager;
use Test::More;
use Test::X1;

sub new ($$) {
  return bless $_[1], $_[0];
} # new

sub c ($) {
  return $_[0]->{context};
} # c

sub client ($;$) {
  my ($self, $key) = @_;
  return $self->client_for ($self->{server_data}->{app_client_url}, $key);
} # client

sub client_for ($$;$) {
  my ($self, $url, $key) = @_;
  $self->{clients}->{$url->get_origin->to_ascii, $key // ''} ||= Web::Transport::BasicClient->new_from_url ($url, {
    proxy_manager => ServerSet::ReverseProxyProxyManager->new_from_envs ($self->{server_data}->{local_envs}),
  });
} # client_for

sub app_rev ($) {
  return $_[0]->{server_data}->{app_rev};
} # app_rev

sub resolve ($$) {
  my $self = shift;
  return Web::URL->parse_string (shift, $self->{server_data}->{app_client_url});
} # resolve

sub save_artifact ($$$$) {
  my ($self, $data, $name, $ext) = @_;
  $name = [
    $self->{test_script_path},
    $self->c->test_name,
    map { ref $_ eq 'ARRAY' ? @$_ : $_ } @$name,
  ];
  $name = join '-', map {
    my $v = $_ // '';
    $v =~ s/[^A-Za-z0-9_]/_/g;
    $v;
  } @$name;
  my $path = $self->{server_data}->{artifacts_path}->child ($name . '.' . $ext);
  warn "Save artifact file |$path|...\n";
  my $file = Promised::File->new_from_path ($path);
  return $file->write_byte_string ($data);
} # save_artifact

sub done ($) {
  my $self = $_[0];
  delete $self->{client};
  return Promise->all ([
    (map { $_->close } values %{delete $self->{client_for} or {}}),
    (map { $_->close } values %{delete $self->{browsers} or {}}),
  ])->then (sub {
    return Promise->all ([
      (map { $_->close } @{delete $self->{wds} or []}),
    ]);
  })->finally (sub {
    (delete $self->{context})->done;
  });
} # done

1;

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
