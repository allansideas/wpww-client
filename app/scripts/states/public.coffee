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
              $state.go('wpww', identifier: data.identifier)
            .error (data)->
              console.log data
              #can handle errors here.
        ]) #end controller
  ).state('wpww',
    url: '/wpww/:identifier'
    views:
      'main':
        templateUrl: 'views/wpww/show.html'
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
        controller: (['$scope', '$state', '$http', 'flash', 'loadedGroup', 'loadedUsers', 'User', ($scope, $state, $http, flash, loadedGroup, loadedUsers, User)->
          $scope.group = {}
          $scope._user = {}
          $scope.ux = {}
          $scope.ux.show_add_user = false
          $scope.ux.show_edit_user = false
          $scope.ux.adding_user = false
          $scope.ux.updating_user = false
          $scope.ux.deleting_user = false
          $scope.ux.loaded = false
          $scope.getUrl = ()->
            window.location.origin + window.location.hash
          $scope.selectText = ()->
            document.getElementById('share').select()
          $scope.toggleAddUser = ()->
            $scope.ux.show_add_user = ! $scope.ux.show_add_user

          $scope.toggleEditUser = ()->
            $scope.ux.show_edit_user = ! $scope.ux.show_edit_user

          loadData = ()->
            if !loadedUsers
              $state.go('new_wpww')

            if loadedGroup.data? && loadedUsers.data?
              $scope.group = loadedGroup.data
              $scope.group.users = loadedUsers.data
              $scope.ux.loaded = true
              if $scope.group.users.length == 0
                $scope.ux.show_add_user = true
              else
                $scope.calculateWhoPaysWhat()

          validateUser = (user, flash_target)->
            if !user.name or !user.amount_paid_cents
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
              console.log $scope._user
              console.log $scope._user.amount_paid_cents
              $scope._user.amount_paid_cents = parseFloat($scope._user.amount_paid_cents) * 100
              console.log $scope._user
              User.createUser($scope.group.id, $scope._user)
              .success (data)->
                $scope.group.users.unshift data
                $scope._user = {}
                $scope.ux.adding_user = false
                $scope.ux.show_add_user = false
                flash.to('fl-user-list').success = 'Successfully added user! Recalculating who owes who what...'
                $scope.calculateWhoPaysWhat()
              .error (data)->
                flash.to('fl-user-form').error = 'Error saving the user check you filled in all the fields correctly.'

          $scope.editUser = (user)->
            $scope._e_user = angular.copy(user)
            $scope._e_user.amount_paid_cents = parseFloat($scope._e_user.amount_paid_cents) / 100
            $scope.ux.show_edit_user = true

          $scope.updateUser = ()->
            if !validateUser($scope._e_user, 'fl-user-form')
              return false

            unless $scope.ux.updating_user
              $scope.ux.updating_user = true
              $scope._e_user.amount_paid_cents = parseFloat($scope._e_user.amount_paid_cents) * 100
              User.updateUser($scope._e_user)
              .success (data)->
                for user, i in $scope.group.users
                  if user.id == data.id
                    $scope.group.users[i] = data
                    break
                $scope._e_user = {}
                $scope.ux.updating_user = false
                flash.to('fl-user-list').success = 'Successfully Updated! Recalculating who owes who what...' 
                $scope.ux.show_edit_user = false
                $scope.calculateWhoPaysWhat()
              .error (data)->
                flash.to('fl-user-form').error = 'Error saving the user check you filled in all the fields correctly.'


          $scope.removeUser = (user_id)->
            $scope.ux.deleting_user = true
            for user, i in $scope.group.users
              if user.id == user_id
                $scope.group.users.splice(i, 1)
                break
            flash.to('fl-user-list').success = 'Removed! Recalculating who owes who what...'
            User.removeUser(user_id)
            .success (data)->
              $scope.ux.deleting_user = false
              $scope.calculateWhoPaysWhat()
              return
            .error (data)->
              flash.to('fl-user-list').error = 'Error, sorry bout that!'

          $scope.totalSpend = ()->
            total = 0
            for user in $scope.group.users
              total = total + user.amount_paid_cents
            total


          $scope.addOwing = (ower, user, amount)->
            for u in $scope.group.users
              if u.id == ower.id
                if ower.owings?
                  ower.owings.push {user: user, amount: amount}
                else
                  ower.owings = []
                  ower.owings.push {user: user, amount: amount}

          $scope.calculateWhoPaysWhat = ()->
            total = $scope.totalSpend()
            num_users = $scope.group.users.length

            #total amount spent by all / number of people = the amount
            #paid by each person if they had all split everything
            #evenly along the way
            even_split = total / num_users
            $scope.even_split = even_split

            for user in $scope.group.users
              user.owings = []
              #get the negative(owing) or positive(owed) distance from the even split
              user.from_even = user.amount_paid_cents - even_split
             
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

            for owed_user, i in users_order_most_owed
              if owed_user.from_even == 0
                users_order_most_owed.splice i, 1
                return
              else
                getOwers(owed_user)

          loadData()
          $scope.url = $scope.getUrl()
        ]) #end controller
  )


])
