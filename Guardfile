guard :rspec, cmd: "bundle exec rspec --color --format documentation" do
  require "guard/rspec/dsl"
  dsl = Guard::RSpec::Dsl.new(self)
  watch(%r{^spec/(.*)\/?(.*)_spec\.rb$})

  # Feel free to open issues for suggestions and improvements

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files)

  # Ruby files
  ruby = dsl.ruby
  dsl.watch_spec_files_for(ruby.lib_files)
end
