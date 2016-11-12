# frozen_string_literal: true
describe Bank::CBE do
  subject(:bank) { described_class.new }

  it 'Live Testing', :live do
    # expect(bank.exchange_rates).to include(:buy, :sell)
  end

  describe '.new' do
    it 'initialize instance variables' do
      expect(bank.sym).to eq :CBE
      expect(bank.instance_variable_get(:@uri)).to be_a URI
    end
  end

  describe '#exchange_rates', vcr: { cassette_name: :CBE } do
    it 'calls #parse with #raw_exchange_rates' do
      expect(bank).to receive(:raw_exchange_rates)
      expect(bank).to receive(:parse)
      bank.exchange_rates
    end
  end

  describe '#raw_exchange_rates' do
    it 'raises ResponseError unless Net::HTTPSuccess', :no_vcr do
      stub_request(:get, /.*cbe.*/).to_return(body: '', status: 500)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        Bank::ResponseError, '500'
    end

    it 'raises ResponseError if HTML structure changed', :no_vcr do
      stub_request(:get, /.*cbe.*/).to_return(body: '', status: 200)
      expect { bank.send(:raw_exchange_rates) }.to raise_error\
        Bank::ResponseError, 'Unknown HTML'
    end

    it 'returns <#Enumerator::Lazy> of 9 rows', vcr: { cassette_name: :CBE } do
      lazy_enumerator = bank.send(:raw_exchange_rates)
      expect(lazy_enumerator).to be_a Enumerator::Lazy
      expect(lazy_enumerator.size).to eq 9
    end
  end

  describe '#currency_symbol' do
    %w(US Euro Pound Swiss Japanese Saudi Kuwait UAE Chinese).each do |currency|
      it "returns currency :SYM for #{currency}" do
        symbols = %i(USD EUR GBP CHF JPY SAR KWD AED CNY)
        expect(symbols).to include(bank.send(:currency_symbol, currency))
      end
    end

    it 'raises ResponseError when Unknown Currency' do
      expect { bank.send(:currency_symbol, 'Egyptian pound') }.to raise_error\
        Bank::ResponseError, 'Unknown currency Egyptian pound'
    end
  end

  describe '#parse', vcr: { cassette_name: :CBE } do
    let(:raw_data) { bank.send(:raw_exchange_rates) }

    it 'returns sell: hash of selling prices' do
      expect(bank.send(:parse, raw_data)[:sell]).to include(
        USD: 17.0863,
        EUR: 18.6155,
        GBP: 21.2365,
        CHF: 17.3096,
        JPY: 16.0014,
        SAR: 4.5562,
        KWD: 56.3718,
        AED: 4.6524,
        CNY: 2.5138
      )
    end

    it 'returns buy: hash of buying prices' do
      expect(bank.send(:parse, raw_data)[:buy]).to include(
        USD: 16.354,
        EUR: 17.8111,
        GBP: 20.3231,
        CHF: 16.551,
        JPY: 15.3113,
        SAR: 4.3603,
        KWD: 53.8492,
        AED: 4.4518,
        CNY: 2.4052
      )
    end
  end
end