# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'generated_schema_validations'
  spec.version       = '0.7.0'
  spec.authors       = ['Georg Limbach']
  spec.email         = ['georg.limbach@lichtbit.com']

  spec.summary       = 'Generate rails validations from schema.rb file'
  spec.description   = 'After each migration it generates a file with some validations. Each active record should ' \
                       'include this file and can use the generated validations.'
  spec.homepage      = 'https://github.com/Lichtbit/generated_schema_validations'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.metadata['source_code_uri'] = 'https://github.com/Lichtbit/generated_schema_validations'
  spec.metadata['changelog_uri'] = 'https://github.com/Lichtbit/generated_schema_validations#changelog'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '>= 7.2', '< 9'
  spec.add_dependency 'railties', '>= 7.2', '< 9'
end
