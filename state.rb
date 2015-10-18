require 'localmemcache'
require 'json'

class State
  def initialize path='./data.lmc'
    @store = LocalMemCache.new(:filename => path)
  end

  def [] key
    JSON.load(@store[key])
  end

  def []= key, value
    @store[key] = value.to_json
  end
end
