PATTERNFLY_GEM_ROOT = Gem::Specification.find_by_name("patternfly-sass").gem_dir
require "#{PATTERNFLY_GEM_ROOT}/tasks/converter"

class RConverter < Converter
  def initialize(options = {})
    super(options)
    @repository = options.fetch(:repository, 'patternfly/rcue')
  end

  TRANSFORMATIONS = [
    :replace_vars,
    :replace_file_imports,
    :replace_mixin_definitions,
    :replace_spin,
    :replace_image_urls,
    :remove_unnecessary_escaping,
    :replace_escaping,
    :convert_less_ampersand,
    :deinterpolate_vararg_mixins,
    :replace_calculation_semantics
  ]

  PATHS = <<-VAR.gsub(/^\s*/, '')
    /* Images and fonts path correction for SASS only */
    $patternfly-sass-asset-helper:                                      false !default;
    $img-path:                                                          if($patternfly-sass-asset-helper, "rcue", "../images/rcue");
    $font-path:                                                         if($patternfly-sass-asset-helper, "rcue", "../fonts/rcue");
  VAR

  private

  def checkout_upstream
    unless Dir.exist?(@source)
      `git clone git@github.com:#{@repository}.git #{@source}`
    end
    repo ||= Rugged::Repository.new(@source)
    repo.checkout(@branch)
    @sha = repo.last_commit.oid
  end

  def process_stylesheets
    save_to = File.join(@destination, 'stylesheets', 'rcue')
    FileUtils.mkdir_p(save_to) unless File.exist?(save_to)

    rcue_less_files.each do |path|
      file = File.basename(path)
      less = File.read(path)
      output = File.join(save_to, "_#{file.sub(/\.less$/, '.scss')}")
      File.open(output, 'w') do |f|
        f.write(less_to_sass(file, less))
      end
    end

    File.open(File.join(save_to, '..', '_rcue.scss'), 'w') do |f|
      f.write(generate_top_level)
    end
  end

  def less_to_sass(file, input)
    transforms = TRANSFORMATIONS.dup
    transforms << :fix_font_and_image_paths if file == 'variables.less'
    transforms.inject(input) { |a, e| send(e, a) }
  end

  def fix_font_and_image_paths(file)
    [file, PATHS].join("\n")
  end

  def generate_top_level
    file = top_level_files.map { |f| File.read(f) }.join("\n")
    file = replace_all(file, %r{\@import \"[a-zA-Z0-9\.\-\/]+/patternfly";$}, '')
    file = replace_all(file, /@import "([^\.]{2})/, '@import "rcue/\1')
    file = replace_all(file, %r{\@import \"[a-zA-Z0-9\.\-\/]+/patternfly\-additions";$}, '@import "patternfly";')
    file = file.split("\n").uniq.join("\n")
    file = remove_comments_and_whitespace(file)
  end

  def top_level_files
    retrieve_files(File.join(@source, 'less'), /rcue(\-additions)?\.less$/)
  end

  def copy_config
    [
      {
        :source      => File.join(@source, 'dist', 'img'),
        :select      => /\.(png|gif|jpe?g|svg|ico)$/,
        :reject      => nil,
        :destination => File.join(@destination, 'images', 'rcue')
      },
      {
        :source      => File.join(@source, 'dist', 'fonts'),
        :select      => /\.(eot|svg|ttf|woff2?)$/,
        :reject      => nil,
        :destination => File.join(@destination, 'fonts', 'rcue')
      },
      {
        :source      => File.join(@source, 'tests'),
        :select      => /.*/,
        :reject      => nil,
        :destination => TEST_DIR
      },
      {
        :source      => File.join(@source, 'dist', 'css'),
        :select      => /css/,
        :reject      => /styles(-additions)?(\.min)?\.css/,
        :destination => File.join(TEST_DIR, 'dist', 'css')
      }
    ]
  end

  def rcue_less_files
    patternfly_less_files.reject { |r| r =~ /rcue/ }
  end

  def store_version
    path = 'lib/rcue-sass/version.rb'
    content = File.read(path).sub(/RCUE_SHA\s*=\s*['"][\w]+['"]/, "RCUE_SHA = '#{@sha}'")
    File.open(path, 'w') { |f| f.write(content) }
  end
end
