
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
READ ! ruby -Ilib exe/proba --help
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
READ lib/probatio/examples/a_test.rb
```


## .test-point

TODO


## .proba-output.rb

By default, probatio summarizes a run in a `.proba-output.rb` file.

Here is an example of such a file:
```ruby
{
argv: ["-d"],
failures:
  [
  { n: "test_fail", p: "test/bravo_test.rb", l: 12, t: "0s000_607" },
  { n: "test_fail", p: "test/alpha_test.rb", l: 29, t: "0s000_055" },
  { n: "test_fail", p: "test/bravo_test.rb", l: 20, t: "0s000_047" },
  ],
duration: "0s004_949",
}
```

Probatio uses it when servicing `bundle exec proba 0` or `bundle exe proba -1`.


## Warnings

```
$ RUBYOPT="-w $RUBYOPT" bundle exec proba
```


## Plugins

```ruby
READ lib/probatio/examples/a_plugin.rb
```


## LICENSE

MIT, see [LICENSE.txt](LICENSE.txt)

