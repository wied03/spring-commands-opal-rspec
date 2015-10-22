# spring-commands-opal-rspec

[![Build Status](http://img.shields.io/travis/wied03/spring-commands-opal-rspec/master.svg?style=flat)](http://travis-ci.org/wied03/spring-commands-opal-rspec)

Adds spring support to opal-rspec

## Usage

Add to your Gemfile:

```ruby
gem 'spring-commands-opal-rspec', group: :development
```

If you're using spring binstubs, run `bundle exec spring binstub opal-rspec` to generate `bin/opal-rspec`. Then run `bin/opal-rspec`. It will use the configured spec info from your opal-rails setup.

SPEC_OPTS can also be supplied (see opal-rspec docs). Any changes will not take effect until `spring stop` is issued. Example:

```ruby
SPEC_OPTS="--format j" spring opal-rspec
```

## Limitations/Quirks:

This command does a little more than the average Spring command because it starts a separate Rack server (from Rails) to serve up the opal specs. The rack server will be stopped/managed by `spring stop` but it will not show up in `spring status`. Here are samples:

```
bin/spring status

Spring is running:

 2622 spring server | test_app | started 19 secs ago                             
 2626 spring app    | test_app | started 19 secs ago | test mode
```

```
ps ux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root        13  0.0  0.1  20276  3228 ?        S    04:12   0:00 bash
root      2622  0.5  1.7 326968 36900 ?        Sl   05:21   0:00 spring server | test_app | started 2 mins ago                              
root      2626  4.5  3.8 391692 78336 ?        Ssl  05:21   0:06 spring app    | test_app | started 2 mins ago | test mode                           
root      2633  6.9  8.6 462860 176672 ?       Sl   05:21   0:09 spring app    | test_app | started 2 mins ago | opal-rspec mode                       
root      2656  0.0  0.1  17492  2084 ?        R+   05:23   0:00 ps ux
```

## Contributing

Install required gems at required versions:

    $ bundle install

A simple rake task should run the example specs in `spec/`:

    $ bundle exec rake

## License

Authors: Brady Wied

Copyright (c) 2015, BSW Technology Consulting LLC
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
