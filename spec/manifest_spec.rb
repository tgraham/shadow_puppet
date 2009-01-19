require File.dirname(__FILE__) + '/spec_helper.rb'

describe "A manifest" do

  describe "when blank" do

    before(:each) do
      @manifest = BlankManifest.new
    end

    it "does nothing" do
      @manifest.class.recipes.should == []
    end

    it "returns true when run" do
      @manifest.run.should be_true
    end

  end

  describe "in general" do

    before(:each) do
      @manifest = RequiresMetViaMethods.new
    end

    it "knows what it's supposed to do" do
      @manifest.class.recipes.should == [:foo, :bar]
    end

    describe 'when evaluated' do

      it "calls specified methods" do
        @manifest.should_receive(:foo)
        @manifest.should_receive(:bar)
        @manifest.evaluate
      end

      it "creates new resources" do
        @manifest.should_receive(:newresource).with(Puppet::Type::Exec, 'foo', :command => '/usr/bin/true').exactly(1).times
        @manifest.should_receive(:newresource).with(Puppet::Type::Exec, 'bar', :command => '/usr/bin/true').exactly(1).times
        @manifest.evaluate
      end

      it "creates new objects" do
        @manifest.evaluate
        @manifest.objects.should_not == {}
      end
    end

    describe "when run" do

      it "calls evaluate and apply" do
        @manifest.should_receive(:evaluate)
        @manifest.should_receive(:apply)
        @manifest.run
      end

      it "returns true" do
        @manifest.run.should == true
      end

      it "cannot be run again" do
        @manifest.run.should == true
        @manifest.run.should == false
      end

    end

  end

end