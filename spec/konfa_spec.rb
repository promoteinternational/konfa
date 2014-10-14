$: << File.join(File.dirname(File.dirname(__FILE__)), "lib")

require 'konfa'

class MyKonfa < Konfa::Base
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

class MyOtherKonfa < Konfa::Base
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
    MyKonfa.send(:configuration=, nil)
    MyOtherKonfa.send(:configuration=, nil)
  end

  context "#variables" do
    it "can list available configuration variables" do
      expect(MyKonfa.variables).to be_kind_of Array
    end

    it "presents all variable keys as symbols" do
      expect(MyKonfa.variables.all? {|v| v.kind_of? Symbol }).to be true
    end
  end

  context "#dump" do
    it "can dump all existing variables and values" do
      expect(MyKonfa.dump).to be_kind_of Hash
      expect(MyKonfa.dump.keys).to eq MyKonfa.variables
    end

    it "dumpes the current state" do
      dumped = MyKonfa.dump
      expect(dumped).not_to equal MyKonfa.dump
    end
  end

  context "class configuration" do
    it "does not provide direct access to variable store" do
      expect {
        MyKonfa.configuration
      }.to raise_error(NoMethodError)
    end
  end

  context "#get" do
    it "all variables can be accessed" do
      MyKonfa.variables.each do |variable|
        expect {
          MyKonfa.get(variable)
        }.not_to raise_error
      end
    end

    it "raises an exception if unknown configuration variable is accessed" do
      expect {
        MyKonfa.get :_this_is_totally_wrong
      }.to raise_error Konfa::UnsupportedVariableError
    end
  end

  context "#initialize_from_yaml" do
    it "can be initialized with a YAML file" do
      expect {
        MyKonfa.initialize_from_yaml(good_file)
      }.to_not raise_error
      expect(MyKonfa.get :my_var).to eq 'read from the yaml file'
    end

    it "returns parsed values" do
      expect(MyKonfa.initialize_from_yaml(good_file)).to eq MyKonfa.dump
    end

    it "requires all keys in YAML file to be defined in config class by default" do
      expect {
        MyKonfa.initialize_from_yaml(bad_file)
      }.to raise_error Konfa::UnsupportedVariableError
    end

    it "handles Ruby's implicit type conversion" do
      MyKonfa.initialize_from_yaml(bool_file)
      expect(MyKonfa.get :my_var).to be_a(String)
      expect(MyKonfa.get :my_var).to eq 'true'
    end

    it "is possible to load an empty file" do
      expect(MyKonfa).to receive(:after_initialize)
      expect {
        MyKonfa.initialize_from_yaml(empty_file)
      }.not_to raise_error
      expect(MyKonfa.get :my_var).to eq 'default value'
    end

    it "raises an exception if file does not contain YAML" do
      expect(MyKonfa).to_not receive(:after_initialize)
      expect {
        MyKonfa.initialize_from_yaml(not_yaml)
      }.to raise_error(Konfa::InitializationError)
    end

    it "raises an exception if file does not key/value pairs" do
      expect {
        MyKonfa.initialize_from_yaml(array_file)
      }.to raise_error(Konfa::InitializationError)
    end
  end

  context "#initialize_from_env" do

    it "prefixes environment variables" do
      expect(MyKonfa.env_variable_prefix).to eq 'PREF_'
    end

    it "can be initialized with environment variables" do
      begin
        ENV["PREF_MY_VAR"] = 'set from env'
        ENV["IGNORE_MY_VAR"]  = 'should be ignored'

        expect {
          MyKonfa.initialize_from_env
        }.not_to raise_error

        expect(MyKonfa.get :my_var).to eq 'set from env'
      ensure
        ENV.delete("PREF_MY_VAR")
        ENV.delete("IGNORE_MY_VAR")
      end
    end

    it "requires all keys in namespace to be defined in config class by default" do
      ENV["PREF_BAD_VARIABLE"] = 'should yield an error'

      expect {
        MyKonfa.initialize_from_env
      }.to raise_error Konfa::UnsupportedVariableError

      ENV.delete("PREF_BAD_VARIABLE")
    end
  end

  context "#initialize_deferred" do
    it 'executes initialization method on first call to get' do
      MyKonfa.initialize_deferred(:initialize_from_yaml, good_file)
      # FIXME: Upgrade rspec and add this test
      expect(MyKonfa).to receive(:initialize_from_yaml).with(good_file).and_call_original
      MyKonfa.get :my_var
    end

    it 'populates konfiguration variables in first call to get' do
      MyKonfa.initialize_deferred(:initialize_from_yaml, good_file)

      expect(MyKonfa.dump[:my_var]).to eq 'default value'
      expect(MyKonfa.get :my_var).to eq 'read from the yaml file'
      expect(MyKonfa.dump[:my_var]).to eq 'read from the yaml file'
    end
  end

  context "#with_config" do

    let(:test_value) { 'my test value' }

    before(:each) do
      MyKonfa.send(:store, :my_var, test_value)
    end

    it "prevents existing values to be over written" do
      MyKonfa.with_config(my_var: 'blah') do
        expect(MyKonfa.get :my_var).to eq 'blah'
      end

      expect(MyKonfa.get :my_var).to be test_value
    end

    it "drops any new values set in block" do
      MyKonfa.with_config do
        MyKonfa.send(:store, :my_var, 'blah')
        expect(MyKonfa.get :my_var).to eq 'blah'
      end

      expect(MyKonfa.get :my_var).to be test_value
    end

    it "works even if an exception is raised" do
      expect {
        MyKonfa.with_config(my_var: 'blah') do
          expect(MyKonfa.get :my_var).to eq 'blah'
          raise Exception.new('This is en error')
        end
      }.to raise_error

      expect(MyKonfa.get :my_var).to be test_value
    end

    it "works with multiple values" do
      MyKonfa.with_config(my_var: 'my new value', default_is_nil: 'a val') do
        expect(MyKonfa.get :my_var).to eq 'my new value'
        expect(MyKonfa.get :default_is_nil).to eq 'a val'
      end
      expect(MyKonfa.get :my_var).to be test_value
      expect(MyKonfa.get :default_is_nil).not_to eq 'a val'
    end

    it "returns the result of the block" do
      retval = MyKonfa.with_config(:my_var => 'my new value') do
        MyKonfa.get(:my_var)
      end

      expect(MyKonfa.get :my_var).to be test_value
      expect(retval).to eq 'my new value'
    end
  end

  context "#true? and #false?" do
    it "implements a shorthand for boolean operations" do
      expect(MyKonfa).to respond_to(:'true?')
      expect(MyKonfa).to respond_to(:'false?')
    end

    it "raises an exception for true? if variable does not exist" do
      expect {
        MyKonfa.true?(:does_not_exist)
      }.to raise_error(Konfa::UnsupportedVariableError)
    end

    it "raises an exception for false? if variable does not exist" do
      expect {
        MyKonfa.false?(:does_not_exist)
      }.to raise_error(Konfa::UnsupportedVariableError)
    end

    it "considers values 1, yes or true to be true" do
      ['true', '1', 'yes', 'on'].each do |truthy|
        MyKonfa.send(:store, :my_var, truthy)

        expect(MyKonfa.true? :my_var).to be true
        expect(MyKonfa.false? :my_var).to be false
      end
    end

    it "considers nil or any value other than 1, yes or true to be false" do
      [nil, '0', 'false', 'blah', 'NOT TRUE'].each do |falsy|
        MyKonfa.send(:store, :my_var, falsy)

        expect(MyKonfa.true? :my_var).to be false
        expect(MyKonfa.false? :my_var).to be true
      end
    end

    it "is case insensitive" do
      ['True', 'trUe', 'yEs', 'YES', 'oN'].each do |truthy|
        MyKonfa.send(:store, :my_var, truthy)

        expect(MyKonfa.true? :my_var).to be true
        expect(MyKonfa.false? :my_var).to be false
      end
    end

    it "ignores whitespace" do
      ['    true', ' on ', '1    '].each do |truthy|
        MyKonfa.send(:store, :my_var, truthy)

        expect(MyKonfa.true? :my_var).to be true
        expect(MyKonfa.false? :my_var).to be false
      end
    end
  end

  context "#after_initialize" do
    it "calls after_initialize when initialized from environment" do
      expect(MyKonfa).to receive(:after_initialize)
      MyKonfa.initialize_from_env
    end

    it "calls after_initialize when initialized from yaml" do
      expect(MyKonfa).to receive(:after_initialize)
      MyKonfa.initialize_from_yaml(good_file)
    end
  end

  context "when declaring multiple sub classes" do
    it 'is possible to initialize them both from env' do
      begin
        ENV["PREF_MY_VAR"]       = 'belongs to MyKonfa'
        ENV["OTHER_PREF_MY_VAR"] = 'belongs to MyOtherKonfa'

        expect {
          MyKonfa.initialize_from_env
          MyOtherKonfa.initialize_from_env
        }.not_to raise_error

        expect(MyKonfa.get :my_var).to eq 'belongs to MyKonfa'
        expect(MyOtherKonfa.get :my_var).to eq 'belongs to MyOtherKonfa'
      ensure
        ENV.delete("PREF_MY_VAR")
        ENV.delete("OTHER_PREF_MY_VAR")
      end
    end

    it 'is possible to initialize them both from config' do
      MyKonfa.initialize_from_yaml(good_file)
      MyOtherKonfa.initialize_from_yaml(bool_file)

      expect(MyKonfa.get :my_var).to eq 'read from the yaml file'
      expect(MyOtherKonfa.get :my_var).to eq 'true'
    end
  end
end
