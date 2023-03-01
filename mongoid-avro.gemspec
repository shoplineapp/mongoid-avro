# frozen_string_literal: true

require_relative "lib/mongoid/avro/version"

Gem::Specification.new do |spec|
  spec.name = "mongoid-avro"
  spec.version = Mongoid::Avro::VERSION
  spec.authors = ["Ray Su"]
  spec.email = ["rayway30419@gmail.com"]

  spec.summary = "Avro defination on mongoid model fields"
  spec.description = "This gem adds a custom avro_format field option on mongoid model which helps us to generate avro schema."
  spec.homepage = "https://github.com/shoplineapp/mongoid-avro"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shoplineapp/mongoid-avro"
  spec.metadata["changelog_uri"] = "https://github.com/shoplineapp/mongoid-avro/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mongoid"
  spec.add_dependency "avro"
end
