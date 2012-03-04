require 'spec_helper'

describe CacheMachine::Cache::ClassTimestamp do
  before :each do
    CacheMachine::Cache::Mapper.new do
      resource Cacher
    end
  end

  describe "#timestamp" do
    it "works" do
      Cacher.timestamp
    end

    it "expires when collection changed" do
      Cacher.should_receive(:reset_timestamp)
      Cacher.create
    end
  end

  describe "#reset_timestamp" do
    it "works" do
      old_timestamp = Cacher.timestamp
      Time.stub("now").and_return('9999')
      Cacher.create
      Cacher.timestamp.should_not == old_timestamp
    end
  end
end
