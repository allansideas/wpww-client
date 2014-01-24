angular.module('wpwwClientApp', [
  'ngSanitize'
  'ngAnimate'
  'ui.router'
  'ui.bootstrap'
  'angular-flash.service'
  'angular-flash.flash-alert-directive'
  'states.public'
  'resources.groups'
  'resources.users'
  'resources.comments'
  'resources.line_items'
  'controllers.event'
  'controllers.event_manage'
  'services.calculator'
])
.constant("API", "localhost:9393")
#.constant("API", "api.woww.instantiate.me")
.config(['$urlRouterProvider', ($urlRouterProvider) ->
    $urlRouterProvider.otherwise('/')
  ])
