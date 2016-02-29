require 'spec_helper'

describe Less::Parser do

  cwd = Pathname(__FILE__).dirname

  describe "simple usage" do
    it "parse less into css" do
      root = subject.parse(".class {width: 1+1}")
      root.to_css.gsub(/\n/,'').should eql ".class {  width: 2;}"
    end

    it "accepts options when parsing" do
      subject.parse(".class {width: 1px+1px;}", :compress => true).to_css.strip.should eql ".class{width:2px}"
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

  describe "when configured with multiple load paths" do
    subject { Less::Parser.new :paths => [ cwd.join('one'), cwd.join('two'), cwd.join('faulty') ] }

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
        e.filename.should == cwd.join('faulty/faulty.less').to_s
        e.line.should == 2
        e.column.should == 9
      else
        fail "parse error not raised"
      end
    end

  end

  it "throws a ParseError if the lesscss is bogus" do
    -> {subject.parse('{^)').to_css}.should raise_error(Less::ParseError, /Unrecognised input/)
  end

  describe "when configured with multiple load paths" do
    before {
      @parser = Less::Parser.new(:paths => [cwd.join('one').to_s, cwd.join('two').to_s])
    }

    it "will load files from both paths" do
      @parser.parse('@import "one.less";').to_css.gsub(/\n/,'').strip.should eql ".one {  width: 1;}"
      @parser.parse('@import "two.less";').to_css.gsub(/\n/,'').strip.should eql ".two {  width: 1;}"
    end
  end

  describe "when load paths are specified in as default options" do
    before do
      Less.paths << cwd.join('one').to_s
      Less.paths << cwd.join('two').to_s
      @parser = Less::Parser.new
    end
    after do
      Less.paths.clear
    end

    it "will load files from default load paths" do
      @parser.parse('@import "one.less";').to_css.gsub(/\n/,'').strip.should eql ".one {  width: 1;}"
      @parser.parse('@import "two.less";').to_css.gsub(/\n/,'').strip.should eql ".two {  width: 1;}"
    end
  end

end
