require 'spec_helper'

describe CacheMachine::Cache::Resource do

  let(:cacher) { cacher = Cacher.create }
  let(:join)   { cacher.joins.create    }
  let(:hm)     { cacher.has_many_cacheables.create }
  let(:hmt)    { HasManyThroughCacheable.create(:cachers => [cacher]) }
  let(:phm)    { cacher.polymorphics.create }

  before :each do
    CacheMachine::Cache::Mapper.new do
      resource Cacher do
        collection :joins do
          member :one
          member :two
        end
        collection :has_many_through_cacheables
        collection :has_many_cacheables
        collection :polymorphics
      end
    end
  end

  describe "::define_timestamp" do
    before :each do
      Cacher.define_timestamp :test_timestamp
    end

    it "works" do
      cacher.should respond_to :test_timestamp
    end
  end

  describe "#association_ids" do
    it "works" do
      join
      cacher.association_ids(:joins).should == [join.id]
    end
  end

  describe "#associated_from_cache" do
    it "works" do
      hmt
      cacher.associated_from_cache(:has_many_through_cacheables).should == [hmt]
      cacher.associated_from_cache(:has_many_through_cacheables).should == [hmt]
    end
  end

  describe "#fetch_cache_of" do
    it "works" do
      cacher.fetch_cache_of(:has_many_cacheables) { 'cached' }.should == 'cached'
      cacher.fetch_cache_of(:has_many_cacheables) { 'non-cached' }.should == 'cached'
      hm
      cacher.fetch_cache_of(:has_many_cacheables) { 'updated' }.should == 'updated'
    end

    context "with timestamps" do
      it "works" do
        cacher.fetch_cache_of(:has_many_cacheables, :timestamp => lambda { 'test-1' }) { 'cached' }.should == 'cached'
        cacher.fetch_cache_of(:has_many_cacheables, :timestamp => lambda { 'test-1' }) { 'non-cached' }.should == 'cached'
        cacher.fetch_cache_of(:has_many_cacheables, :timestamp => lambda { 'test-2' }) { 'cached-2' }.should == 'cached-2'
      end

      it "updates when collection changed" do
        cacher.fetch_cache_of(:has_many_cacheables, :timestamp => lambda { 'test' }) { 'cached' }.should == 'cached'
        hm
        Time.stub("now").and_return('another time comes')
        cacher.fetch_cache_of(:has_many_cacheables, :timestamp => lambda { 'test' }) { 'updated' }.should == 'updated'
      end
    end
  end

  describe "#delete_cache_of_only" do
    it "works" do
      cacher.fetch_cache_of(:test) { 'cached' }
      cacher.delete_cache_of_only(:test)
      cacher.fetch_cache_of(:test) { 'updated' }.should == 'updated'
    end
  end

  describe "#delete_cache_of" do
    context "on collection member" do
      it "works" do
        HasManyCacheable.should_receive(:reset_resource_cache).once.with(cacher, :has_many_cacheables)
        cacher.delete_cache_of(:has_many_cacheables)
      end
    end

    context "on virtual member" do
      it "works" do
        cacher.should_receive(:delete_cache_of_only).with(:test)
        cacher.delete_cache_of(:test)
      end
    end
  end

  describe "#delete_all_caches" do
    it "works" do
      cacher.fetch_cache_of(:has_many_cacheables) { 'cached' }
      cacher.fetch_cache_of(:has_many_through_cacheables) { 'cached' }

      cacher.delete_all_caches

      cacher.fetch_cache_of(:has_many_cacheables) { 'updated' }.should == 'updated'
      cacher.fetch_cache_of(:has_many_through_cacheables) { 'updated' }.should == 'updated'
    end
  end
end
