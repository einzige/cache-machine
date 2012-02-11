require "spec_helper"


if ENV["ADAPTER"] == 'redis'

  describe CacheMachine::Adapters::Redis do
    subject { CacheMachine::Cache::map_adapter }

    describe "#association_ids" do
      let(:target) { Cacher.create(:name => 'foo') }

      before :each do
        target.has_many_cacheables.create :id => 1
        target.has_many_cacheables.create :id => 2
      end

      after :each do
        subject.association_ids(target, :has_many_cacheables).should =~ ["1","2"]
      end

      context "with clear cache" do
        it("returns ids of an association") {}
      end

      context "filled cache" do
        it "returns ids from cache if has already requested before" do
          subject.redis.should_receive(:smembers).and_return ["1", "2"]
        end
      end
    end
  end
end