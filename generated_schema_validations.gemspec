# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'generated_schema_validations'
  spec.version       = '0.1.1'
  spec.authors       = ['Georg Limbach']
  spec.email         = ['georg.limbach@lichtbit.com']

  spec.summary       = 'Generate rails validations from schema.rb file'
  spec.description   = 'After each migration it generates a file with some validations. Each active record should ' \
                       'include this file and can uns generated validations.'
  spec.homepage      = 'https://github.com/Lichtbit/generated_schema_validations'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Lichtbit/generated_schema_validations'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']
end
