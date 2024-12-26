
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

TODO

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

