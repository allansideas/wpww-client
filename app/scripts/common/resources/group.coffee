angular.module('resources.groups', [])
.service("Group", ['$http', ($http) ->
  getGroup: (group_id)->
    $http.get("http://localhost:9393/wpww/groups/#{group_id}")
])
