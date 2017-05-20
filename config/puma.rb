threads_count = Integer(ENV['MUMUKI_CLASSROOM_API_THREADS'] || 2)

threads threads_count, threads_count

rackup      DefaultRackup
port        ENV['MUMUKI_CLASSROOM_API_PORT'] || 3002
environment ENV['RACK_ENV']                  || 'development'
