# -*- Perl -*-
use strict;
use warnings;
use Path::Tiny;
use Time::HiRes qw(time);
use Promise;
use Promised::Flow;
use Promised::File;
use JSON::PS;
use Digest::SHA qw(hmac_sha1);
use Web::Transport::Base64;
use Web::Encoding;
use Web::URL;
use Wanage::HTTP;
use Warabe::App;

use WorkerState;

sub run_processor ($$) {
  my ($app, $name) = @_;
  my $config = $app->http->server_state->data->{config};
  my $def = $config->{processors}->{$name};
  unless (defined $def) {
    return $app->throw_error (404, reason_phrase => 'No processor');
  }

  my $arg = $app->text_param ('arg') // '';
  if (defined $def->{key}) {
    my $sig_got = $app->bare_param ('signature') // '';
    my $sig_expected = encode_web_base64 hmac_sha1
        (encode_web_utf8 ($arg), encode_web_utf8 ($def->{key}));
    return $app->throw_error (400, reason_phrase => 'Bad |signature|')
        unless $sig_got eq $sig_expected;
  }
  
  my $js_path = path ($config->{processors_dir})->child ($name . '.js');
  my $js_file = Promised::File->new_from_path ($js_path);

  my $wd = Web::Driver::Client::Connection->new_from_url
      (Web::URL->parse_string ($config->{wd_url}));
  my $session;
  
  my $timeout = $def->{timeout} || 60;
  return Promise->resolve->then (sub {
    return promised_timeout {

  return $wd->new_session (
    desired => {},
    #http_proxy_url
  )->then (sub {
    $session = $_[0];
    
    return $js_file->read_char_string->then (sub {
      return $session->execute (q{
        return new Function (arguments[0]).apply (null, arguments[1]);
      }, [$_[0], [$arg]])->then (sub {
        my $res = $_[0];
        my $value = $res->json->{value};
        unless (defined $value and
                ref $value eq 'HASH' and
                defined $value->{content} and
                ref $value->{content} eq 'HASH') {
          warn "Bad JavaScript response: " . perl2json_bytes $value;
          return $app->throw_error (500, reason_phrase => 'Bad result');
        }
        my $headers = sub {
          $app->http->set_status ($value->{statusCode}) if defined $value->{statusCode};
          if (defined $value->{httpCache} and
              ref $value->{httpCache} eq 'HASH' and
              defined $value->{httpCache}->{maxAge}) {
            $app->http->add_response_header
                ('cache-control', sprintf 'public,max-age=%d', $value->{httpCache}->{maxAge});
          }
        }; # $headers
        if (($value->{content}->{type} // '') eq 'screenshot') {
          return $session->screenshot (selector => $value->{content}->{targetElement})->then (sub {
            $app->http->set_response_header ('content-type', 'image/png');
            $headers->();
            $app->http->send_response_body_as_ref (\($_[0]));
            return $app->http->close_response_body;
          }, sub {
            my $res = $_[0];
            warn "Processor error: (screenshot) $_[0]";
            return $app->throw_error (500, reason_phrase => 'Failed');
          });
        } else {
          $headers->();
          return $app->send_plain_text ($value->{content}->{value} // '');
        }
      }, sub {
        my $res = $_[0];
        warn "Processor error: $_[0]";
        return $app->throw_error (500, reason_phrase => 'Failed');
      });
    }, sub {
      warn "Processor error: $_[0]";
      return $app->throw_error (500, reason_phrase => 'Bad process');
    });
    });
    } $timeout;
  })->catch (sub {
    my $e = $_[0];
    if (UNIVERSAL::isa ($e, 'Promise::AbortError')) {
      return $app->throw_error (504, reason_phrase => 'Process timeout ('.$timeout.')');
    }
    die $e;
  })->finally (sub {
    return $session->close if defined $session;
  })->finally (sub {
    return $wd->close;
  });
} # run_processor

return sub {
  my $http = Wanage::HTTP->new_from_psgi_env ($_[0]);
  my $app = Warabe::App->new_from_http ($http);
  $app->execute_by_promise (sub {
    my $config = $app->http->server_state->data->{config};
    $app->http->set_response_header
        ('Strict-Transport-Security',
         'max-age=10886400; includeSubDomains; preload')
        if $config->{is_live} or $config->{is_test_script};

    my $path = $app->path_segments;

    if (@$path == 1 and $path->[0] eq 'robots.txt') {
      $app->http->set_response_header ('X-Rev' => $config->{git_sha});
      $app->http->set_response_last_modified (1556636400);
      if ($config->{is_live} or
          $config->{is_test_script} or
          $app->bare_param ('is_live')) {
        return $app->send_plain_text ("");
      } else {
        return $app->send_plain_text ("User-agent: *\x0ADisallow: /\x0A");
      }
    }
    
    if (@$path == 1 and $path->[0] eq 'favicon.ico') {
      return $app->throw_error (204);
    }

    return Promise->resolve->then (sub {
      my $origin = $app->http->get_request_header ('origin');
      if (defined $origin) {
        if ($config->{_cors_allowed}->{$origin}) {
          $app->http->set_response_header ('access-control-allow-origin', $origin);
        }
      }
      
      if (@$path == 1 and $path->[0] =~ /\A[0-9A-Za-z_]+\z/) {
        return run_processor ($app, $path->[0]);
      }

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
