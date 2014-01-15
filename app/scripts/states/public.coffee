angular.module('states.public', [])
.config(['$stateProvider', '$urlRouterProvider', ($stateProvider, $urlRouterProvider)->
  $stateProvider.state('new_wpww',
    url: '/wpww/new'
    views:
      'main':
        templateUrl: 'views/wpww/new.html'
        controller: (['$scope', '$state', '$http', ($scope, $state, $http)->
          $scope.group = {}

          $scope.createGroup = ()->
            $http.post('http://localhost:9393/wpww/groups', $scope.group).success (data, status, headers, config)->
              $state.go('wpww', identifier: data.identifier)
            .error (data, status, headers, config)->
              #can handle errors here.
        ]) #end controller
  ).state('wpww',
    url: '/wpww/:identifier'
    views:
      'main':
        templateUrl: 'views/wpww/show.html'
        controller: (['$scope', '$state', '$http', 'flash', 'Group', 'User', ($scope, $state, $http, flash, Group, User)->
          $scope.group = {}
          $scope._user = {}
          $scope.owing_results = []
          $scope.ux = {}
          $scope.ux.show_add_user = false
          $scope.ux.show_edit_user = false
          $scope.ux.adding_user = false
          $scope.ux.updating_user = false

          $scope.toggleAddUser = ()->
            $scope.ux.show_add_user = ! $scope.ux.show_add_user

          $scope.toggleEditUser = ()->
            $scope.ux.show_edit_user = ! $scope.ux.show_edit_user

          Group.getGroup($state.params.identifier)
          .success (data)->
            $scope.group = data
            User.usersInGroup($scope.group.id)
            .success (data)->
              $scope.group.users = data.reverse()
              if $scope.group.users.length == 0
                $scope.ux.show_add_user = true
          .error (data, status, headers, config)->
            alert "Can't find group"

          validateUser = (user, flash_target)->
            if !user.name or !user.amount_payed_cents
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
              User.createUser($scope.group.id, $scope._user)
              .success (data)->
                $scope.group.users.unshift data
                $scope._user = {}
                $scope.ux.adding_user = false
                $scope.ux.show_add_user = false
                flash.to('fl-user-list').success = 'Successfully added user!'
              .error (data)->
                flash.to('fl-user-form').error = 'Error saving the user check you filled in all the fields correctly.'

          $scope.editUser = (user)->
            $scope._e_user = angular.copy(user)
            $scope.ux.show_edit_user = true

          $scope.updateUser = ()->
            if !validateUser($scope._e_user, 'fl-user-form')
              return false

            unless $scope.ux.updating_user
              $scope.ux.updating_user = true
              User.updateUser($scope._e_user)
              .success (data)->
                for user, i in $scope.group.users
                  if user.id == data.id
                    $scope.group.users[i] = data
                    break
                $scope._e_user = {}
                $scope.ux.updating_user = false
                flash.to('fl-user-list').success = 'Successfully Updated'
                $scope.ux.show_edit_user = false
              .error (data)->
                flash.to('fl-user-form').error = 'Error saving the user check you filled in all the fields correctly.'


          $scope.removeUser = (user_id)->
            for user, i in $scope.group.users
              if user.id == user_id
                $scope.group.users.splice(i, 1)
                break
            flash.to('fl-user-list').success = 'Removed!'
            User.removeUser(user_id)
            .success (data)->
              return
            .error (data)->
              flash.to('fl-user-list').error = 'Error, sorry bout that!'

          $scope.totalSpend = ()->
            total = 0
            for user in $scope.group.users
              total = total + user.amount_payed_cents
            total


          $scope.indexOfOwerInOwings = (ower)->
            index = undefined
            for o, i in $scope.owing_results
              if o.ower.id == ower.id
                index = i
            index

          $scope.addOwing = (ower, user, amount)->
            #if the ower is already in the owers array, find the index
            ower_in_owings_index = $scope.indexOfOwerInOwings(ower)
            #if they are then add the user to thier owings array,
            #otherwise create the owing with one user.
            if ower_in_owings_index?
              $scope.owing_results[ower_in_owings_index].owings.push {user: user, amount: amount}
            else
              owing = {}
              owing.ower = ower
              owing.owings = []
              owing.owings.push {user: user, amount: amount}
              $scope.owing_results.push owing

          $scope.calculateWhoPaysWhat = ()->
            $scope.owing_results = []
            total = $scope.totalSpend()
            num_users = $scope.group.users.length

            #total amount spent by all / number of people = the amount
            #payed by each person if they had all split everything
            #evenly along the way
            even_split = total / num_users

            for user in $scope.group.users
              #get the negative(owing) or positive(owed) distance from the even split
              user.from_even = user.amount_payed_cents - even_split
             
            #sort the users 
            users_order_least_owed = _.sortBy $scope.group.users, "from_even", _.values
            users_order_most_owed = users_order_least_owed.reverse()

            #calculate who owes a given user
            getOwers = (user)->
              for ower, i in users_order_least_owed
                #ignore the user we are asking for owers from ignore
                #them if they are owed money, or they have had all their
                #owers figured out (from_even == 0)
                unless ower.id == user.id or ower.from_even >= 0 or user.from_even == 0
                  #if the ower owes more than the total remaining owed
                  #to the user then owe the rest of what that user is
                  #owed and set the remainder they owe after, otherwise
                  #owe the full amount of what they owe to the given
                  #user.
                  if (user.from_even - ower.from_even * -1) < 0
                    remainder_after = user.from_even - ower.from_even * -1
                    rest_of_owed = (ower.from_even * -1) - remainder_after * -1
                    #building the owers array
                    $scope.addOwing(ower, user, rest_of_owed)
                    #setting the user and ower new from_even vals
                    user.from_even -= rest_of_owed
                    ower.from_even = remainder_after
                  else
                    #building the owers array
                    $scope.addOwing(ower, user, ower.from_even * -1)
                    #setting the user and ower new from_even vals
                    user.from_even -= (ower.from_even * -1)
                    ower.from_even = 0
              for owing in $scope.owing_results
                for user in $scope.group.users
                  if user.id == owing.ower.id
                    user.owings = owing.owings

            for owed_user, i in users_order_most_owed
              if owed_user.from_even == 0
                users_order_most_owed.splice i, 1
                return
              else
                getOwers(owed_user)

                

        ]) #end controller
  )


])
