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
.config(['$urlRouterProvider', ($urlRouterProvider) ->
    $urlRouterProvider.otherwise('/')
  ])
