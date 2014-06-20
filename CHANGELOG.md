
1.1.0 / 2014-06-20
==================

 * added back ‘destroy’ method

1.0.0 / 2014-06-19
==================

 * ctor: allow ‘new’ keyword or not
 * changed event ‘not_ready’ to ‘target-not-ready’ for clarity
 * changed ‘reject’ event to ‘source-reject’
 * removed concept of a ‘model’ event-emitter. AutoMerger now extends EE
 * converted CS class to prototype
 * removed unused ‘destroy’ function
 * replaced underscore dep with deep-equal
 * readyProperties: simplified default/existence
 * removed ‘parallel’ property
 * removed redis dependency from api
 * removed fakeredis dev dep
 * fix: not_ready property length check
 * fix: reject on unchanged target
 * fix: set updatedAt after cloning prevTarget to curTarget
 * test: many new tests
 * readme: overhaul for new api
 * moved readyProperties from model to automerger
 * deleted bin/ dir
 * now using subscriberStreams[] in place of redis connection

0.6.0 / 2014-04-14
==================

 * added optional `migrator` function that will be run on all loaded target documents if defined
 * style: fix quotes + whitespace

0.5.1 / 2014-04-09
==================

  - fix for 'keyed_count' strategy
  - split tests up into separate files

0.5.0 / 2014-01-14
==================

  - release worker before publishing to subscribers

0.4.0 / 2013-12-24
==================

  - added instance method #destroy()
    - destroys streams & quits redis conn
    - test
  - wrote test with the minimum possible config to get output
  - readme: added usage example based on mvp test

0.3.0 / 2013-12-13
==================

  - use '!' to delimit key fragments instead of '_'

0.2.3 / 2013-10-08
==================

  - changed updated and created ts var names

0.2.2 / 2013-10-08
==================

  - still need underscore dep for strategies. added

0.2.1 / 2013-10-01
==================

  - fixed a test that wasn't running

0.2.0 / 2013-10-01
==================

  - removed underscore dep
  - fixed module to use via 'require'

0.1.1 / 2013-09-30
==================

  - changed project name "auto-merger" -> "automerger"
  - added contributors, repo

0.1.0 / 2013-09-30
==================

  - initial commit
