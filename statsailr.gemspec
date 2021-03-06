require_relative 'lib/statsailr/version'

Gem::Specification.new do |spec|
  spec.name          = "statsailr"
  spec.version       = StatSailr::VERSION
  spec.authors       = ["Toshihiro Umehara"]
  spec.email         = ["toshi@niceume.com"]

  spec.summary       = %q{Provides a platform to focus on statistics}
  spec.description   = %q{StatSailr is a Ruby program that enables users to manipulate data and to apply statistical procedures in an intuiitive way. Internally, StatSailr converts StatSailr script into R's internal representation via Ruby, and executes it. }
  spec.homepage      = "https://github.com/niceume/statsailr"
  spec.license       = "GPL-3.0"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

#  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "r_bridge" , '~> 0.5', '>= 0.5.1'
  spec.add_runtime_dependency "statsailr_procs_base" , '~> 0.1', '>= 0.1.0'
end
