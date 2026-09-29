# frozen_string_literal: true

require_relative 'lib/sangho/version'

Gem::Specification.new do |spec|
  spec.name          = 'sangho'
  spec.version       = Sangho::VERSION
  spec.authors       = ['Sangho']
  spec.email         = ['nels.holy.allg@gmail.com']
  spec.summary       = "SDK officiel Ruby pour l'API Sangho"
  spec.description   = "Infrastructure de paiements adaptée au marché africain — SDK officiel Ruby pour l'API Sangho"
  spec.homepage      = 'https://docs.sangho.ga/api/sdks/ruby/'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.1'

  spec.metadata = {
    'source_code_uri' => 'https://github.com/sangho-sdks/sangho.ruby',
    'changelog_uri' => 'https://github.com/sangho-sdks/sangho.ruby/blob/main/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/sangho-sdks/sangho.ruby/issues',
    'rubygems_mfa_required' => 'true'
  }

  spec.files         = Dir['lib/**/*', 'README.md', 'CHANGELOG.md', 'LICENSE']
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 2.0'
  spec.add_dependency 'json',    '~> 2.0'

  spec.add_development_dependency 'rspec',   '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.60'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock', '~> 3.23'
end
