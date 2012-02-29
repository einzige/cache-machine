require 'spec_helper'

describe CacheMachine::Cache::Map do

  let(:cacher) { cacher = Cacher.create }
  let(:join1)   { cacher.joins.create   }
  let(:join2)   { cacher.joins.create   }

  before :each do
    CacheMachine::Cache::Mapper.new do
      resource Cacher do
        collection :joins
      end
    end
  end

  describe "::fill_associations_map" do
    before :each do
      cacher and join1 and join2
    end

    it "really breaks" do
      cacher.should_receive(:association_ids)
      CacheMachine::Cache::map_adapter.association_ids(cacher, :joins)
    end

    it "works" do
      CacheMachine::Cache::Map.fill_associations_map(Cacher)
      cacher.should_not_receive(:association_ids)
      CacheMachine::Cache::map_adapter.association_ids(cacher, :joins).should =~ [join1.id, join2.id]
    end
  end
end
