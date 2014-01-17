angular.module('wpwwClientApp', [
  'ngSanitize'
  'ngAnimate'
  'ui.router'
  'angular-flash.service'
  'angular-flash.flash-alert-directive'
  'states.public'
  'resources.groups'
  'resources.users'
])
#.constant("API", "localhost:9393")
.constant("API", "api.woww.instantiate.me")
.config(['$urlRouterProvider', ($urlRouterProvider) ->
    $urlRouterProvider.otherwise('/')
  ])
