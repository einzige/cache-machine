require "spec_helper"

if ENV["ADAPTER"] != 'redis'

  describe CacheMachine::Adapters::Rails do
    subject { CacheMachine::Cache::map_adapter }

    let(:cacher) { Cacher.create }

    before :each do
      CacheMachine::Cache::Mapper.new do
        resource Cacher do
          collection :has_many_cacheables
        end
      end
    end

    describe "#append_id_to_map" do
      let(:key) { subject.get_map_key(cacher, :joins) }

      it "works" do
        ::Rails.cache.should_receive(:write).with(key, [1])
        subject.append_id_to_map(cacher, :joins, 1)
      end

      it "appends keys" do
        subject.append_id_to_map(cacher, :joins, 1)
        ::Rails.cache.should_receive(:write).with(key, [1, 2])
        subject.append_id_to_map(cacher, :joins, 2)
      end

      it "does not append duplicate key" do
        subject.append_id_to_map(cacher, :joins, 1)
        ::Rails.cache.should_receive(:write).with(key, [1])
        subject.append_id_to_map(cacher, :joins, 1)
      end
    end

    describe "#append_id_to_reverse_map" do
      let(:join) { cacher.joins.create }
      let(:key) { subject.get_reverse_map_key(Cacher, :joins, join) }

      it "works" do
        ::Rails.cache.should_receive(:write).with(key, [1])
        subject.append_id_to_reverse_map(Cacher, :joins, join, 1)
      end

      it "appends keys" do
        subject.append_id_to_reverse_map(Cacher, :joins, join, 1)
        ::Rails.cache.should_receive(:write).with(key, [1, 2])
        subject.append_id_to_reverse_map(Cacher, :joins, join, 2)
      end

      it "does not append duplicate key" do
        subject.append_id_to_reverse_map(Cacher, :joins, join, 1)
        ::Rails.cache.should_receive(:write).with(key, [1])
        subject.append_id_to_reverse_map(Cacher, :joins, join, 1)
      end
    end

    describe "#association_ids" do
      let(:cacher) { Cacher.create(:name => 'foo') }

      before :each do
        Rails.cache.clear
        cacher.has_many_cacheables.create :id => 1
        cacher.has_many_cacheables.create :id => 2
      end

      context "with clear cache" do
        it("returns ids of an association") do
          subject.association_ids(cacher, :has_many_cacheables).should =~ [1, 2]
        end
      end

      context "filled cache" do
        it "returns ids from cache if has already requested before" do
          Rails.cache.should_receive(:fetch).and_return [1, 2]
          subject.association_ids(cacher, :has_many_cacheables).should =~ [1, 2]
        end
      end
    end

    describe "#fetch" do
      let(:cache_key) { 'test' }
      let(:key) { subject.get_content_key(cache_key) }

      it "works" do
        ::Rails.cache.should_receive(:fetch).with(key, {})
        subject.fetch(cache_key) { 'cached' }
      end
    end

    describe "#fetch_timestamp" do
      let(:cache_key) { 'test' }
      let(:key) { subject.get_timestamp_key(cache_key) }

      it "works" do
        ::Rails.cache.should_receive(:fetch).with(key, {})
        subject.fetch_timestamp(cache_key) { 'cached' }
      end
    end

    describe "#delete" do
      it "works" do
        ::Rails.cache.should_receive(:delete).with('test')
        subject.delete('test')
      end
    end

    describe "#delete_content" do
      let(:content_key) { 'test' }
      let(:key) { subject.get_content_key(content_key) }

      it "works" do
        ::Rails.cache.should_receive(:delete).with(key)
        subject.delete_content(content_key)
      end
    end

    describe "#reset_timestamp" do
      let(:timestamp) { 'test' }
      let(:key) { subject.get_timestamp_key(timestamp) }

      it "works" do
        ::Rails.cache.should_receive(:delete).with(key)
        subject.reset_timestamp(timestamp)
      end
    end

    describe "#reverse_association_ids" do
      let(:target) { cacher.has_many_cacheables.create }

      context "with clear cache" do
        it "returns ids of an association" do
          subject.reverse_association_ids(Cacher, :has_many_cacheables, target).should == [cacher.id]
        end
      end

      context "filled cache" do
        it "returns ids from cache if has already requested before" do
          subject.reverse_association_ids(Cacher, :has_many_cacheables, target)
          target.should_not_receive(:cache_map_ids)
          subject.reverse_association_ids(Cacher, :has_many_cacheables, target)
        end
      end
    end
  end
end