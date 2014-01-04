angular.module('wpwwClientApp', [
  'ngSanitize'
  'ui.router'
  'states.public'
])
.config(['$urlRouterProvider', ($urlRouterProvider) ->
    $urlRouterProvider.otherwise('/')
  ])
