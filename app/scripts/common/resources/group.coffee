angular.module('resources.groups', [])
.service("Group", ['$http', 'API', ($http, API) ->
  getGroup: (group_id)->
    $http.get("http://#{API}/wpww/groups/#{group_id}")
])
