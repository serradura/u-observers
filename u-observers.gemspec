require_relative 'lib/micro/observers/version'

Gem::Specification.new do |spec|
  spec.name          = 'u-observers'
  spec.version       = Micro::Observers::VERSION
  spec.authors       = ['Rodrigo Serradura']
  spec.email         = ['rodrigo.serradura@gmail.com']

  spec.summary       = %q{Simple and powerful implementation of the observer pattern.}
  spec.description   = %q{Simple and powerful implementation of the observer pattern.}
  spec.homepage      = 'https://github.com/serradura/u-observers'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/serradura/u-observers'
  spec.metadata['changelog_uri'] = 'https://github.com/serradura/u-observers/releases'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('>= 2.2.0')

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 13.0'
end
