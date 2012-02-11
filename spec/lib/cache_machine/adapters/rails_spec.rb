require "spec_helper"

if ENV["ADAPTER"] != 'redis'

  describe CacheMachine::Adapters::Rails do
    subject { CacheMachine::Cache::map_adapter }

    describe "#association_ids" do
      let(:target) { Cacher.create(:name => 'foo') }

      before :each do
        Rails.cache.clear
        target.has_many_cacheables.create :id => 1
        target.has_many_cacheables.create :id => 2
      end

      context "with clear cache" do
        it("returns ids of an association") do
          subject.association_ids(target, :has_many_cacheables).should =~ ["1", "2"]
        end
      end

      context "filled cache" do
        it "returns ids from cache if has already requested before" do
          Rails.cache.should_receive(:fetch).and_return [1, 2]
          subject.association_ids(target, :has_many_cacheables).should =~ [1, 2]
        end
      end
    end
  end
end