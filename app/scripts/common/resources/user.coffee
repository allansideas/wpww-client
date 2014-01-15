angular.module('resources.users', [])
.service("User", ['$http', ($http) ->
  usersInGroup: (group_id)->
    $http.get("http://localhost:9393/wpww/groups/#{group_id}/users")
  getUser: (user_id)->
    return false
  updateUser: (user_data)->
    return false
  createUser: (group_id, user_data)->
    $http.post("http://localhost:9393/wpww/groups/#{group_id}/users", user_data)
])
