require 'spec_helper'

describe CacheMachine::Cache::TimestampBuilder do
  describe "::define_timestamp" do
    before :each do
      Cacher.stamp = 0
      Cacher.define_timestamp(:test_timestamp) { stamp }
    end

    it "works" do
      Cacher.should respond_to :test_timestamp
      Object.should_not respond_to :test_timestamp
    end

    it "returns current time value if cache is clear" do
      Time.stub("now").and_return 1
      Cacher.test_timestamp.should == "1"
    end

    context "key" do
      it "works" do
        CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp"))
        CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp_0_stamp"), {})
        Cacher.test_timestamp
      end

      it "changes value" do
        Cacher.stamp = 1

        CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp"))
        CacheMachine::Cache::timestamps_adapter.should_receive(:fetch_timestamp).with(Cacher.timestamp_key_of("test_timestamp_1_stamp"), {})
        Cacher.test_timestamp
      end
    end

    it "returns value from cache" do
      Cacher.test_timestamp
      CacheMachine::Cache::timestamps_adapter.should_not_receive(:reset_timestamp)
      Cacher.test_timestamp
    end

    it "expires old timestamp" do
      Cacher.test_timestamp
      CacheMachine::Cache::timestamps_adapter.should_receive(:reset_timestamp).with("Cacher~test_timestamp~ts")
      CacheMachine::Cache::timestamps_adapter.should_receive(:reset_timestamp).with("Cacher~test_timestamp_0_stamp~ts")

      Cacher.stamp = 1
      Cacher.test_timestamp
    end
  end
end
