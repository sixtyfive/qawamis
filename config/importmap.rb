# Pin npm packages by running ./bin/importmap

pin 'application'

pin_all_from 'app/javascript/vendor/jquery_mb_extruder', under: 'vendor/jquery_mb_extruder'
pin 'js-cookie' # @3.0.5
pin 'jquery-mousewheel' # @3.2.2
pin 'jquery' # @3.7.1
pin_all_from 'app/javascript/vendor/i18n-js', under: 'vendor/i18n-js'
pin 'translations'
pin 'ui'

pin '@hotwired/turbo-rails', to: '@hotwired--turbo-rails.js' # @8.0.20
pin '@hotwired/turbo', to: '@hotwired--turbo.js' # @8.0.20
pin '@rails/actioncable/src', to: '@rails--actioncable--src.js' # @8.1.100
