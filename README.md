# Package::Audit

[![Gem Version](https://img.shields.io/gem/v/package-audit.svg)](https://rubygems.org/gems/package-audit)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Lint Status](https://github.com/vkononov/package-audit/actions/workflows/lint.yml/badge.svg)](https://github.com/vkononov/package-audit/actions/workflows/lint.yml)
[![Test Status](https://github.com/vkononov/package-audit/actions/workflows/test.yml/badge.svg)](https://github.com/vkononov/package-audit/actions/workflows/test.yml)

A useful tool for patch management and prioritization, `package-audit` produces a list of dependencies that are outdated, deprecated or have security vulnerabilities.

`Package::Audit` will automatically detect the technologies used by the project and print out an appropriate report.

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/yellow_img.png)](https://www.buymeacoffee.com/vkononov)

## Supported Technologies

* Ruby
* Node (using Yarn)

## Report Example

Below is an example of running the script on a project that uses both Ruby and Node.

```
======================================================================================================
Package                   Version  Latest   Latest Date  Flags  Vulnerabilities       Risk
======================================================================================================
actionpack                7.0.3.1  7.0.4.3  2023-03-13   ⦗V··⦘  unknown(2) medium(1)  high
activerecord              7.0.3.1  7.0.4.3  2023-03-13   ⦗V··⦘  high(2)               high
activesupport             7.0.3.1  7.0.4.3  2023-03-13   ⦗V··⦘  unknown(2)            high
byebug                    11.1.3   11.1.3   2020-04-23   ⦗··D⦘                        medium
devise-async              1.0.0    1.0.0    2017-09-20   ⦗··D⦘                        medium
foundation-rails          6.6.2.0  6.6.2.0  2020-03-30   ⦗··D⦘                        medium
puma                      6.2.1    6.2.2    1980-01-01   ⦗··D⦘                        medium
rails-controller-testing  1.0.5    1.0.5    2020-06-23   ⦗··D⦘                        medium
rails                     7.0.3.1  7.0.4.3  2023-03-13   ⦗·O·⦘                        low
rubocop-i18n              3.0.0    3.0.0    2020-12-14   ⦗··D⦘                        medium
sass-rails                6.0.0    6.0.0    2019-08-16   ⦗··D⦘                        medium
selenium-webdriver        4.8.6    4.9.0    2023-04-21   ⦗·O·⦘                        low
serviceworker-rails       0.6.0    0.6.0    2019-07-09   ⦗··D⦘                        medium
turbolinks                5.2.1    5.2.1    2019-09-18   ⦗··D⦘                        medium

3 ⦗V⦘ulnerable (7 vulnerabilities), 6 ⦗O⦘utdated, 9 ⦗D⦘eprecated.
Found a total of 14 Ruby packages.

For more information about Ruby vulnerabilities run:
 > bundle-audit check --update

==================================================================================================
Package                   Version  Latest   Latest Date  Flags  Vulnerabilities      Risk
==================================================================================================
@sideway/formula          3.0.0    3.0.1    2022-12-16   ⦗V··⦘  moderate(1)          medium
ansi-regex                4.1.0    6.0.1    2021-09-10   ⦗V··⦘  high(5)              high
async                     2.6.3    3.2.4    2022-06-07   ⦗V··⦘  high(2)              high
babel-eslint              10.1.0   10.1.0   2020-02-26   ⦗··D⦘                       medium
decode-uri-component      0.2.0    0.4.1    2022-12-19   ⦗V··⦘  high(10)             high
hermes-engine             0.7.2    0.11.0   2022-01-27   ⦗V··⦘  critical(2)          high
json5                     2.2.0    2.2.3    2022-12-31   ⦗V··⦘  high(30)             high
react-native-safari-view  2.1.0    2.1.0    2017-10-02   ⦗··D⦘                       medium
react-native              0.64.2   0.71.7   2023-04-19   ⦗·O·⦘                       low
react-navigation-stack    2.10.4   2.10.4   2021-03-01   ⦗··D⦘                       medium
react-navigation          4.4.4    4.4.4    2021-02-21   ⦗··D⦘                       medium
redux-axios-middleware    4.0.1    4.0.1    2019-07-10   ⦗··D⦘                       medium
redux-devtools-extension  2.13.9   2.13.9   2021-03-06   ⦗··D⦘                       medium
redux-persist             6.0.0    6.0.0    2019-09-02   ⦗··D⦘                       medium
shell-quote               1.6.1    1.8.1    2023-04-07   ⦗V··⦘  critical(3)          high
shelljs                   0.8.4    0.8.5    2022-01-07   ⦗V··⦘  moderate(1) high(1)  high
simple-plist              1.3.0    1.3.1    2022-03-31   ⦗V··⦘  critical(1)          high
urijs                     1.19.7   1.19.11  2022-04-03   ⦗V··⦘  high(1) moderate(4)  high

10 ⦗V⦘ulnerable (61 vulnerabilities), 11 ⦗O⦘utdated, 7 ⦗D⦘eprecated.
Found a total of 18 Node packages.

For more information about Node vulnerabilities run:
 > yarn audit
```

### Understanding the Flags Column

The Flags column shows which risk types apply to each package:

- `⦗V··⦘` - Vulnerable (has security vulnerabilities)
- `⦗·O·⦘` - Outdated (newer version available)
- `⦗··D⦘` - Deprecated (no updates in 2+ years)
- `⦗VO·⦘` - Both vulnerable and outdated
- `⦗VOD⦘` - All three risk types apply

The footer uses the same notation (⦗V⦘ulnerable, ⦗O⦘utdated, ⦗D⦘eprecated) as a legend.

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

* To filter packages by specific risk types, use the `--deprecated`, `--outdated`, or `--vulnerable` flags:

    ```bash
    # Show only deprecated packages
    package-audit --deprecated [DIR]

    # Show only vulnerable packages
    package-audit --vulnerable [DIR]

    # Show deprecated OR vulnerable packages (not outdated-only)
    package-audit --deprecated --vulnerable [DIR]
    ```

* To exclude specific risk types, use the `--skip-deprecated`, `--skip-outdated`, or `--skip-vulnerable` flags:

    ```bash
    # Show everything except deprecated packages
    package-audit --skip-deprecated [DIR]

    # Show everything except outdated packages
    package-audit --skip-outdated [DIR]

    # Show only vulnerable packages (exclude deprecated and outdated)
    package-audit --skip-deprecated --skip-outdated [DIR]
    ```

    **Note:** Packages with multiple risk types are handled intelligently. For example, a package that is both outdated and vulnerable will still appear when using `--skip-outdated` because it has a vulnerability.

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

Bug reports and pull requests are welcome on GitHub at https://github.com/vkononov/package-audit. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/vkononov/package-audit/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Package::Audit project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/vkononov/package-audit/blob/main/CODE_OF_CONDUCT.md).
