angular.module('states.public', [])
.config(['$stateProvider', '$urlRouterProvider', ($stateProvider, $urlRouterProvider)->
  $stateProvider.state('test', 
    url: '/test'
    views:
      'main':
        template: 'Hurrah!'
        controller: (['$scope', '$state', ($scope, $state)->
          console.log $scope, $state
        ]) #end controller
  )
])
