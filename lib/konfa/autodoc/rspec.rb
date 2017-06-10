module Konfa
  module AutoDoc
    module RSpec
      shared_examples 'an Konfa::AutoDoc::Formatter subclass' do
        let(:konfa_class) { double("KonfaClass") }

        subject { described_class.new(konfa_class) }

        it { is_expected.to be_kind_of Konfa::AutoDoc::Formatter }
        it { is_expected.to respond_to :konfa_class }
        it { is_expected.to respond_to :version }

        it 'sets class as r/o accessor' do
          expect(subject.konfa_class).to be konfa_class
        end

        it 'sets version as r/w accessor' do
          expect(subject).to respond_to :version=
        end

        context '#generate' do
          let(:autodoc_instance) { double }

          before(:each) do
            allow(Konfa::AutoDoc::Parser).to receive(:new).with(subject.konfa_class).and_return autodoc_instance
            allow(subject).to receive(:format).and_return "something formatted"
            allow(autodoc_instance).to receive(:parse).and_return "something parsed"
          end

          after(:each) do
            subject.generate
          end

          it 'constructs a parser with konfa_class' do
            expect(Konfa::AutoDoc::Parser).to receive(:new).with(subject.konfa_class).and_return autodoc_instance
          end

          it 'passes the parsed value to #format' do
            expect(subject).to receive(:format).with("something parsed")
          end
        end
      end
    end
  end
end
