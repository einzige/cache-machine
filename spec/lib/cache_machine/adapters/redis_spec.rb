require "spec_helper"


if ENV["ADAPTER"] == 'redis'

  describe CacheMachine::Adapters::Redis do
    subject { CacheMachine::Cache::map_adapter }

    let(:cacher) { Cacher.create }

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
          subject.association_ids(target, :has_many_through_cacheables).should =~ [hmt1.id, hmt2.id].map(&:to_s)
        end

        context "with clear cache" do
          it("returns ids of an association") {}
        end

        context "filled cache" do
          it "returns ids from cache if has already requested before" do
            subject.association_ids(target, :has_many_through_cacheables)
            subject.redis.should_receive(:smembers).and_return [hmt1.id, hmt2.id].map(&:to_s)
          end
        end
      end

      context "reverse direction" do
        it "works" do
          subject.association_ids(target.has_many_through_cacheables.first, :cachers).should == [target.id]
        end
      end
    end

    describe "#reverse_association_ids" do
      let(:target) { cacher.has_many_through_cacheables.create }

      context "with clear cache" do
        it "returns ids of an association" do
          subject.reverse_association_ids(Cacher, :has_many_through_cacheables, target).should == [cacher.id.to_s]
        end
      end

      context "filled cache" do
        it "returns ids from cache if has already requested before" do
          subject.reverse_association_ids(Cacher, :has_many_through_cacheables, target)
          target.should_not_receive(:cache_map_ids)
          subject.reverse_association_ids(Cacher, :has_many_through_cacheables, target)
        end
      end
    end

    describe "#append_id_to_map" do
      let(:key) { subject.get_map_key(cacher, :joins) }

      it "works" do
        ::Redis.any_instance.should_receive(:sadd).with(key, 1)
        subject.append_id_to_map(cacher, :joins, 1)
      end
    end

    describe "#append_id_to_reverse_map" do
      let(:join) { cacher.joins.create }
      let(:key) { subject.get_reverse_map_key(Cacher, :joins, join) }

      it "works" do
        ::Redis.any_instance.should_receive(:sadd).with(key, 1)
        subject.append_id_to_reverse_map(Cacher, :joins, join, 1)
      end
    end

    describe "#fetch" do
      let(:cache_key) { 'test' }
      let(:key) { subject.get_content_key(cache_key) }

      it "works" do
        ::Redis.any_instance.should_receive(:get).with(key)
        subject.fetch(cache_key)
      end
    end

    describe "#delete" do
      it "works" do
        ::Redis.any_instance.should_receive(:del).with('test')
        subject.delete('test')
      end
    end

    describe "#delete_content" do
      let(:content_key) { 'test' }
      let(:key) { subject.get_content_key(content_key) }

      it "works" do
        ::Redis.any_instance.should_receive(:del).with(key)
        subject.delete_content(content_key)
      end
    end

    describe "#reset_timestamp" do
      let(:timestamp) { 'test' }
      let(:key) { subject.get_timestamp_key(timestamp) }

      it "works" do
        ::Redis.any_instance.should_receive(:del).with(key)
        subject.reset_timestamp(timestamp)
      end
    end
  end
end