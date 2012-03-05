require 'spec_helper'

describe CacheMachine::Cache::Associations do

  let(:cacher) { cacher = Cacher.create }
  let(:join)   { cacher.joins.create    }
  let(:hmt)    { HasManyThroughCacheable.create(:cachers => [cacher]) }

  before :each do
    CacheMachine::Cache::Mapper.new do
      resource Cacher do
        collection :joins
        collection :has_many_through_cacheables
      end
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
end
