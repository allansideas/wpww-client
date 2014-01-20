angular.module('resources.comments', [])
.service("Comment", ['$http', 'API',($http, API) ->
  commentsInGroup: (group_id)->
    $http.get("http://#{API}/wpww/groups/#{group_id}/comments")
  createComment: (group_id, comments)->
    $http.post("http://#{API}/wpww/groups/#{group_id}/comments", comments)
  removeComment: (comment_id)->
    $http.delete("http://#{API}/wpww/comments/#{comment_id}")
])
