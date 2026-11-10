require 'json'
require_relative '../lib/rubycopier'
begin
 v=13.times.map { STDIN.readline.chomp }
 c=RubyCopier::CopierService.new(v[0],user_key:v[1])
 platform=ENV.fetch('COPIER_PLATFORM','MT5')
 raise 'COPIER_PLATFORM must be MT4 or MT5' unless ['MT4','MT5'].include?(platform)
 account=->(i){{type:platform,user:Integer(v[i]),password:v[i+1],server:v[i+2],id:v[i+3]}}
 r=case ARGV[0]
 when 'start' then c.start(master:account.call(2),slave:account.call(6),risk_type:v[10],risk_value:v[11],fixed_master_balance:v[12],copy_sl:true,copy_tp:true)
 when 'list' then {ok:true,copiers:c.list.map(&:to_h)}
 when 'pause' then c.pause(ARGV[1],paused:ARGV[2]=='true')
 when 'remove' then c.remove(ARGV[1])
 else raise 'Unknown operation'
 end
 puts JSON.generate(r.respond_to?(:to_h) ? r.to_h : r)
rescue => e
 puts JSON.generate(ok:false,error:e.message)
 exit 1
end
