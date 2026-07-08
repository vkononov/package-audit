require_relative 'lib/package/audit/version'

Gem::Specification.new do |spec|
  spec.name = 'package-audit'
  spec.version = Package::Audit::VERSION
  spec.authors = ['Vadim Kononov']
  spec.email = ['vadim@konoson.com']

  spec.summary = 'A helper tool to find outdated, deprecated and vulnerable dependencies.'
  spec.description = 'A useful tool for patch management and prioritization, package-audit produces a list of dependencies that are outdated, deprecated or have security vulnerabilities.' # rubocop:disable Layout/LineLength
  spec.homepage = 'https://github.com/vkononov/package-audit'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/vkononov/package-audit'

  # Ship only what the gem needs at runtime: the executable and library code
  # plus the license, readme, and the images the readme references. Using an
  # allowlist keeps tests, tooling, CI config, and other development files out
  # of the package even as new ones are added over time.
  root_files = %w[LICENSE.txt README.md]
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).select do |f|
      f.start_with?('exe/', 'lib/', 'docs/') || root_files.include?(f)
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'bundler-audit', '~> 0.8'
  spec.add_dependency 'thor', '~> 1.2'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
