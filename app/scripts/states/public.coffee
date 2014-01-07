angular.module('states.public', [])
.config(['$stateProvider', '$urlRouterProvider', ($stateProvider, $urlRouterProvider)->
  $stateProvider.state('new_wpww',
    url: '/wpww/new'
    views:
      'main':
        template: '
          <h1>Create a new wpww</h1>
          <input ng-model="group.description" type="text"></div>
          <button ng-click="createGroup()">Create Group</button>
          '
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
        template: '
          <h2>{{group.description}}</h2>
          <ul>
            <li ng-repeat="user in group.users">
            {{user.name}} : ${{user.amount_payed_cents}}
            </li>
          </ul>
          <form>
            <p>name*</p>
            <input type="text" ng-model="_user.name" />
            <p>email</p>
            <input type="email" ng-model="_user.email" />
            <p>amount payed in cents</p>
            <input type="number" ng-model="_user.amount_payed_cents" />
            <button ng-click="addUser()">Add someone</button>
          </form>
          <button ng-click="calculateWhoPaysWhat()">Calculate who pays what.</button>
          <div ng-repeat="ower in owing_results track by $index">
            <strong>{{ower.ower.name}}</strong>
            must pay
            <br />
            <p ng-repeat="o in ower.owings">
              {{o.user.name}}
              {{o.amount}}
            </p>
          </div>
          '
        controller: (['$scope', '$state', '$http', ($scope, $state, $http)->
          $scope.group = {}
          $scope._user = {}
          $scope.owing_results = []

          $http.get("http://localhost:9393/wpww/groups/#{$state.params.identifier}").success (data, status, headers, config)->
            $scope.group = data
            $http.get("http://localhost:9393/wpww/groups/#{$scope.group.id}/users").success (data, status, headers, config)->
              $scope.group.users = data
              $scope._user = {}
          .error (data, status, headers, config)->
            alert "Can't find group"
            
          $scope.addUser = ()->
            $http.post("http://localhost:9393/wpww/groups/#{$scope.group.id}/users", $scope._user).success (data, status, headers, config)->
              $scope.group.users.push data
            .error (data, status, headers, config)->
              #can handle errors here.

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

            for owed_user, i in users_order_most_owed
              if owed_user.from_even == 0
                users_order_most_owed.splice i, 1
                return
              else
                getOwers(owed_user)

        ]) #end controller
  )


])
