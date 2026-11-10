require 'minitest/autorun'
require_relative '../lib/rubycopier'
class ContractTest < Minitest::Test
  class Spy
    attr_reader :calls
    def initialize; @calls=[];end
    def method_missing(name,*args,**kwargs)
      raise 'Missing ApiKey' unless kwargs[:metadata]['apikey']=='owner-test'
      raise 'Missing deadline' unless kwargs[:deadline]
      @calls << [name,args[0]]
      return Copier::ListReply.new(ok:false,error:'refused') if name==:list
      name==:start ? Copier::StartReply.new(ok:true,copier_id:'test') : Copier::SimpleReply.new(ok:true)
    end
  end
  def test_all_calls
    client=RubyCopier::CopierService.new('copy.mrpc.pro',user_key:'owner-test')
    spy=Spy.new;client.instance_variable_set(:@stub,spy)
    assert client.start(master:{user:1},slave:{user:2},copy_sl:false,copy_tp:true,fixed_master_balance:'1000').ok
    assert_raises(StandardError){client.list}
    assert client.pause('test',paused:false).ok
    assert client.remove('test').ok
    assert_equal 4,spy.calls.length
    req=spy.calls[0][1]
    refute req.copy_sl;assert req.copy_tp;assert_equal '1000',req.fixed_master_balance
  end
  def test_bad_keys
    ['','TRIAL','trial','a b',"x\r\nInjected: yes"].each do |key|
      assert_raises(ArgumentError){RubyCopier::CopierService.new('copy.mrpc.pro',user_key:key)}
    end
  end
end
