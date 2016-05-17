require 'rake'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

def gem_asset_path(package, path)
  File.join(Gem::Specification.find_by_name(package).gem_dir, path)
end

desc 'Convert Less to SCSS'
task :convert, [:branch] => [:deps] do |_, args|
  require './tasks/converter'
  branch = args.has_key?(:branch) ? args[:branch] : 'master'
  RConverter.new(:branch => branch).convert
end

desc 'Compile rcue-sass into CSS'
task :compile do
  require 'sass'
  require 'fileutils'
  require 'term/ansicolor'

  Sass.load_paths << File.join(gem_asset_path('bootstrap-sass', 'assets/stylesheets'))
  Sass.load_paths << File.join(gem_asset_path('font-awesome-sass', 'assets/stylesheets'))
  Sass.load_paths << File.join(gem_asset_path('patternfly-sass', 'assets/stylesheets'))

  ::Sass::Script::Value::Number.precision = [8, ::Sass::Script::Value::Number.precision].max

  path = 'assets/stylesheets'
  FileUtils.mkdir_p('tmp')

  puts Term::ANSIColor.bold "Compiling SCSS in #{path}"

  %w(rcue.css rcue.min.css).each do |out|
    style = (out == "rcue.min.css") ? :compressed : :nested
    src_path = File.join(path, '_rcue.scss')
    dst_path = File.join('tmp', out)
    engine = Sass::Engine.for_file(src_path, :syntax => :scss, :load_paths => [path], :style => style)
    css = engine.render
    css.gsub!(/(( )|(:))0((px)|(em)|(\%))/, '\10')
    File.open(dst_path, 'w') { |f| f.write css }
    puts Term::ANSIColor.cyan("  #{dst_path}") + '...'
  end
end

desc "Start a web server with both the less and the sass version"
task :serve => :compile do
  require 'webrick'
  server = WEBrick::HTTPServer.new :Port => 9000, :DirectoryIndex => []
  {
    '/'                                     => 'spec/main.html',
    '/less/dist/css'                        => 'spec/html/dist/css',
    '/less/dist/fonts'                      => 'assets/fonts/rcue',
    '/less/dist/img'                        => 'assets/images/rcue',
    '/less/components'                      => 'bower_components',
    '/less/components/bootstrap/dist/js'    => gem_asset_path('bootstrap-sass', 'assets/javascripts'),
    '/less/components/bootstrap/dist/fonts' => gem_asset_path('bootstrap-sass', 'assets/fonts/bootstrap'),
    '/less/components/font-awesome/fonts'   => gem_asset_path('font-awesome-sass', 'assets/fonts/font-awesome'),
    '/less/components/patternfly/dist/js/'  => 'bower_components/patternfly-sass/assets/javascripts',
    '/less/rcue'                            => 'spec/html',
    '/sass/dist/fonts'                      => 'assets/fonts',
    '/sass/dist/fonts/bootstrap'            => gem_asset_path('bootstrap-sass', 'assets/fonts/bootstrap'),
    '/sass/dist/img'                        => 'assets/images/rcue',
    '/sass/dist/images'                     => 'assets/images',
    '/sass/dist/js'                         => 'assets/javascripts',
    '/sass/dist/css'                        => 'tmp',
    '/sass/components'                      => 'bower_components',
    '/sass/components/bootstrap/dist/js'    => gem_asset_path('bootstrap-sass', 'assets/javascripts'),
    '/sass/dist/fonts/font-awesome'         => gem_asset_path('font-awesome-sass', 'assets/fonts/font-awesome'),
    '/sass/components/patternfly/dist/js/'  => 'bower_components/patternfly-sass/assets/javascripts',
    '/sass/rcue'                            => 'spec/html'
  }.each { |http, local| server.mount http, WEBrick::HTTPServlet::FileHandler, local }

  trap('INT') { server.stop }
  server.start
end

desc "Install testing dependencies using bower"
task :deps do
  system("bower install", out: $stdout, err: :out)
end

desc "Clean up the test results"
task :cleanup do
  require 'fileutils'
  FileUtils.rm_rf '.sass-cache'
  FileUtils.rm_rf 'spec/results'
end

desc "Run the tests with a web server"
task :test => [] do
  pid = Process.fork do
    puts "Starting web server on port 9000"
    $stdout.reopen('/dev/null', 'w')
    $stderr.reopen('/dev/null', 'w')
    Rake::Task[:serve].invoke
    puts "Stopping web server on port 9000"
  end
  sleep(5)
  puts "Starting the tests against the web server"
  begin
    Rake::Task[:spec].invoke
  ensure
    Process.kill('INT', pid)
  end
end

desc "Run the tests without a web server"
RSpec::Core::RakeTask.new(:spec) do |t|
  Rake::Task[:cleanup].invoke
  FileUtils.mkdir_p 'spec/results/sass'
  FileUtils.mkdir_p 'spec/results/less'
  t.pattern = Dir.glob('spec/**/*_spec.rb')
end

task :default => :convert
