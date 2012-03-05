require "spec_helper"

describe CacheMachine::Cache::Scope do
  let(:cacher_under_scope_one) { Cacher.create :name => 'one'  }
  let(:cacher_under_scope_two) { Cacher.create :name => 'two'  }
  let(:cacher_outside_scope  ) { Cacher.create :name => 'tree' }

  let(:join_under_scope_one) { Join.create :cacher => cacher_under_scope_one }
  let(:join_under_scope_two) { Join.create :cacher => cacher_under_scope_two }
  let(:join_outside_scope)   { Join.create :cacher => cacher_outside_scope   }

  before :each do
    CacheMachine::Cache::Mapper.new do
      resource Cacher, :scopes => :test_scope do
        collection :joins, :scopes => :test_scope
      end
    end
  end

  it "works" do
    Cacher.should respond_to(:cache_scopes)
    Cacher.should respond_to(:under_cache_scopes)
  end

  describe "::under_cache_scopes" do
    context "for resources" do
      before :each do
        cacher_under_scope_one
        cacher_under_scope_two
        cacher_outside_scope
      end

      it "works" do
        Cacher.under_cache_scopes.all.should =~ [cacher_under_scope_one, cacher_under_scope_two]
      end
    end

    context "for collections" do
      before :each do
        join_under_scope_one
        join_under_scope_two
        join_outside_scope
      end

      it "works" do
        Join.under_cache_scopes.all.should =~ [join_under_scope_one, join_under_scope_two]
      end
    end
  end
end