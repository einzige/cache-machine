require "spec_helper"


if ENV["ADAPTER"] == 'redis'

  describe CacheMachine::Adapters::Redis do
    subject { CacheMachine::Cache::map_adapter }

    before :each do
      CacheMachine::Cache::Mapper.new do
        resource Cacher do
          collection :has_many_through_cacheables
        end
      end
    end

    describe "#association_ids" do
      let(:target) { Cacher.create(:name => 'foo') }
      let(:hmt1) { target.has_many_through_cacheables.create }
      let(:hmt2) { target.has_many_through_cacheables.create }

      before :each do
        hmt1 and hmt2
      end

      context "primary direction" do
        after :each do
          subject.association_ids(target, :has_many_through_cacheables).should =~ [hmt1.id, hmt2.id]
        end

        context "with clear cache" do
          it("returns ids of an association") {}
        end

        context "filled cache" do
          it "returns ids from cache if has already requested before" do
            subject.association_ids(target, :has_many_through_cacheables)
            subject.redis.should_receive(:smembers).and_return [hmt1.id, hmt2.id]
          end
        end
      end

      context "reverse direction" do
        it "works" do
          subject.association_ids(target.has_many_through_cacheables.first, :cachers).should == [target.id]
        end
      end
    end
  end
end