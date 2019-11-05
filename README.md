# Solidity Bootstrap Project

## How to use it

* Fork this repo
* Remove `.git` folder and initialize a new github repo with `git init` to drop off this repo history
* Update descriptions in files like `README.md` and `package.json`

## Commands

* `make cleanup` - remove solidity build artifacts
* `make compile` - compile solidity files, executes `make cleanup` before compilation
* `make test` - run tests
* `make coverage` - run solidity coverage
* `make lint` - run solidity and javascript linters
* `make deploy` - run deployment scripts
* `make ganache` - run local pre-configured ganache

For more information check out `Makefile`

## Tests

Includes test runner configuration for the following CI services:

* GitHub Actions
* GitLab CI
* Travis CI

