PYTHON=python3
.DEFAULT_GOAL := help
SHELL := /bin/bash

.PHONY: help
help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

format: ## Formats the code base and tests using Black.
	black --line-length 100 simple_slack_bot tests

isort: ## Orders the imports of the code base and tests using isort.
	isort --recursive simple_slack_bot tests

lint: ## Performs linting on the code base and tests using flake8 and pydocstyle.
	flake8 simple_slack_bot tests --show-source
	# does not check tests to help me keep my sanity as there's many issues that provide little value resolving
	pylint simple_slack_bot --ignore=tests

type: ## Checks type hints on the code base and tests using mypy.
	mypy simple_slack_bot tests --disallow-untyped-calls

security: ## Checks code base and tests for security vulnerability, bad imports and keys using bandit, safety and dodgy.
	# does not check tests to help me keep my sanity as there's many issues that provide little value resolving
	bandit -r simple_slack_bot
	# ignoring pipenv installed in Circle Ci Docker container
	safety check --full-report --ignore 38334
	dodgy

magic: format isort lint type security ## Performs format, isort, lint, type and security in that order.

test: ## Runs the pytest suite
	pytest

test-and-generate-coverage: ## Runs the pytest suite and generates code coverage.
	coverage run -m pytest && coverage report -m

upload-coverage-to-codecov: ## Uploads the covde coverage to Code Cov IO
	 bash <(curl -s https://codecov.io/bash)

clean-old-packages: ## Cleans up old package artifacts
	python3 setup.py custom_clean

package: ## Packages up the project.
	# cleaning up prior builds before we build another, this stops us from uploading mutliple whl and tarbars in a later step
	python3 setup.py sdist bdist_wheel

upload-test-pypi: ## Uploads the project to test.pypi.org.
	python3 -m twine upload --repository-url https://test.pypi.org/legacy/ dist/*

upload-pypi: ## Uploads the project to pypi.org
	python3 -m twine upload dist/*

create-github-release: ## Creates a Github Release
	python3 setup.py create_github_release

verify-git-tag-matches-version: ## Verifies git tag matches version
	python3 setup.py verify

circle-ci-validate: ## Validates the circleci config.
	circleci config validate

circle-ci-local-execute: ## Execute circleci config locally.
	circleci local execute

deploy: clean-old-packages create-github-release package upload-pypi ## Deploys new version by creating a new Github Tag, Release and uploading to PyPi
