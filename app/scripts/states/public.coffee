angular.module('states.public', [])
.config(['$stateProvider', '$urlRouterProvider', ($stateProvider, $urlRouterProvider)->
  $stateProvider.state('new_wpww',
    url: '/'
    views:
      'main':
        templateUrl: 'views/wpww/new.html'
        controller: (['$scope', '$state', '$http', 'API', ($scope, $state, $http, API)->
          $scope.group = {}
          $scope.ux = {}
          $scope.ux.creating = false
          $scope.ux.add_description = false

          $scope.createGroup = ()->
            if !$scope.group.name
              return false
            $scope.ux.creating = true
            $http.post("http://#{API}/wpww/groups", $scope.group).success (data)->
              $state.go('event.show', identifier: data.identifier)
            .error (data)->
              console.log data
              #can handle errors here.
        ]) #end controller
  ).state('event',
    url: '/event/:identifier'
    views:
      'main':
        resolve: 
          loadedGroup: ['Group', '$stateParams', (Group, $stateParams)->
            Group.getGroup($stateParams.identifier)
          ]
          loadedUsers: ['loadedGroup', 'User', (loadedGroup, User)->
            if loadedGroup.data != 'null'
              User.usersInGroup(loadedGroup.data.id)
            else
              return false
          ]
          loadedComments: ['loadedGroup', 'Comment', (loadedGroup, Comment)->
            if loadedGroup.data != 'null'
              Comment.commentsInGroup(loadedGroup.data.id)
            else
              return false
          ]
        templateUrl: 'views/wpww/event.html'
        controller: 'EventController'
  ).state('event.show',
    url: '/show'
    views:
      'left':
        templateUrl: 'views/wpww/event_results_panel.html'
        controller: (['$scope', '$state', '$http', 'flash', 'User', 'Comment', ($scope, $state, $http, flash, User, Comment)->
          $scope._comment = {}
          $scope.ux = $scope.$parent.ux

          $scope.addComment = ()->
            unless $scope.ux.adding_comment or !$scope._comment.body
              $scope.ux.adding_comment = true
              Comment.createComment($scope.group.id, $scope._comment)
              .success (data)->
                $scope.group.comments.unshift data
                $scope._comment = {}
                $scope.ux.adding_comment = false
              .error (data)->
                flash.to('fl-user-form').error = 'Error saving the comment check you filled in all the fields correctly.'
        ]) #end controller
      'right':
        templateUrl: 'views/wpww/event_manage_panel.html'
        controller: 'EventManageController'
  )
])
