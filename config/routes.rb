Flamingo::Dispatcher::Map.define do |map|
  
  # tweet, event, limit, delete
  
  map.all :queue=>:logger #, :worker=>'LogEvents'
  map.tweet 'text'=>/https?/i, :queue=>:links #, :worker=>'ExtractLinks'
  map.tweet 'source'=>/web/i, :queue=>:web_source

end