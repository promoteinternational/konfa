require_relative 'spec_helper'

class MyTestKonfa < Konfa::Base
  class << self
    def env_variable_prefix
      'PREF_'
    end

    def allowed_variables
      {
        :my_var         => 'default value',
        :default_is_nil => nil,
        :foo => nil,
        :bar => nil,
        :baz => nil
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
  let(:bool_file) { File.expand_path('../support/bool_config.yaml', __FILE__) }
  let(:good_file) { File.expand_path('../support/good_config.yaml', __FILE__) }
  let(:initial_file) { File.expand_path('../support/initial_config.yaml', __FILE__) }
  let(:overrides_file) { File.expand_path('../support/overrides.yaml', __FILE__) }

  before(:each) do
    MyTestKonfa.deprecation_warnings = false
    MyTestKonfa.reinit
    MyTestKonfa.send(:initializer=, nil)
    MyTestKonfa.send(:configuration=, nil)
    MyOtherTestKonfa.reinit
    MyOtherTestKonfa.send(:initializer=, nil)
    MyOtherTestKonfa.send(:configuration=, nil)
  end

  describe '.variables' do
    it 'can list available configuration variables' do
      expect(MyTestKonfa.variables).to be_kind_of Array
    end

    it 'presents all variable keys as symbols' do
      expect(MyTestKonfa.variables.all? {|v| v.kind_of? Symbol }).to be true
    end
  end

  describe '.dump' do
    it 'can dump all existing variables and values' do
      expect(MyTestKonfa.dump).to be_kind_of Hash
      expect(MyTestKonfa.dump.keys).to eq MyTestKonfa.variables
    end

    it 'dupes the current state' do
      dumped = MyTestKonfa.dump
      expect(dumped).not_to equal MyTestKonfa.dump
    end
  end

  context 'class configuration' do
    it 'does not provide direct access to variable store' do
      expect {
        MyTestKonfa.configuration
      }.to raise_error(NoMethodError)
    end
  end

  describe '.get' do
    it 'all variables can be accessed' do
      MyTestKonfa.variables.each do |variable|
        expect {
          MyTestKonfa.get(variable)
        }.not_to raise_error
      end
    end

    it 'raises an exception if unknown configuration variable is accessed' do
      expect {
        MyTestKonfa.get :_this_is_totally_wrong
      }.to raise_error Konfa::UnsupportedVariableError
    end
  end

  describe '.get!' do
    it 'can access a variable that is not nil' do
      expect(MyTestKonfa.get!(:my_var)).to eq 'default value'
    end

    it 'considers an empty string valid' do
      MyTestKonfa.with_config(my_var: '') do
        expect(MyTestKonfa.get!(:my_var)).to eq ''
      end
    end

    it "considers the string 'nil' valid" do
      MyTestKonfa.with_config(my_var: 'nil') do
        expect(MyTestKonfa.get!(:my_var)).to eq 'nil'
      end
    end

    it 'raises an error if the variable is nil' do
      expect {
        MyTestKonfa.get! :default_is_nil
      }.to raise_error Konfa::NilVariableError
    end
  end

  describe '.init' do
    before(:each) do
      MyTestKonfa.init_with(:yaml, good_file)
    end

    it 'executes initialization method on first call to configuration' do
      expect(MyTestKonfa).to receive(:init_with_yaml).once.with(good_file).and_call_original
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

    context 'without initialize method' do
      before do
        MyTestKonfa.send(:initializer=, nil)
      end

      it 'should not call #after_initialize' do
        expect(MyTestKonfa).to_not receive(:after_initialize)
        MyTestKonfa.init
      end
    end

    context 'when init? returns false' do
      before :each do
        allow(MyTestKonfa).to receive(:init?).and_return(false)
      end

      it 'should not alter initialized' do
        expect {
          MyTestKonfa.init
        }.to_not change(MyTestKonfa, :initialized)
      end

      it 'should not call initializer method' do
        expect(MyTestKonfa).to_not receive(:init_with_yaml)
        MyTestKonfa.init
      end

      it 'should not call after_initialize' do
        expect(MyTestKonfa).to_not receive(:after_initialize)
        MyTestKonfa.init
      end
    end
  end

  describe '.init_with' do
    it 'should set initializer with prefix' do
      expect {
        MyTestKonfa.init_with(:something, 'arg')
      }.to change {
        MyTestKonfa.send(:initializer)
      }.from(nil).to([:init_with_something, 'arg'])
    end

    it 'should return self' do
      expect(MyTestKonfa.init_with(:something)).to eq(MyTestKonfa)
    end
  end

  describe '.reinit' do
    it 'sets initialized to false' do
      expect(MyTestKonfa).to receive(:initialized=).with(false)
      MyTestKonfa.reinit
    end
  end

  describe '.with_config' do

    let(:test_value) { 'my test value' }

    before(:each) do
      MyTestKonfa.send(:store, :my_var, test_value)
    end

    it 'prevents existing values to be over written' do
      MyTestKonfa.with_config(my_var: 'blah') do
        expect(MyTestKonfa.get :my_var).to eq 'blah'
      end

      expect(MyTestKonfa.get :my_var).to be test_value
    end

    it 'drops any new values set in block' do
      MyTestKonfa.with_config do
        MyTestKonfa.send(:store, :my_var, 'blah')
        expect(MyTestKonfa.get :my_var).to eq 'blah'
      end

      expect(MyTestKonfa.get :my_var).to be test_value
    end

    it 'works even if an exception is raised' do
      expect {
        MyTestKonfa.with_config(my_var: 'blah') do
          expect(MyTestKonfa.get :my_var).to eq 'blah'
          raise Exception.new('This is en error')
        end
      }.to raise_error(Exception)

      expect(MyTestKonfa.get :my_var).to be test_value
    end

    it 'works with multiple values' do
      MyTestKonfa.with_config(my_var: 'my new value', default_is_nil: 'a val') do
        expect(MyTestKonfa.get :my_var).to eq 'my new value'
        expect(MyTestKonfa.get :default_is_nil).to eq 'a val'
      end
      expect(MyTestKonfa.get :my_var).to be test_value
      expect(MyTestKonfa.get :default_is_nil).not_to eq 'a val'
    end

    it 'returns the result of the block' do
      retval = MyTestKonfa.with_config(:my_var => 'my new value') do
        MyTestKonfa.get(:my_var)
      end

      expect(MyTestKonfa.get :my_var).to be test_value
      expect(retval).to eq 'my new value'
    end
  end

  describe '.true? and #false?' do
    it 'implements a shorthand for boolean operations' do
      expect(MyTestKonfa).to respond_to(:'true?')
      expect(MyTestKonfa).to respond_to(:'false?')
    end

    it 'raises an exception for true? if variable does not exist' do
      expect {
        MyTestKonfa.true?(:does_not_exist)
      }.to raise_error(Konfa::UnsupportedVariableError)
    end

    it 'raises an exception for false? if variable does not exist' do
      expect {
        MyTestKonfa.false?(:does_not_exist)
      }.to raise_error(Konfa::UnsupportedVariableError)
    end

    it 'considers values 1, yes or true to be true' do
      ['true', '1', 'yes', 'on'].each do |truthy|
        MyTestKonfa.send(:store, :my_var, truthy)

        expect(MyTestKonfa.true? :my_var).to be true
        expect(MyTestKonfa.false? :my_var).to be false
      end
    end

    it 'considers nil or any value other than 1, yes or true to be false' do
      [nil, '0', 'false', 'blah', 'NOT TRUE'].each do |falsy|
        MyTestKonfa.send(:store, :my_var, falsy)

        expect(MyTestKonfa.true? :my_var).to be false
        expect(MyTestKonfa.false? :my_var).to be true
      end
    end

    it 'is case insensitive' do
      ['True', 'trUe', 'yEs', 'YES', 'oN'].each do |truthy|
        MyTestKonfa.send(:store, :my_var, truthy)

        expect(MyTestKonfa.true? :my_var).to be true
        expect(MyTestKonfa.false? :my_var).to be false
      end
    end

    it 'ignores whitespace' do
      ['    true', ' on ', '1    '].each do |truthy|
        MyTestKonfa.send(:store, :my_var, truthy)

        expect(MyTestKonfa.true? :my_var).to be true
        expect(MyTestKonfa.false? :my_var).to be false
      end
    end
  end

  context 'default values' do
    it 'uses value from allowed_variables by default' do
      expect(MyTestKonfa.get(:my_var)).to eq 'default value'
    end

    it 'allows nil as default value' do
      expect(MyTestKonfa.get(:default_is_nil)).to be nil
    end
  end

  describe '.store' do
    it 'raises an error if trying to store a non-declared variable' do
      expect {
        MyTestKonfa.send(:store, 'invalid_variable', 'data')
      }.to raise_error Konfa::UnsupportedVariableError
    end

    it 'stores numbers as strings' do
      MyTestKonfa.send(:store, :my_var, 123)
      expect(MyTestKonfa.get(:my_var)).to eq('123')
    end

    it 'stores booleans as strings' do
      MyTestKonfa.send(:store, :my_var, true)
      expect(MyTestKonfa.get(:my_var)).to eq('true')
      MyTestKonfa.send(:store, :my_var, false)
      expect(MyTestKonfa.get(:my_var)).to eq('false')
    end
  end

  context 'when declaring multiple sub classes' do
    it 'is possible to initialize them both from env' do
      begin
        ENV['PREF_MY_VAR']       = 'belongs to MyTestKonfa'
        ENV['OTHER_PREF_MY_VAR'] = 'belongs to MyOtherTestKonfa'

        expect {
          MyTestKonfa.init_with(:env).init
          MyOtherTestKonfa.init_with(:env).init
        }.not_to raise_error

        expect(MyTestKonfa.get :my_var).to eq 'belongs to MyTestKonfa'
        expect(MyOtherTestKonfa.get :my_var).to eq 'belongs to MyOtherTestKonfa'
      ensure
        ENV.delete('PREF_MY_VAR')
        ENV.delete('OTHER_PREF_MY_VAR')
      end
    end

    it 'is possible to initialize them both from config' do
      MyTestKonfa.init_with(:yaml, good_file).init
      MyOtherTestKonfa.init_with(:yaml, bool_file).init

      expect(MyTestKonfa.get :my_var).to eq 'read from the yaml file'
      expect(MyOtherTestKonfa.get :my_var).to eq 'true'
    end
  end

  describe '.read_from' do
    subject { MyTestKonfa.read_from(initializer, good_file) }

    context 'valid initializer' do
      let(:initializer) { :yaml }

      it { is_expected.to eq MyTestKonfa }

      it 'calls the initializer' do
        expect(MyTestKonfa).to receive(:init_with_yaml).with(good_file)
        subject
      end
    end

    context 'multiple config files' do
      context 'with multiple calls' do
        it 'merges config vars' do
          MyTestKonfa.read_from(:yaml, initial_file)
          MyTestKonfa.read_from(:yaml, overrides_file)

          expect(MyTestKonfa.dump).to include({
            foo: 'overrides initial config foo var',
            bar: 'bar',
            baz: 'baz'
          })
        end

        it 'overrides configs in the order it is called' do
          MyTestKonfa.read_from(:yaml, overrides_file)
          MyTestKonfa.read_from(:yaml, initial_file)

          expect(MyTestKonfa.dump).to include({
            foo: 'foo',
            bar: 'bar',
            baz: 'baz'
          })
        end
      end

      context 'when called with multiple files' do
        it 'merges config vars' do
          MyTestKonfa.read_from(:yaml, initial_file, overrides_file)

          expect(MyTestKonfa.dump).to include({
            foo: 'overrides initial config foo var',
            bar: 'bar',
            baz: 'baz'
          })
        end

        it 'overrides according to files argument order' do
          MyTestKonfa.read_from(:yaml, overrides_file, initial_file)

          expect(MyTestKonfa.dump).to include({
            foo: 'foo',
            bar: 'bar',
            baz: 'baz'
          })
        end
      end
    end

    context 'invalid initializer' do
      let(:initializer) { :foobar }

      it 'raises error' do
        expect {
          subject
        }.to raise_error(Konfa::UnsupportedInitializerError)
      end
    end
  end

  describe '.initialize!' do
    it 'sets initialized state' do
      MyTestKonfa.read_from(:yaml, good_file)

      expect {
        MyTestKonfa.initialize!
      }.to change { MyTestKonfa.initialized? }.from(false).to(true)
    end

    it 'calls after_initialize' do
      MyTestKonfa.read_from(:yaml, good_file)

      expect(MyTestKonfa).to receive(:after_initialize)

      MyTestKonfa.initialize!
    end

    it 'raises error when already initialized' do
      MyTestKonfa.read_from(:yaml, initial_file).initialize!

      expect {
        MyTestKonfa.initialize!
      }.to raise_error(Konfa::AlreadyInitializedError)
    end
  end

  describe '.initialized?' do
    it 'is true when initialized' do
      MyTestKonfa.read_from(:yaml, good_file).initialize!

      expect(MyTestKonfa).to be_initialized
    end

    it 'is false when not initialized' do
      MyTestKonfa.read_from(:yaml, good_file)

      expect(MyTestKonfa).not_to be_initialized
    end
  end
end
