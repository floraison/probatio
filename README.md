
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
    -c, --color            Enable colour output anyway
    -y, --dry              Don't run the test, just flag them as successes
    -n, --name PATTERN     include tests matching /regexp/ or string in run
    -e, --exclude PATTERN  Exclude /regexp/ or string from run
    -p, --print            Dumps the test tree
    -s, --seed             Sets random seed
    -d, --debug            Sets $DEBUG to true
    -x, --example          Outputs an example test file
    -X, --plugin-example   Outputs an example plugin file

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

## Test files

```ruby
group 'core' do

  setup do
    # occurs once before tests and sub-groups in group 'core'
  end
  teadowm do
    # occurs once after tests and sub-groups in group 'core'
  end

  group 'alpha' do

    before do
      # is run in the separate test context before _each_ test
    end
    after do
      # is run in the separate test context after _each_ test
    end

    test 'one' do

      MyLib.do_this_or_that()

      assert 'one', 'o' + 'ne'
      assert_match 'one', /^one$/
    end
  end

  group 'bravo' do
  end
end

group 'core' do
  #
  # it's OK to re-open a group to add sub-groups, tests,
  # and setups, teardowns, befores, or afters
  #
  # it's OK to re-open a group in another file, as long
  # as it's the same name at the same point in the name hierarchy

  _test 'not yet' do
    #
    # prefix a test, a group, or other element with _
    # marks it as _pending
  end
end
```

## .test-point

TODO

## Warnings

```
$ RUBYOPT="-w $RUBYOPT" bundle exec proba
```

## Plugins

```ruby
#
# examples of probatio plugins

class MyProbatioPlugin

  def on_test_succeed(ev)

    puts "GREAT SUCCESS! " + ev.to_s
  end
end

Probatio.plug(MyProbatioPlugin.new)
```


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

