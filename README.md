
# probatio

<!-- [![tests](https://github.com/floraison/fugit/workflows/test/badge.svg)](https://github.com/floraison/fugit/actions) -->
[![Gem Version](https://badge.fury.io/rb/probatio.svg)](https://badge.fury.io/rb/probatio)

Test tools for floraison and flor. Somewhere between Minitest and Rspec, but not as excellent.


## Goals

* `bundle exec proba test/there/`
* `bundle exec proba test/there/that.rb`
* `bundle exec proba test/there/that.rb:123`
* `bundle exec proba test/there/that.rb:123:210`
* `bundle exec proba test/there/that.rb:123-210`
* `bundle exec proba test/there/ -n /_for_rm\$/`
* `bundle exec proba test/there/ -n "that test"`
* `bundle exec proba first`
* `bundle exec proba last -2`
* `bundle exec proba 0 1`
* `bundle exec proba -1 -2`
* dots
* colors
* times monow


## Usage

```
  Usage: bundle exec proba [OPTIONS] [FILES] [DIRS]

  A test runner for Ruby.

  Options:
    -h, --help             Show this help message and quit
    --version              Show proba's version and exit
    -m, --monochrome       Disable colour output
    -y, --dry              Don't run the test, just flag them as successes
    -n, --name PATTERN     include tests matching /regexp/ or string in run
    -e, --exclude PATTERN  Exclude /regexp/ or string from run
    -d, --debug            Sets $DEBUG to true

  Files:
    TODO

  Dirs:
    TODO

  Examples:
    # Run all tests in a dir
    bundle exec proba test/

    # Run all the tests in a file
    bundle exec proba test/this_test.rb
```

## .test-point

TODO

## Warnings

```
$ RUBYOPT="-w $RUBYOPT" bundle exec proba
```

## Plugins

TODO


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

