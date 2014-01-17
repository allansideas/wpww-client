angular.module('resources.users', [])
.service("User", ['$http', 'API',($http, API) ->
  usersInGroup: (group_id)->
    $http.get("http://#{API}/wpww/groups/#{group_id}/users")
  getUser: (user_id)->
    return false
  updateUser: (user)->
    $http.put("http://#{API}/wpww/users/#{user.id}", user)
  createUser: (group_id, user)->
    $http.post("http://#{API}/wpww/groups/#{group_id}/users", user)
  removeUser: (user_id)->
    $http.delete("http://#{API}/wpww/users/#{user_id}")

])
