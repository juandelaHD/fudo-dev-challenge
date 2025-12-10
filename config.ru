require_relative 'app/application'
require_relative 'app/workers/product_worker'
require_relative 'app/services/external_product_sync_service'

$stdout.sync = true
$stderr.sync = true

ExternalProductSyncService.sync_on_startup

ProductWorker.start

at_exit do
  puts "\n[Shutdown] Application shutting down, stopping workers..."
  ProductWorker.stop
end

run Application.app
