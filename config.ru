require_relative 'app/application'
require_relative 'app/workers/product_worker'

$stdout.sync = true
$stderr.sync = true

ProductWorker.start

at_exit do
  ProductWorker.stop
end

run Application.app
