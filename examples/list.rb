require_relative '../lib/rubycopier'
service = RubyCopier::CopierService.new('copy.mrpc.pro:443', user_key: ENV.fetch('MRPC_API_KEY'))
# list raises on failure; [] means a successful response with no copiers.
service.list.each { |copier| puts "#{copier.id}: paused=#{copier.paused}" }
