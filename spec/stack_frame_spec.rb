require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe CodeBuddy::StackFrame do
  subject { CodeBuddy::StackFrame.new("/gems/actionpack-3.0.3/lib/abstract_controller/base.rb:3:in `new'") }

  describe 'initialization' do
    before do
      CodeBuddy::StackFrame.any_instance.expects(:code).returns('def some_code_here end')
    end
    
    it 'should have the file path' do
      subject.path.should == '/gems/actionpack-3.0.3/lib/abstract_controller/base.rb'
    end
    it 'should have the line number' do
      subject.line.should == 3
    end
  end
  
  describe 'formatting code from the source file' do
    describe 'with a valid file' do
      let(:source_code) { [
        "require 'active_support/configurable'\n",
        "require 'active_support/descendants_tracker'\n",
        "require 'active_support/core_ext/module/anonymous'\n",
        "\n",
        "module AbstractController\n",
        "  class Error < StandardError; end\n",
        "  class ActionNotFound < StandardError; end\n",
        "\n",
        "  # <tt>AbstractController::Base</tt> is a low-level API. Nobody should be\n",
        "  # using it directly, and subclasses (like ActionController::Base) are\n",
        "  # expected to provide their own +render+ method, since rendering means\n",
        "  # different things depending on the context.  \n",
        "  class Base\n",
        "    attr_internal :response_body\n",
        "    attr_internal :action_name\n",
        "    attr_internal :formats\n",
        "\n",
        "    include ActiveSupport::Configurable\n",
        "    extend ActiveSupport::DescendantsTracker\n",
        "\n",
        "    class << self\n",
        "      attr_reader :abstract\n",
        "      alias_method :abstract?, :abstract\n",
        "\n",
        "      # Define a controller as abstract. See internal_methods for more\n",
        "      # details.\n",
        "      def abstract!\n",
        "        @abstract = true\n",
        "      end\n",
        "\n",
        "      # A list of all internal methods for a controller. This finds the first\n",
        "      # abstract superclass of a controller, and gets a list of all public\n",
        "      # instance methods on that abstract class. Public instance methods of\n"
        ] }
    
      before do
        File.expects(:new).with('/gems/actionpack-3.0.3/lib/abstract_controller/base.rb').
                           returns(mock(:readlines=>source_code))
      end

      it 'should read code from the middle of a file' do
        CodeRay.expects(:scan).with(source_code[4,25], :ruby).returns(parsed_code=mock)
        parsed_code.expects(:html).
                    with(:line_number_start => 5, :line_numbers => :inline, :wrap => :span).
                    returns(formatted_source=mock)

        stack_frame = CodeBuddy::StackFrame.new("/gems/actionpack-3.0.3/lib/abstract_controller/base.rb:15:in `new'") 
        stack_frame.code.should == formatted_source
      end
      it 'should read code from the top of a file' do
        CodeRay.expects(:scan).with(source_code[0,13], :ruby).returns(parsed_code=mock)
        parsed_code.expects(:html).
                    with(:line_number_start => 1, :line_numbers => :inline, :wrap => :span).
                    returns(formatted_source=mock)

        stack_frame = CodeBuddy::StackFrame.new("/gems/actionpack-3.0.3/lib/abstract_controller/base.rb:3:in `new'") 

        stack_frame.code.should == formatted_source
      end
      it 'should read code from the bottom of a file' do
        CodeRay.expects(:scan).with(source_code[19, 32], :ruby).returns(parsed_code=mock)
        parsed_code.expects(:html).
                    with(:line_number_start => 20, :line_numbers => :inline, :wrap => :span).
                    returns(formatted_source=mock)

        stack_frame = CodeBuddy::StackFrame.new("/gems/actionpack-3.0.3/lib/abstract_controller/base.rb:30:in `new'") 
      
        stack_frame.code.should == formatted_source
      end
    end
    
    it 'should return an error message in the code when unable to read the source file' do
      File.expects(:new).with('/no/such/file.rb').
                         raises(Errno::ENOENT.new('/no/such/file.rb'))

      stack_frame = CodeBuddy::StackFrame.new('/no/such/file.rb') 
      stack_frame.code.should == 'Unable to read the file /no/such/file.rb'
    end
  end
end