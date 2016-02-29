require 'spec_helper'

describe Less::Parser do

  cwd = Pathname(__FILE__).dirname
  support = cwd.join('../support/')

  describe "simple usage" do
    it "parse less into css" do
      root = subject.parse(".class {width: 1+1}")
      root.to_css.gsub(/\n/,'').should eql ".class {  width: 2;}"
    end

    it "accepts options when parsing" do
      subject.parse(".class {width: 1px+1px;}", compress: true).to_css.strip.should eql ".class{width:2px}"
    end

    it "passes exceptions from the less compiler" do
      -> { subject.parse('body { color: @a; }').to_css }.should raise_error(Less::ParseError, /variable @a is undefined/)
    end

    it "passes detail from the less exceptions" do
      begin
        less = <<-eos
        body {
          .foo {
            color: red;
          }
          .bar {
            color: @a;
          }
        }
        eos
        subject.parse(less, filename: 'foo.less').to_css
      rescue Less::ParseError => e
        e.message.should == 'variable @a is undefined'
        e.type.should == 'Name'
        e.filename.should eql 'foo.less'
        e.line.should eql 6
        e.column.should eql 19
        e.extract.should eql ["          .bar {", "            color: @a;", "          }"]
      else
        fail 'parse error not raised'
      end
    end
  end

  describe "loading in custom functions" do
    context 'defined as parser option' do
      subject { Less::Parser.new paths: [ support.join('custom_functions') ], custom_functions: support.join('custom_functions/custom_functions') }
      let(:result) { subject.parse('@import "custom_functions.less";').to_css.gsub(/\n/,'').strip }

      it 'should import the custom functions defined' do
        result.should eql ".one {  width: 20;}"
      end

      it 'should not permenantly modify the node path' do
        result
        ENV['NODE_PATH'].split(':').grep(support.join('custom_functions')).should be_empty
      end
    end

    context 'when specified as a global option' do
      before { Less.defaults[:custom_functions] = support.join('custom_functions/custom_functions') }
      after  { Less.defaults[:custom_functions] = nil }

      subject { Less::Parser.new paths: [ support.join('custom_functions') ] }
      let(:result) { subject.parse('@import "custom_functions.less";').to_css.gsub(/\n/,'').strip }

      it 'should import the custom functions defined' do
        result.should eql ".one {  width: 20;}"
      end
    end
  end

  describe "when configured with multiple load paths" do
    subject { Less::Parser.new paths: [ support.join('one'), support.join('two'), support.join('faulty') ] }

    it "will load files from both paths" do
      subject.parse('@import "one.less";').to_css.gsub(/\n/,'').strip.should eql ".one {  width: 1;}"
      subject.parse('@import "two.less";').to_css.gsub(/\n/,'').strip.should eql ".two {  width: 1;}"
    end

    it "passes exceptions from less imported less files" do
      -> { subject.parse('@import "faulty.less";').to_css }.should raise_error(Less::ParseError, /variable @a is undefined/)
    end

    it "will track imported files" do
      result_1 = subject.parse('@import "one.less";')
      result_2 = subject.parse('@import "two.less";')
      result_1.imports.grep(/one\.less$/).should_not be_empty
      result_2.imports.grep(/two\.less$/).should_not be_empty
    end

    it "reports type, line, column, extract and filename of (parse) error" do
      begin
        subject.parse('@import "faulty.less";').to_css
      rescue Less::ParseError => e
        e.type.should == 'Name'
        e.filename.should == support.join('faulty/faulty.less').to_s
        e.line.should == 2
        e.column.should == 9
        e.extract.should eql ["body {", "  color: @a;", "}"]
      else
        fail "parse error not raised"
      end
    end

  end

  it "throws a ParseError if the less has errors" do
    -> {subject.parse('{^)').to_css}.should raise_error(Less::ParseError, /Unrecognised input/)
  end

  describe "when configured with multiple load paths" do
    let(:parser) { Less::Parser.new(paths: [support.join('one').to_s, support.join('two').to_s]) }

    it "will load files from both paths" do
      parser.parse('@import "one.less";').to_css.gsub(/\n/,'').strip.should eql ".one {  width: 1;}"
      parser.parse('@import "two.less";').to_css.gsub(/\n/,'').strip.should eql ".two {  width: 1;}"
    end
  end

  describe "when load paths are specified in as default options" do
    before do
      Less.paths << support.join('one').to_s
      Less.paths << support.join('two').to_s
    end

    after { Less.paths.clear }

    let(:parser) { Less::Parser.new }

    it "will load files from default load paths" do
      parser.parse('@import "one.less";').to_css.gsub(/\n/,'').strip.should eql ".one {  width: 1;}"
      parser.parse('@import "two.less";').to_css.gsub(/\n/,'').strip.should eql ".two {  width: 1;}"
    end
  end

  # NOTE: runs JS tests from less.js it's a replacement for less-test.js
  describe "less.js test suite", :integration => true do

    TEST_LESS_DIR = File.expand_path('../../lib/less/js/less/test/less', File.dirname(__FILE__))
    TEST_CSS_DIR =  File.expand_path('../../lib/less/js/less/test/css' , File.dirname(__FILE__))

    Dir.glob(File.join(TEST_LESS_DIR, '*.less')).each do |less_file|
      base_name = File.basename(less_file, '.less')
      css_file = File.join(TEST_CSS_DIR, "#{base_name}.css")
      raise "missing css file: #{css_file}" unless File.exists?(css_file)

      less_content = File.read(less_file)
      case base_name
        when 'javascript'
          # adjust less .eval line :
          #   title: `process.title`;
          # later replaced by line :
          #   title: `typeof process.title`;
          # with something that won't fail (since we're not in Node.JS)
          less_content.sub!('process.title', '"node"')
      end

      it "#{base_name}.less" do
        parser = Less::Parser.new(filename: less_file, paths: [ File.dirname(less_file) ], custom_functions: support.join('less.js.tests-custom-functions') )
        less = parser.parse( less_content, strictMath: true, silent: true, relativeUrls: true )
        less.to_css.should == File.read(css_file)
      end

    end

  end

end
