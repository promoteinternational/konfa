require 'spec_helper'

describe Konfa::Initializer do
  let(:bool_file)  { File.expand_path("../../support/bool_config.yaml", __FILE__) }
  let(:good_file)  { File.expand_path("../../support/good_config.yaml", __FILE__) }
  let(:bad_file)   { File.expand_path("../../support/bad_config.yaml", __FILE__) }
  let(:not_yaml)   { File.expand_path("../../support/not_yaml.yaml", __FILE__) }
  let(:empty_file) { File.expand_path("../../support/empty.yaml", __FILE__) }
  let(:array_file) { File.expand_path("../../support/array.yaml", __FILE__) }

  subject do
    dummy = Class.new do
      include Konfa::Initializer
    end
    allow(dummy).to receive(:store)
    allow(dummy).to receive(:dump)
    dummy
  end

  context "#init_with_yaml" do
    it 'calls store with data from yaml' do
      expect(subject).to receive(:store).with('my_var', 'read from the yaml file')
      subject.init_with_yaml(good_file)
    end

    it "raises an exception if file does not contain YAML" do
      expect {
        subject.init_with_yaml(not_yaml)
      }.to raise_error(Konfa::InitializationError)
    end

    it "raises an exception if file does not key/value pairs" do
      expect {
        subject.init_with_yaml(array_file)
      }.to raise_error(Konfa::InitializationError)
    end

    it "is possible to load an empty file" do
      expect(subject).to_not receive(:store)
      expect {
        subject.init_with_yaml(empty_file)
      }.not_to raise_error
    end
  end

  context "#init_with_env" do
    before do
      allow(subject).to receive(:env_variable_prefix).and_return('PREF_')
    end

    it "can be initialized with prefixed environment variables" do
      begin
        ENV["PREF_MY_VAR"] = 'set from env'
        ENV["IGNORE_MY_VAR"]  = 'should be ignored'

        expect(subject).to receive(:store).with('my_var', 'set from env')
        expect {
          subject.init_with_env
        }.not_to raise_error
      ensure
        ENV.delete("PREF_MY_VAR")
        ENV.delete("IGNORE_MY_VAR")
      end
    end
  end

end
