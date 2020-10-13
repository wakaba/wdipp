package Tests;
use strict;
use warnings;
use Path::Tiny;
use lib glob path (__FILE__)->parent->parent->parent->child
    ('t_deps/modules/*/lib');
use AbortController;
use Test::More;
use Test::X1;
use JSON::PS;
use Time::HiRes qw(time);
use Promise;
use Promised::Flow;
use Exporter::Lite;
use Digest::SHA qw(hmac_sha1);
use Web::Transport::Base64;
use Web::Encoding;
use Web::URL;
use Web::URL::Encoding;

use WDIPPSS;
use CurrentTest;

our @EXPORT = grep { not /^\$/ }
    @Test::More::EXPORT,
    @Test::X1::EXPORT,
    @Promised::Flow::EXPORT,
    @JSON::PS::EXPORT,
    @Web::Encoding::EXPORT,
    @Web::URL::Encoding::EXPORT,
    'time';

my $RootPath = path (__FILE__)->parent->parent->parent;
my $TestScriptPath = path ($0)->relative ($RootPath->child ('t'));

push @EXPORT, qw(signature);
sub signature ($$) {
  return encode_web_base64 hmac_sha1
      (encode_web_utf8 ($_[0]), encode_web_utf8 ($_[1]));
} # signed

our $ServerData;
my $NeedBrowser;
push @EXPORT, qw(Test);
sub Test (&;%) {
  my $code = shift;
  my %args = @_;
  $NeedBrowser = 1 if delete $args{browser};
  $args{timeout} //= 120;
  test {
    my $current = CurrentTest->new ({
      context => shift,
      server_data => $ServerData,
      test_script_path => $TestScriptPath,
    });
    Promise->resolve ($current)->then ($code)->catch (sub {
      my $error = $_[0];
      test {
        ok 0, "promise resolved";
        is $error, undef, "no exception";
      } $current->c;
    })->then (sub {
      return $current->done;
    });
  } %args;
} # Test

push @EXPORT, qw(RUN);
sub RUN () {
  note "Servers...";
  my $ac = AbortController->new;
  my $v = WDIPPSS->run (
    signal => $ac->signal,
    app_config_path => $RootPath->child ('config/test.json'),
    processors_path => $RootPath->child ('t_deps/processors'),
    need_browser => $NeedBrowser,
    browser_type => $ENV{TEST_WD_BROWSER}, # or undef
  )->to_cv->recv;

  note "Tests...";
  local $ServerData = $v->{data};
  run_tests;

  note "Done";
  $ac->abort;
  $v->{done}->to_cv->recv;
} # RUN

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
