require_relative 'app/application'

$stdout.sync = true
$stderr.sync = true

run Application.app
