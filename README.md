# Package::Audit

[![Gem Version](https://img.shields.io/gem/v/package-audit.svg)](https://rubygems.org/gems/package-audit)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Lint Status](https://github.com/vkononov/package-audit/actions/workflows/lint.yml/badge.svg)](https://github.com/vkononov/package-audit/actions/workflows/lint.yml)
[![Test Status](https://github.com/vkononov/package-audit/actions/workflows/test.yml/badge.svg)](https://github.com/vkononov/package-audit/actions/workflows/test.yml)

A useful tool for patch management and prioritization, `package-audit` produces a list of dependencies that are outdated, deprecated or have security vulnerabilities.

`Package::Audit` will automatically detect the technologies used by the project and print out an appropriate report.

## Supported Technologies

* Ruby
* Node (using Yarn)

## Known Issues

1. [RubyGems.org API](https://guides.rubygems.org/rubygems-org-api/) produces an incorrect date for the latest version of the [puma](https://github.com/puma/puma) gem. As a result, `puma` is shown on reports as an outdated and a deprecated gem as a false positive.


## Report Example

Below is an example of running the script on a project that uses both Ruby and Node.

```
===========================================================================================================================
Package                   Version  Latest   Latest Date  Vulnerabilities       Risk    Risk Explanation
===========================================================================================================================
actionpack                7.0.3.1  7.0.4.3  2023-03-13   unknown(2) medium(1)  high    security vulnerability
activerecord              7.0.3.1  7.0.4.3  2023-03-13   high(2)               high    security vulnerability
activesupport             7.0.3.1  7.0.4.3  2023-03-13   unknown(2)            high    security vulnerability
byebug                    11.1.3   11.1.3   2020-04-23                         medium  no updates by author in over 2 years
devise-async              1.0.0    1.0.0    2017-09-20                         medium  no updates by author in over 2 years
foundation-rails          6.6.2.0  6.6.2.0  2020-03-30                         medium  no updates by author in over 2 years
puma                      6.2.1    6.2.2    1980-01-01                         medium  no updates by author in over 2 years
rails-controller-testing  1.0.5    1.0.5    2020-06-23                         medium  no updates by author in over 2 years
rails                     7.0.3.1  7.0.4.3  2023-03-13                         low     not at latest version
rubocop-i18n              3.0.0    3.0.0    2020-12-14                         medium  no updates by author in over 2 years
sass-rails                6.0.0    6.0.0    2019-08-16                         medium  no updates by author in over 2 years
selenium-webdriver        4.8.6    4.9.0    2023-04-21                         low     not at latest version
serviceworker-rails       0.6.0    0.6.0    2019-07-09                         medium  no updates by author in over 2 years
turbolinks                5.2.1    5.2.1    2019-09-18                         medium  no updates by author in over 2 years

3 vulnerable (7 vulnerabilities), 6 outdated, 9 deprecated.
Found a total of 14 Ruby packages.

To get more information about the ruby gem vulnerabilities run:
 > bundle-audit check --update

==========================================================================================================================
Package                   Version  Latest   Latest Date  Vulnerabilities      Risk    Risk Explanation
==========================================================================================================================
@sideway/formula          3.0.0    3.0.1    2022-12-16   moderate(1)          medium  security vulnerability
ansi-regex                4.1.0    6.0.1    2021-09-10   high(5)              high    security vulnerability
async                     2.6.3    3.2.4    2022-06-07   high(2)              high    security vulnerability
babel-eslint              10.1.0   10.1.0   2020-02-26                        medium  no updates by author in over 2 years
decode-uri-component      0.2.0    0.4.1    2022-12-19   high(10)             high    security vulnerability
hermes-engine             0.7.2    0.11.0   2022-01-27   critical(2)          high    security vulnerability
json5                     2.2.0    2.2.3    2022-12-31   high(30)             high    security vulnerability
react-native-safari-view  2.1.0    2.1.0    2017-10-02                        medium  no updates by author in over 2 years
react-native              0.64.2   0.71.7   2023-04-19                        low     not at latest version
react-navigation-stack    2.10.4   2.10.4   2021-03-01                        medium  no updates by author in over 2 years
react-navigation          4.4.4    4.4.4    2021-02-21                        medium  no updates by author in over 2 years
redux-axios-middleware    4.0.1    4.0.1    2019-07-10                        medium  no updates by author in over 2 years
redux-devtools-extension  2.13.9   2.13.9   2021-03-06                        medium  no updates by author in over 2 years
redux-persist             6.0.0    6.0.0    2019-09-02                        medium  no updates by author in over 2 years
shell-quote               1.6.1    1.8.1    2023-04-07   critical(3)          high    security vulnerability
shelljs                   0.8.4    0.8.5    2022-01-07   moderate(1) high(1)  high    security vulnerability
simple-plist              1.3.0    1.3.1    2022-03-31   critical(1)          high    security vulnerability
urijs                     1.19.7   1.19.11  2022-04-03   high(1) moderate(4)  high    security vulnerability

10 vulnerable (61 vulnerabilities), 11 outdated, 7 deprecated.
Found a total of 18 Node packages.

To get more information about the node module vulnerabilities run:
 > yarn audit
```

## Continuous Integration

This gem provides a return code of `0` to indicate success and `1` to indicate failure. It is specifically designed for seamless integration into continuous integration pipelines.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'package-audit', require: false
```

And then execute:

```bash
bundle
```

Or install it yourself as:

```bash
gem install package-audit
```

## Usage

* To generate a report of vulnerable, deprecated, and outdated packages, execute the following command (optionally providing the `DIR` parameter to specify the path of the project you wish to check, which defaults to the current directory):

    ```bash
    package-audit [DIR]
    ```

* To include a custom configuration file, use `--config` or `-c` (see [Configuration File](#configuration-file) for details):

    ```bash
    package-audit --config .package-audit.yml [DIR]
    ```

* To display the vulnerable, deprecated or outdated packages separately (one list at a time), use:

    ```bash
    package-audit [deprecated|outdated|vulnerable] [DIR]
    ```

* To include ignored packages use the `--include-ignored` flag:

    ```bash
    package-audit --include-ignored [DIR]
    ```

* To include only specific technologies use `--technology` or `-t`:

    ```bash
    package-audit -t node -t ruby [DIR]
    package-audit --technology node --technology ruby [DIR]
    ```

* To include only specific groups use `--group` or `-g`:

    ```bash
    package-audit -e staging -g production [DIR]
    package-audit --group staging --group production [DIR]
    ```

* To produce the same report in a CSV format run:

    ```bash
    package-audit --format csv
    ```

* To produce the same report in a Markdown format run:

    ```bash
    package-audit --format md
    ```

* To show how risk is calculated for the above report run:

    ```bash
    package-audit risk
    ```

#### For a list of all commands and their options run:

```bash
package-audit help
```

OR

```bash
package-audit help [COMMAND]
```

## Configuration File

The `package-audit` gem automatically searches for `.package-audit.yml` in the current directory or in the specified `DIR` if available. However, you have the option to override the default configuration file location by using the `--config` (or `-c`) flag.

#### Below is an example of a configuration file:

```YAML
technology:
  node:
    nth-check:
      version: 1.0.2
      vulnerable: false
  ruby:
    devise-async:
      version: 1.0.0
      deprecated: false
    puma:
      version: 6.3.0
      deprecated: false
    selenium-webdriver:
      version: 4.1.0
      outdated: false
```

#### This configuration file allows you to specify the following exclusions:


* Ignore all security vulnerabilities associated with `nth-check@1.0.2`.
* Suppress messages regarding potential deprecations for  `device-async@1.0.0` and `puma@6.3.0`.
* Disable warnings about newer available versions of  `selenium-webdriver@4.1.0`

**Note:** If the installed package version differs from the expected package version specified in the configuration file, the exclusion settings will not apply to that particular package.

**Note:** If a package is reported for multiple reasons (e.g. vulnerable and outdated), it will still be reported unless the exclusion criteria match every reason for being on the report.

> By design, wildcard (`*`) version exclusions are not supported to prevent developers from inadvertently overlooking crucial messages when packages are updated.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tactica/package-audit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/tactica/package-audit/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Package::Audit project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tactica/package-audit/blob/main/CODE_OF_CONDUCT.md).
