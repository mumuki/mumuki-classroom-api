#\ -s puma -O Threads=2:8

require_relative './lib/classroom'
require_relative './app/routes'

run Sinatra::Application
