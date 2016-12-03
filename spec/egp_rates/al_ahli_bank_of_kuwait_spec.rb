# frozen_string_literal: true
describe EGPRates::AlAhliBankOfKuwait do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    expect(bank.exchange_rates).to include(:buy, :sell)
    expect(bank.exchange_rates[:buy].size).to eq 8
    expect(bank.exchange_rates[:sell].size).to eq 8
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :AlAhliBankOfKuwait
      expect(bank.instance_variable_get(:@uri)).to be_a URI
    end
  end

  describe '#exchange_rates' do
    it 'calls #parse with #raw_exchange_rates' do
      expect(bank).to receive(:raw_exchange_rates)
      expect(bank).to receive(:parse)
      bank.exchange_rates
    end
  end

  describe '#raw_exchange_rates' do
    it 'raises ResponseError unless Net::HTTPSuccess', :no_vcr do
      stub_request(:get, /.*abkegypt.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*abkegypt.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        EGPRates::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 8 rows',
       vcr: { cassette_name: :AlAhliBankOfKuwait } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 8
    end
  end

  describe '#parse', vcr: { cassette_name: :AlAhliBankOfKuwait } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to match(
        AED: 4.9687,
        CHF: 18.0016,
        EUR: 19.3979,
        GBP: 22.891,
        JPY: 0.1603,
        KWD: 59.8361,
        SAR: 4.8664,
        USD: 18.25
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to match(
        AED: 4.8326,
        CHF: 17.4259,
        EUR: 18.7902,
        GBP: 22.1875,
        JPY: 0.1546,
        KWD: 58.1776,
        SAR: 4.7323,
        USD: 17.75
      )
    end
  end
end
