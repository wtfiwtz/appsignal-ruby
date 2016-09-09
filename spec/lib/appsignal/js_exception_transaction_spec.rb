describe Appsignal::JSExceptionTransaction do
  before { SecureRandom.stub(:uuid => '123abc') }

  let!(:transaction) { Appsignal::JSExceptionTransaction.new(data) }
  let(:data) do
    {
      'name'        => 'TypeError',
      'message'     => 'foo is not a valid method',
      'action'      => 'ExceptionIncidentComponent',
      'path'        => 'foo.bar/moo',
      'environment' => 'development',
      'backtrace'   => [
        'foo.bar/js:11:1',
        'foo.bar/js:22:2',
      ],
      'tags'        => [
        'tag1'
      ]
    }
  end

  describe "#initialize" do
    it "should call all required methods" do
      expect( Appsignal::Extension ).to receive(:start_transaction).with('123abc', 'frontend', 0).and_return(1)

      expect( transaction ).to receive(:set_action)
      expect( transaction ).to receive(:set_metadata)
      expect( transaction ).to receive(:set_error)
      expect( transaction ).to receive(:set_sample_data)

      transaction.send :initialize, data

      expect( transaction.ext ).not_to be_nil
    end
  end

  describe "#set_base_data" do
    it "should call `Appsignal::Extension.set_transaction_basedata`" do
      expect( transaction.ext ).to receive(:set_action).with(
        'ExceptionIncidentComponent'
      )

      transaction.set_action
    end
  end

  describe "#set_metadata" do
   it "should call `Appsignal::Extension.set_transaction_metadata`" do
     expect( transaction.ext ).to receive(:set_metadata).with(
       'path',
       'foo.bar/moo'
     )

     transaction.set_metadata
   end
  end

  describe "#set_error" do
   it "should call `Appsignal::Extension.set_transaction_error`" do
     expect( transaction.ext ).to receive(:set_error).with(
       'TypeError',
       'foo is not a valid method',
       "[\"foo.bar/js:11:1\",\"foo.bar/js:22:2\"]"
     )

     transaction.set_error
   end
  end

  describe "#set_sample_data" do
   it "should call `Appsignal::Extension.set_transaction_error_data`" do
     expect( transaction.ext ).to receive(:set_sample_data).with(
      'tags',
      '["tag1"]'
     )

     transaction.set_sample_data
   end
  end

  describe "#complete!" do
    it "should call all required methods" do
      expect( transaction.ext ).to receive(:finish)
      expect( transaction.ext ).to receive(:complete)
      transaction.complete!
    end
  end
end
