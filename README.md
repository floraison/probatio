
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
Usage: bundle exec proba [OPTIONS] [DIRS] [FILES] [OTHERS] [ENVS]

  A test runner for Ruby.

  Options:
    -h, --help             Show this help message and quit
    --version              Show proba's version and exit
    -c, --color            Enable colour output anyway
    -C, --no-color         Disable colour output
    -y, --dry              Don't run the tests, just flag them as successes
    -n, --name PATTERN     include tests matching /regexp/ or string in run
    -e, --exclude PATTERN  Exclude /regexp/ or string from run
    -p, --print            Dumps the test tree
    -m, --map              Dumps the test file map
    -s, --seed             Sets random seed
    -d, --debug            Sets $DEBUG to true
    -x, --example          Outputs an example test file
    -X, --plugin-example   Outputs an example plugin file
    --mangle               Turns the given _spec.rb files into proba _test.rb

  Dirs:
    Defaults to test/ if no files nor dir are given.
    Probatio will look at all the *_helper[s].rb, *_test[s].rb files
    under the given dirs and also at the setup.rb, *_setup.rb files

  Files:
    List of test files to scan for tests.
    A file may end with `:123` to indicate that the test at line 123 should
    be run. Multiple "colon-lnumber" suffixes may be specified, as in
    `test/fun/that_test.rb:123:456`

  Others:
    Short codes like
    * `bundle exec proba -1`
    * `bundle exec proba last` run the last failing test of the last run
    * `bundle exec proba first`
    * `bundle exec proba 1st`
    * `bundle exec proba 0` run the first failing test of the last run

  Envs:
    Short FULLCAPS environment variable setters driven by a
    `.probatio-environments.rb` file in the current work directory.

    ```
    # .probatio-environments.rb
    {
      D: { 'FLOR_DEBUG' => 'dbg,stdout' },
      DD: { 'FLOR_DEBUG' => 'dbg,sto,stdout' },
    }
    ```

  Examples:
    # Run all tests in a dir
    bundle exec proba test/

    # Run all the tests in a file
    bundle exec proba test/this_test.rb
```

## Test files

By default probatio looks into `test/` for test files ending in `_test.rb` or `_tests.rb` but first look at helpers ending in `_helper.rb` or `_helpers.rb`.

A typical test hierarchy:
```
test/
|-- helpers/
|   |-- some_helpers.rb
|   `-- some_other_helpers.rb
|-- this_test.rb
|-- that_test.rb
`-- more_tests.rb
```

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

      assert_true true
      assert_false 1 > 2

      assert_truthy "yes", "no"
      assert_trueish "yes", "no"
      assert_falsy nil, false
      assert_falsey nil, false
      assert_falseish nil, false

      assert_equal 'one', 'o' + 'ne'
        # checks that all its arguments are equal

      assert_match 'one', /^one$/
        # checks that it receives a regex and one or more strings
        # and that all those strings match the regex

      assert_start_with 'one', 'one two or three'
        # checks that the shortest string is the start of the remaining string
        # arguments
      assert_end_with 'three', 'one two or three'
        # checks that the shortest string is the end of the remaining string
        # arguments

      assert_include 1, [ 1, 'two' ]
        # checks that the first array argument includes all other arguments

      assert_error(ArgumentError) { do_this_or_that() }
        # checks that the given block raises an ArgumentError
      assert_error(ArgumentError, /bad/) { do_this_or_that() }
        # checks that the given block raises an ArgumentError and
        # the error message matches the /bad/ regexp
      assert_error lambda { do_this_or_that() }, ArgumentError
        # checks that the given Proc raises an ArgumentError
      assert_error lambda { do_this_or_that() }, ArgumentError, 'bad'
        # checks that the given Proc raises an ArgumentError and
        # the error message == "bad"

      assert_hashy(
        this_thing => 1,
        that_thing => 'two')
          # combines two assert_equals in one

      assert_instance_of 1, Integer
      assert_is_a Integer, 123
        # checks that value or set of values are of a given of class

      assert 1, 1
        # behaves like assert_equal
      assert 'one', /one/i
        # behaves like assert_match
      assert 'one', [ 'one', 'two' ]
        # behaves like assert_include
      assert 11 => '10'.to_i + 1
        # assert equality between key and value
      assert 'one' => 'on' + 'e', 'two' => :two.to_s
        # assert equality between keys and values
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

group 'core', 'sub-core', 'sub-sub-core' do
  #
  # it's OK to specifiy a path of group names

  test 'this' do
  end
end

group 'core < sub-core < sub-sub-core' do
  #
  # this is also ok...

  test 'that' do
  end
end
```


## .test-point

By running `bx proba .`, one tells probatio to run the test pointed at in the file `.test-point`.

Here is an example of `.test-point` content:
```
test/wma/dwm/onboarding_benchmark_non_star_test.rb:189
```

For Vim users, here is a snippet that saves the current path and line number to `.test-point` every 700ms:
```vim
au BufEnter test/*_test.rb,test/**/*_test.rb :set updatetime=700

au BufEnter,CursorHold,BufWrite test/*_test.rb,test/**/*_test.rb :call writefile([ expand('%') . ':' . line('.') ], '.test-point', 'b')
```


## .probatio-output.rb

By default, probatio summarizes a run in a `.probatio-output.rb` file.

Here is an example of such a file:
```ruby
# .probatio-output.rb
{
argv: [ "test/alpha_test.rb:23" ],
failures:
  [
  { n: "test_fail", p: "test/alpha_test.rb", l: 24, t: "0s000_077" },
  { n: "test_fail", p: "test/alpha_test.rb", l: 29, t: "0s000_033" },
  ],
duration: "0s001_297",
probatio: { v: "1.0.0" },
ruby:
  {
  p: "/usr/local/bin/ruby33",
  d: "ruby 3.3.5 (2024-09-03 revision ef084cc8f4) [x86_64-openbsd]",
  l: 100,
  },
some_env:
  {
  USER: "jmettraux",
  HOME: "/home/jmettraux",
  PATH: "/home/jmettraux/.gem/ruby/3.3/bin:/home/jmettraux/.pkg_rubies/ruby33:/usr/local/jdk-21/bin:/home/jmettraux/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/X11R6/bin:/usr/local/bin:/usr/local/sbin",
  SHELL: "/usr/local/bin/fish",
  GEM_HOME: "/home/jmettraux/.gem/ruby/3.3",
  PWD: "/home/jmettraux/w/probatio/test",
  },
}
```

Probatio uses it when servicing `bundle exec proba 0` or `bundle exe proba -1`.

It can also be useful to other tools around probatio.


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

