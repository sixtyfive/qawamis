# Pin npm packages by running ./bin/importmap

pin 'application'

pin_all_from 'app/javascript/vendor/jquery_mb_extruder', under: 'vendor/jquery_mb_extruder'
pin 'js-cookie' # @3.0.5
pin 'jquery-mousewheel' # @3.2.2
pin 'jquery' # @3.7.1
pin 'translations'
pin 'ui'

pin '@hotwired/turbo-rails', to: '@hotwired--turbo-rails.js' # @8.0.20
pin '@hotwired/turbo', to: '@hotwired--turbo.js' # @8.0.20
pin '@rails/actioncable/src', to: '@rails--actioncable--src.js' # @8.1.100

#pin "i18n-js" # @4.5.1
#pin "bignumber.js" # @9.3.1
#pin "lodash/camelCase", to: "lodash--camelCase.js" # @4.17.21
#pin "lodash/get", to: "lodash--get.js" # @4.17.21
#pin "lodash/has", to: "lodash--has.js" # @4.17.21
#pin "lodash/merge", to: "lodash--merge.js" # @4.17.21
#pin "lodash/range", to: "lodash--range.js" # @4.17.21
#pin "lodash/repeat", to: "lodash--repeat.js" # @4.17.21
#pin "lodash/sortBy", to: "lodash--sortBy.js" # @4.17.21
#pin "lodash/uniq", to: "lodash--uniq.js" # @4.17.21
#pin "lodash/zipObject", to: "lodash--zipObject.js" # @4.17.21
#pin "make-plural" # @7.4.0
