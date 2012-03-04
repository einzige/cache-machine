require 'spec_helper'

describe CacheMachine::Cache::TimestampBuilder do
  describe "::define_timestamp" do
    let(:key_part) { 0 }

    before :each do
      Cacher.define_timestamp :test_timestamp do
        key_part
      end
    end

    it "works" do
      Cacher.should respond_to :test_timestamp
      Object.should_not respond_to :test_timestamp
    end

    it "defines timestamp" do
      Time.stub("now").and_return 1
      Cacher.test_timestamp.should == "1"
    end

    it "returns value from cache" do
      CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp"))
      CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp_0_stamp"), {})
      Cacher.test_timestamp
      CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp"))
      CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp_0_stamp"), {})
      Cacher.test_timestamp
    end

    it "clears cache on key-update" do
      key_part = 1
      CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp"))
      CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp_1_stamp"), {})
      Cacher.test_timestamp
    end
  end
end
