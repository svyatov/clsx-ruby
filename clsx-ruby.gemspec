# frozen_string_literal: true

require_relative 'lib/clsx/version'

Gem::Specification.new do |spec|
  spec.name = 'clsx-ruby'
  spec.version = Clsx::VERSION
  spec.authors = ['Leonid Svyatov']
  spec.email = ['leonid@svyatov.com']

  spec.summary = 'The fastest conditional CSS class builder for Ruby'
  spec.description = 'Build CSS class strings from conditional expressions, hashes, arrays, or nested structures. ' \
                     'Framework-agnostic. Perfect for ViewComponent, Phlex, and Tailwind CSS. ' \
                     'Works with any Ruby codebase.'
  spec.homepage = 'https://github.com/svyatov/clsx-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(
          *%w[bin/ test/ spec/ features/ benchmark/ .git .github appveyor Gemfile Rakefile .rubocop]
        )
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
