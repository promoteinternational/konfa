require 'spec_helper'

describe Konfa::Initializer do
  let(:bool_file)  { File.expand_path("../../support/bool_config.yaml", __FILE__) }
  let(:good_file)  { File.expand_path("../../support/good_config.yaml", __FILE__) }
  let(:bad_file)   { File.expand_path("../../support/bad_config.yaml", __FILE__) }
  let(:not_yaml)   { File.expand_path("../../support/not_yaml.yaml", __FILE__) }
  let(:empty_file) { File.expand_path("../../support/empty.yaml", __FILE__) }
  let(:array_file) { File.expand_path("../../support/array.yaml", __FILE__) }

  # FIXME duplicated in konfa_spec
  before(:each) do
    MyTestKonfa.reinit
    MyTestKonfa.send(:initializer=, nil)
    MyTestKonfa.send(:configuration=, nil)
    MyOtherTestKonfa.reinit
    MyOtherTestKonfa.send(:initializer=, nil)
    MyOtherTestKonfa.send(:configuration=, nil)
  end

  context "#init_with_yaml" do
    it "returns parsed values" do
      expect(MyTestKonfa.init_with_yaml(good_file)).to eq MyTestKonfa.dump
    end

    it "raises an exception if file does not contain YAML" do
      expect {
        MyTestKonfa.init_with_yaml(not_yaml)
      }.to raise_error(Konfa::InitializationError)
    end

    it "raises an exception if file does not key/value pairs" do
      expect {
        MyTestKonfa.init_with_yaml(array_file)
      }.to raise_error(Konfa::InitializationError)
    end

    it "requires all keys in YAML file to be defined in config class by default" do
      expect {
        MyTestKonfa.init_with_yaml(bad_file)
      }.to raise_error Konfa::UnsupportedVariableError
    end

    it "handles Ruby's implicit type conversion" do
      MyTestKonfa.init_with_yaml(bool_file)
      expect(MyTestKonfa.get :my_var).to be_a(String)
      expect(MyTestKonfa.get :my_var).to eq 'true'
    end

    context "when used as an initializer" do
      it "configures variables from a YAML file" do
        expect {
          MyTestKonfa.init_with(:yaml, good_file).init
        }.to_not raise_error
        expect(MyTestKonfa.get :my_var).to eq 'read from the yaml file'
      end

      it "is possible to load an empty file" do
        expect {
          MyTestKonfa.init_with(:yaml, empty_file).init
        }.not_to raise_error
        expect(MyTestKonfa.get :my_var).to eq 'default value'
      end
    end
  end

  context "#init_with_env" do

    it "prefixes environment variables" do
      expect(MyTestKonfa.env_variable_prefix).to eq 'PREF_'
    end

    it "can be initialized with environment variables" do
      begin
        ENV["PREF_MY_VAR"] = 'set from env'
        ENV["IGNORE_MY_VAR"]  = 'should be ignored'

        expect {
          MyTestKonfa.init_with_env
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
        MyTestKonfa.init_with_env
      }.to raise_error Konfa::UnsupportedVariableError

      ENV.delete("PREF_BAD_VARIABLE")
    end
  end

end
