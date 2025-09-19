
Gem::Specification.new do |s|

  s.name = 'probatio'

  s.version = File.read(
    File.expand_path('../lib/probatio.rb', __FILE__)
  ).match(/ VERSION *= *['"]([^'"]+)/)[1]

  s.platform = Gem::Platform::RUBY
  s.authors = [ 'John Mettraux' ]
  s.email = [ 'jmettraux+flor@gmail.com' ]
  s.homepage = "https://github.com/floraison/#{s.name}"
  s.license = 'MIT'
  s.summary = 'test tools for floraison and flor'

  s.description = %{
Test tools for floraison and flor. Somewhere between Minitest and Rspec, but not as excellent.
  }.strip

  s.metadata = {
    'changelog_uri' => s.homepage + '/blob/master/CHANGELOG.md',
    'bug_tracker_uri' => s.homepage + '/issues',
    'documentation_uri' => s.homepage,
    'homepage_uri' =>  s.homepage,
    'source_code_uri' => s.homepage,
    #'mailing_list_uri' => 'https://groups.google.com/forum/#!forum/floraison',
    #'wiki_uri' => s.homepage + '/wiki',
    'rubygems_mfa_required' => 'true',
  }

  #s.files = `git ls-files`.split("\n")
  s.files = Dir[
    '{README,CHANGELOG,CREDITS,LICENSE}.{md,txt}',
    #'Makefile',
    'lib/**/*.rb', #'spec/**/*.rb', 'test/**/*.rb',
    'exe/*',
    "#{s.name}.gemspec",
  ]

  s.add_runtime_dependency 'stringio'
  s.add_runtime_dependency 'diff-lcs', '~> 1.6'
  s.add_runtime_dependency 'colorato', '~> 1.0'

  s.require_path = 'lib'

  s.bindir = 'exe'
  s.executables = [ 'proba' ]
end

