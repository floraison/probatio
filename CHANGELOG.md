
# CHANGELOG.md


## probatio 1.6.0 not yet released

* Let `proba` accept leaf globs directly


## probatio 1.5.0 released 2026-01-28

* Introduce `assert_not_match`
* Introduce `time do; end` helper
* Alias `assert_class` to `assert_instance_of`


## probatio 1.4.2 released 2025-11-26

* Allow pointing at a group with a line number between tests


## probatio 1.4.1 released 2025-11-16

* Fixed assert_error versus no errors


## probatio 1.4.0 released 2025-10-13

* Work on StringDiff, HashDiff, and ArrayDiff
* Use diff-lcs for StringDiff


## probatio 1.3.0 released 2025-08-08

* Add windows? and jruby? to Probatio::Group
* Alias `assert_nothing_raised` to `assert_no_error`


## probatio 1.2.1 released 2025-05-20

* Tighten Probatio.beep and friends


## probatio 1.2.0 released 2025-05-19

* Introduce Probatio::Context#beep
* Introduce --beeps {n || 1}
* Allow for list.rb as 'list'


## probatio 1.1.1 released 2025-05-08

* Fix .probatio-output.rb string/number alignment
* Fix assert_error and assert_no_error


## probatio 1.1.0 released 2025-04-16

* Introduce `assert_no_error { do_this_or_that() }`


## probatio 1.0.0 released 2025-02-08

* Initial release


## probatio 0.9.0 released 2024-12-19

* Initial bogus release ;-)

