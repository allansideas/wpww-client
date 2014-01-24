angular.module('controllers.event_manage', [])
.controller 'EventManageController', ['$scope', '$state', '$http', 'flash', 'User', 'LineItem', ($scope, $state, $http, flash, User, LineItem)->
  $scope._user = {}
  $scope._user.amount_paid_cents = 0
  $scope._line_item = {}
  $scope._line_item.amount_in_cents = 0

  $scope.ux = $scope.$parent.ux
  $scope.ux.adding_user = false
  $scope.ux.updating_user = false

  $scope.selectText = ()->
    document.getElementById('share').select()

  validateUser = (user, flash_target)->
    if !user.name and user.amount_paid_cents >= 0
      flash.to('fl-user-form').error = 'Error saving the user check you filled in all the fields correctly.'
      $scope.ux.adding_user = false
      $scope.ux.updating_user = false
      return false
    else
      return true

  $scope.addUser = ()->
    if !validateUser($scope._user, 'fl-user-form')
      return false
    unless $scope.ux.adding_user
      $scope.ux.adding_user = true
      $scope._user.amount_paid_cents = parseFloat($scope._user.amount_paid_cents) * 100
      User.createUser($scope.$parent.group.id, $scope._user)
      .success (data)->
        $scope.$parent.group.users.unshift data
        $scope._user = {}
        $scope._user.amount_payed_cents = 0
        $scope.ux.adding_user = false
        $scope.ux.show_add_user = false
        flash.to('fl-user-list').success = 'Successfully added user! Recalculating who owes who what...'
      .error (data)->
        flash.to('fl-user-form').error = 'Error saving the user check you filled in all the fields correctly.'

  $scope.addLineItem = ()->
    unless $scope.ux.adding_line_item
      $scope._line_item.user_id = $scope._line_item.user.id
      delete $scope._line_item.user
      $scope.ux.adding_line_item = true
      $scope._line_item.amount_in_cents = parseFloat($scope._line_item.amount_in_cents) * 100
      console.log $scope._line_item
      LineItem.createLineItem($scope._line_item)
      .success (data)->
        for user in $scope.$parent.group.users
          if user.id == $scope._line_item.user_id
            if user.line_items?
              user.line_items.unshift data
            else
              user.line_items = []
              user.line_items.push data
        $scope._line_item = {}
        $scope._line_item.amount_in_cents = 0
        $scope.ux.adding_line_item = false
        flash.to('fl-user-list').success = 'Successfully added item! Recalculating who owes who what...'
      .error (data)->
        flash.to('fl-user-form').error = 'Error saving the item check you filled in all the fields correctly.'

  $scope.updateUser = ()->
    if !validateUser($scope._e_user, 'fl-user-form')
      return false

    unless $scope.ux.updating_user
      $scope.ux.updating_user = true
      $scope._e_user.amount_paid_cents = parseFloat($scope._e_user.amount_paid_cents) * 100
      User.updateUser($scope._e_user)
      .success (data)->
        for user, i in $scope.$parent.group.users
          if user.id == data.id
            $scope.$parent.group.users[i] = data
            break
        $scope._e_user = {}
        $scope.ux.updating_user = false
        flash.to('fl-user-list').success = 'Successfully Updated! Recalculating who owes who what...' 
        $scope.ux.show_edit_user = false
      .error (data)->
        flash.to('fl-user-form').error = 'Error saving the user check you filled in all the fields correctly.'

  $scope.$on 'edit-event-user', (scope, user)-> 
    $scope._e_user = angular.copy(user)
    $scope._e_user.amount_paid_cents = parseFloat($scope._e_user.amount_paid_cents) / 100
    $scope.$parent.ux.show_edit_user = !$scope.$parent.ux.show_edit_user

  $scope.$on 'remove-event-user', (scope, user_id)-> 
    $scope.ux.deleting_user = true
    for user, i in $scope.$parent.group.users
      if user.id == user_id
        $scope.$parent.group.users.splice(i, 1)
        break
    flash.to('fl-user-list').success = 'Removed! Recalculating who owes who what...'
    User.removeUser(user_id)
    .success (data)->
      $scope.$parent.ux.deleting_user = false
      return
    .error (data)->
        flash.to('fl-user-list').error = 'Error, sorry bout that!'

  $scope.$on 'remove-event-user-line-item', (scope, line_item)-> 
    $scope.ux.line_item_user = true
    for user in $scope.$parent.group.users
      if user.id == line_item.user_id
        for li, i in user.line_items
          if li.id == line_item.id
            user.line_items.splice(i, 1)
            break
        break
    flash.to('fl-user-list').success = 'Removed! Recalculating who owes who what...'
    LineItem.removeLineItem(line_item.id)
    .success (data)->
      $scope.$parent.ux.deleting_line_item = false
      return
    .error (data)->
        flash.to('fl-user-list').error = 'Error, sorry bout that!'

]
