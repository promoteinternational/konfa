require_relative 'spec_helper'

class MyTestKonfa < Konfa::Base
  class << self
    def env_variable_prefix
      'PREF_'
    end

    def allowed_variables
      {
        :my_var         => 'default value',
        :default_is_nil => nil
      }
    end
  end
end

class MyOtherTestKonfa < Konfa::Base
  class << self
    def env_variable_prefix
      'OTHER_PREF_'
    end

    def allowed_variables
      {
        :my_var         => 'other default',
        :default_is_nil => 'no it is not'
      }
    end
  end
end


describe Konfa do
  let(:bool_file)  { File.expand_path("../support/bool_config.yaml", __FILE__) }
  let(:good_file)  { File.expand_path("../support/good_config.yaml", __FILE__) }
  let(:bad_file)   { File.expand_path("../support/bad_config.yaml", __FILE__) }
  let(:not_yaml)   { File.expand_path("../support/not_yaml.yaml", __FILE__) }
  let(:empty_file) { File.expand_path("../support/empty.yaml", __FILE__) }
  let(:array_file) { File.expand_path("../support/array.yaml", __FILE__) }

  before(:each) do
    MyTestKonfa.reset_configuration
    MyTestKonfa.send(:initializer=, nil)
    MyOtherTestKonfa.reset_configuration
    MyOtherTestKonfa.send(:initializer=, nil)
  end

  context "#variables" do
    it "can list available configuration variables" do
      expect(MyTestKonfa.variables).to be_kind_of Array
    end

    it "presents all variable keys as symbols" do
      expect(MyTestKonfa.variables.all? {|v| v.kind_of? Symbol }).to be true
    end
  end

  context "#dump" do
    it "can dump all existing variables and values" do
      expect(MyTestKonfa.dump).to be_kind_of Hash
      expect(MyTestKonfa.dump.keys).to eq MyTestKonfa.variables
    end

    it "dupes the current state" do
      dumped = MyTestKonfa.dump
      expect(dumped).not_to equal MyTestKonfa.dump
    end
  end

  context "class configuration" do
    it "does not provide direct access to variable store" do
      expect {
        MyTestKonfa.configuration
      }.to raise_error(NoMethodError)
    end
  end

  context "#get" do
    it "all variables can be accessed" do
      MyTestKonfa.variables.each do |variable|
        expect {
          MyTestKonfa.get(variable)
        }.not_to raise_error
      end
    end

    it "raises an exception if unknown configuration variable is accessed" do
      expect {
        MyTestKonfa.get :_this_is_totally_wrong
      }.to raise_error Konfa::UnsupportedVariableError
    end
  end

  context "#initialize_from_yaml" do
    it "returns parsed values" do
      expect(MyTestKonfa.initialize_from_yaml(good_file)).to eq MyTestKonfa.dump
    end

    it "raises an exception if file does not contain YAML" do
      expect(MyTestKonfa).to_not receive(:after_initialize) # FIXME test this in #init spec
      expect {
        MyTestKonfa.initialize_from_yaml(not_yaml)
      }.to raise_error(Konfa::InitializationError)
    end

    it "raises an exception if file does not key/value pairs" do
      expect {
        MyTestKonfa.initialize_from_yaml(array_file)
      }.to raise_error(Konfa::InitializationError)
    end

    context "when used as an initializer" do
      it "configures variables from a YAML file" do
        MyTestKonfa.initialize_with :initialize_from_yaml, good_file
        expect {
          MyTestKonfa.init
        }.to_not raise_error
        expect(MyTestKonfa.get :my_var).to eq 'read from the yaml file'
      end

      it "requires all keys in YAML file to be defined in config class by default" do
        expect {
          MyTestKonfa.initialize_from_yaml(bad_file)
        }.to raise_error Konfa::UnsupportedVariableError
      end

      it "handles Ruby's implicit type conversion" do
        MyTestKonfa.initialize_from_yaml(bool_file)
        expect(MyTestKonfa.get :my_var).to be_a(String)
        expect(MyTestKonfa.get :my_var).to eq 'true'
      end

      it "is possible to load an empty file" do
        expect {
          MyTestKonfa.initialize_with :initialize_from_yaml, empty_file
          MyTestKonfa.init
        }.not_to raise_error
        expect(MyTestKonfa.get :my_var).to eq 'default value'
      end
    end
  end

  context "#initialize_from_env" do

    it "prefixes environment variables" do
      expect(MyTestKonfa.env_variable_prefix).to eq 'PREF_'
    end

    it "can be initialized with environment variables" do
      begin
        ENV["PREF_MY_VAR"] = 'set from env'
        ENV["IGNORE_MY_VAR"]  = 'should be ignored'

        expect {
          MyTestKonfa.initialize_from_env
        }.not_to raise_error

        expect(MyTestKonfa.get :my_var).to eq 'set from env'
      ensure
        ENV.delete("PREF_MY_VAR")
        ENV.delete("IGNORE_MY_VAR")
      end
    end

    it "requires all keys in namespace to be defined in config class by default" do
      ENV["PREF_BAD_VARIABLE"] = 'should yield an error'

      expect {
        MyTestKonfa.initialize_from_env
      }.to raise_error Konfa::UnsupportedVariableError

      ENV.delete("PREF_BAD_VARIABLE")
    end
  end

  context "#init" do
    before(:each) do
      MyTestKonfa.initialize_with(:initialize_from_yaml, good_file)
    end

    it 'executes initialization method on first call to configuration' do
      expect(MyTestKonfa).to receive(:initialize_from_yaml).once.with(good_file).and_call_original
      MyTestKonfa.send(:configuration)
      MyTestKonfa.send(:configuration)
    end

    it 'calls #after_initialize' do
      expect(MyTestKonfa).to receive(:after_initialize)
      MyTestKonfa.init
    end

    it 'sets initialized to true' do
      expect {
        MyTestKonfa.init
      }.to change(MyTestKonfa, :initialized).from(false).to(true)
    end

     context "without initialize method" do
      before do
        MyTestKonfa.send(:initializer=, nil)
      end

      it 'calls #after_initialize' do
        expect(MyTestKonfa).to receive(:after_initialize)
        MyTestKonfa.init
      end

      it 'sets initialized to true' do
        expect {
          MyTestKonfa.init
        }.to change(MyTestKonfa, :initialized).from(false).to(true)
      end
    end
  end

  context "#reset_configuration" do
    it 'sets initialized to false' do
      expect(MyTestKonfa).to receive(:initialized=).with(false)
      MyTestKonfa.reset_configuration
    end

    it 'sets configuration to allowed_variables' do
      allow(MyTestKonfa).to receive(:allowed_variables).and_return(overrided: true)
      MyTestKonfa.reset_configuration
      expect(MyTestKonfa.instance_variable_get(:@configuration)).to eq(MyTestKonfa.allowed_variables)
    end
  end

  context "#with_config" do

    let(:test_value) { 'my test value' }

    before(:each) do
      MyTestKonfa.send(:store, :my_var, test_value)
    end

    it "prevents existing values to be over written" do
      MyTestKonfa.with_config(my_var: 'blah') do
        expect(MyTestKonfa.get :my_var).to eq 'blah'
      end

      expect(MyTestKonfa.get :my_var).to be test_value
    end

    it "drops any new values set in block" do
      MyTestKonfa.with_config do
        MyTestKonfa.send(:store, :my_var, 'blah')
        expect(MyTestKonfa.get :my_var).to eq 'blah'
      end

      expect(MyTestKonfa.get :my_var).to be test_value
    end

    it "works even if an exception is raised" do
      expect {
        MyTestKonfa.with_config(my_var: 'blah') do
          expect(MyTestKonfa.get :my_var).to eq 'blah'
          raise Exception.new('This is en error')
        end
      }.to raise_error

      expect(MyTestKonfa.get :my_var).to be test_value
    end

    it "works with multiple values" do
      MyTestKonfa.with_config(my_var: 'my new value', default_is_nil: 'a val') do
        expect(MyTestKonfa.get :my_var).to eq 'my new value'
        expect(MyTestKonfa.get :default_is_nil).to eq 'a val'
      end
      expect(MyTestKonfa.get :my_var).to be test_value
      expect(MyTestKonfa.get :default_is_nil).not_to eq 'a val'
    end

    it "returns the result of the block" do
      retval = MyTestKonfa.with_config(:my_var => 'my new value') do
        MyTestKonfa.get(:my_var)
      end

      expect(MyTestKonfa.get :my_var).to be test_value
      expect(retval).to eq 'my new value'
    end
  end

  context "#true? and #false?" do
    it "implements a shorthand for boolean operations" do
      expect(MyTestKonfa).to respond_to(:'true?')
      expect(MyTestKonfa).to respond_to(:'false?')
    end

    it "raises an exception for true? if variable does not exist" do
      expect {
        MyTestKonfa.true?(:does_not_exist)
      }.to raise_error(Konfa::UnsupportedVariableError)
    end

    it "raises an exception for false? if variable does not exist" do
      expect {
        MyTestKonfa.false?(:does_not_exist)
      }.to raise_error(Konfa::UnsupportedVariableError)
    end

    it "considers values 1, yes or true to be true" do
      ['true', '1', 'yes', 'on'].each do |truthy|
        MyTestKonfa.send(:store, :my_var, truthy)

        expect(MyTestKonfa.true? :my_var).to be true
        expect(MyTestKonfa.false? :my_var).to be false
      end
    end

    it "considers nil or any value other than 1, yes or true to be false" do
      [nil, '0', 'false', 'blah', 'NOT TRUE'].each do |falsy|
        MyTestKonfa.send(:store, :my_var, falsy)

        expect(MyTestKonfa.true? :my_var).to be false
        expect(MyTestKonfa.false? :my_var).to be true
      end
    end

    it "is case insensitive" do
      ['True', 'trUe', 'yEs', 'YES', 'oN'].each do |truthy|
        MyTestKonfa.send(:store, :my_var, truthy)

        expect(MyTestKonfa.true? :my_var).to be true
        expect(MyTestKonfa.false? :my_var).to be false
      end
    end

    it "ignores whitespace" do
      ['    true', ' on ', '1    '].each do |truthy|
        MyTestKonfa.send(:store, :my_var, truthy)

        expect(MyTestKonfa.true? :my_var).to be true
        expect(MyTestKonfa.false? :my_var).to be false
      end
    end
  end

  context "when declaring multiple sub classes" do
    it 'is possible to initialize them both from env' do
      begin
        ENV["PREF_MY_VAR"]       = 'belongs to MyTestKonfa'
        ENV["OTHER_PREF_MY_VAR"] = 'belongs to MyOtherTestKonfa'

        MyTestKonfa.initialize_with(:initialize_from_env)
        MyOtherTestKonfa.initialize_with(:initialize_from_env)
        expect {
          MyTestKonfa.init
          MyOtherTestKonfa.init
        }.not_to raise_error

        expect(MyTestKonfa.get :my_var).to eq 'belongs to MyTestKonfa'
        expect(MyOtherTestKonfa.get :my_var).to eq 'belongs to MyOtherTestKonfa'
      ensure
        ENV.delete("PREF_MY_VAR")
        ENV.delete("OTHER_PREF_MY_VAR")
      end
    end

    it 'is possible to initialize them both from config' do
      MyTestKonfa.initialize_from_yaml(good_file)
      MyOtherTestKonfa.initialize_from_yaml(bool_file)

      expect(MyTestKonfa.get :my_var).to eq 'read from the yaml file'
      expect(MyOtherTestKonfa.get :my_var).to eq 'true'
    end
  end
end
