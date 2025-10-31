# Pin npm packages by running ./bin/importmap

pin '@hotwired/turbo-rails', to: '@hotwired--turbo-rails.js' # @8.0.20
pin '@hotwired/turbo', to: '@hotwired--turbo.js' # @8.0.20
pin '@rails/actioncable/src', to: '@rails--actioncable--src.js' # @8.1.100

pin 'js-cookie' # @3.0.5
pin 'jquery-mousewheel' # @3.2.2
pin 'jquery' # @3.7.1

pin_all_from 'app/javascript/vendor/jquery_mb_extruder', under: 'vendor/jquery_mb_extruder'

pin 'application'
pin 'translations'