#require 'test_helper'
#require 'prax/microworker'
#
#class TestMicroWorker < Prax::MicroWorker
#  def perform
#    # queue.pop
#  end
#end
#
#describe "MicroWorker" do
#  let :worker do
#    TestMicroWorker.new(4)
#  end
#
#  after { worker.stop(true) if worker.started? }
#
#  it "must have start the threads" do
#    assert_equal 4, worker.threads.size
#  end
#
#  it "must be started" do
#    assert worker.started?
#  end
#
#  describe "stop" do
#    before do
#      worker.stop(true)
#      Thread.pass # hacky: makes the test pass in MRI, but not in RBX
#    end
#
#    it "must stop" do
#      assert_equal 0, worker.threads.size
#    end
#  end
#
#  it "must respawn failed threads"
#
#end
