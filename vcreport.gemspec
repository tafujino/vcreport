require_relative 'lib/vcreport/version'

Gem::Specification.new do |spec|
  spec.name          = "vcreport"
  spec.version       = Vcreport::VERSION
  spec.authors       = ["Takeshi Fujino"]
  spec.email         = ["fujino@edu.k.u-tokyo.ac.jp"]

  spec.summary       = %q{Generates a report on variant call progress and metrics}
#  spec.description   = %q{TODO: Write a longer description or delete this line.}
#  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

#  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

#  spec.metadata["homepage_uri"] = spec.homepage
#  spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
#  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z --recurse-submodules`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "activesupport"
  spec.add_dependency "redcarpet"
  spec.add_dependency "concurrent-ruby"
  spec.add_dependency "posix-spawn"
  spec.add_dependency "mono_logger"
  spec.add_dependency "webrick"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "solargraph"
  spec.add_development_dependency "rake"
end
