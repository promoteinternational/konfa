$: << File.join(File.dirname(File.dirname(__FILE__)), "lib")

require 'konfa'
require 'konfa/rspec'

class MyKonfa < Konfa::Base
  class << self
    def allowed_variables
      {
        :my_var_1 => 'default value 1',
        :my_var_2 => 'default value 2',
        :my_var_3 => 'default value 3',
      }
    end
  end
end

class MyOtherKonfa < Konfa::Base
  class << self
    def allowed_variables
      {
        :my_var_3 => 'default value 3',
        :my_var_4 => 'default value 4',
      }
    end
  end
end

describe Konfa::RSpec do
  include_context 'with konfa', MyKonfa

  context 'let_config' do
    it 'allows stubbing a particular variable' do
      let_config(:my_var_1, 'overriden value')

      expect(MyKonfa.get(:my_var_1)).to eq 'overriden value'
    end

    it 'leaves unstubbed variables' do
      let_config(:my_var_1, 'overriden value')

      expect(MyKonfa.get(:my_var_2)).to eq 'default value 2'

    end

    it 'raises exception if required variable does not exist' do
      expect {
        let_config(:do_not_exist, 'some value')
      }.to raise_error Konfa::UnsupportedVariableError
    end

    it 'allows overriding specified konfa instance' do
      let_config(:my_var_3, 'overridden value', MyOtherKonfa)

      expect(MyOtherKonfa.get(:my_var_3)).to eq 'overridden value'
    end

    it 'can be called repeatedly' do
      let_config(:my_var_1, 'overridden value 1')
      let_config(:my_var_2, 'overridden value 2')

      expect(MyKonfa.get(:my_var_1)).to eq 'overridden value 1'
      expect(MyKonfa.get(:my_var_2)).to eq 'overridden value 2'
      expect(MyKonfa.get(:my_var_3)).to eq 'default value 3'
    end

    it 'allows mixing calls to different classes' do
      let_config(:my_var_1, 'overridden value 1')
      let_config(:my_var_3, 'overridden value 3')
      let_config(:my_var_3, 'other overridden value 3', MyOtherKonfa)

      expect(MyKonfa.get(:my_var_1)).to eq 'overridden value 1'
      expect(MyKonfa.get(:my_var_3)).to eq 'overridden value 3'
      expect(MyOtherKonfa.get(:my_var_3)).to eq 'other overridden value 3'
    end
  end

  context 'with_config' do
    it 'accepts a hash of variables' do
      with_config({
        my_var_1: 'overridden 1',
        my_var_2: 'overridden 2',
      })

      expect(MyKonfa.get(:my_var_1)).to eq 'overridden 1'
      expect(MyKonfa.get(:my_var_2)).to eq 'overridden 2'
    end

    it 'leaves variables not specified' do
      with_config({
        my_var_1: 'overridden 1',
        my_var_2: 'overridden 2',
      })

      expect(MyKonfa.get(:my_var_1)).to eq 'overridden 1'
      expect(MyKonfa.get(:my_var_2)).to eq 'overridden 2'
      expect(MyKonfa.get(:my_var_3)).to eq 'default value 3'
    end

    it 'allows specify other konfa class' do
      with_config({
        my_var_3: 'overridden 3',
        my_var_4: 'overridden 4',
      }, MyOtherKonfa)

      expect(MyOtherKonfa.get(:my_var_3)).to eq 'overridden 3'
      expect(MyOtherKonfa.get(:my_var_4)).to eq 'overridden 4'
    end

    it 'raises exception if a variable do not exist' do
      expect {
        with_config({
          my_var_1: 'overridden 3',
          does_not_exist: 'overridden 4',
        })
      }.to raise_error Konfa::UnsupportedVariableError
    end
  end
end