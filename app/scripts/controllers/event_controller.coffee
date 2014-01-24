angular.module('controllers.event', [])
.controller 'EventController', ['$scope', '$state', 'loadedGroup', 'loadedUsers', 'loadedComments', 'Calculator', ($scope, $state, loadedGroup, loadedUsers, loadedComments, Calculator)->
  $scope.ux = {}
  $scope.ux.show_add_user = false
  $scope.ux.show_edit_user = false
  $scope.ux.deleting_user = false

  $scope.toggleAddUser = ()->
    $scope.ux.show_add_user = ! $scope.ux.show_add_user

  $scope.toggleEditUser = ()->
    $scope.ux.show_edit_user = ! $scope.ux.show_edit_user

  $scope.editUser = (user)->
    $scope.$broadcast('edit-event-user', user)

  $scope.removeUser = (user_id)->
    $scope.$broadcast('remove-event-user', user_id)

  $scope.removeLineItem = (line_item)->
    $scope.$broadcast('remove-event-user-line-item', line_item)

  setUsersTotalPaid = ()->
    console.log $scope.group.users
    for user in $scope.group.users
      total = 0
      if user.line_items
        for li in user.line_items
          total += li.amount_in_cents
      user.amount_paid_cents = total

  loadData = ()->
    if !loadedUsers
      $state.go('new_wpww')
    if loadedGroup.data? && loadedUsers.data?
      $scope.group = loadedGroup.data
      $scope.group.users = loadedUsers.data.reverse()
      setUsersTotalPaid()
      $scope.group.comments = loadedComments.data.reverse()
      $scope.ux.loaded = true
      if $scope.group.users.length == 0
        $scope.ux.show_add_user = true
      else
        $scope.even_split = Calculator.getEventSplit($scope.group.users)
        Calculator.calculateWhoPaysWhat($scope.group.users)
  loadData()

  $scope.$watch('group.users', (n, o)->
    if n != o
      setUsersTotalPaid()
      $scope.even_split = Calculator.getEventSplit($scope.group.users)
      Calculator.calculateWhoPaysWhat($scope.group.users)
  ,true)
]
