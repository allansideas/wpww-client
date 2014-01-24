angular.module('resources.line_items', [])
.service("LineItem", ['$http', 'API',($http, API) ->
  createLineItem: (line_item)->
    console.log line_item
    $http.post("http://#{API}/wpww/users/#{line_item.user_id}/line_items", line_item)
  removeLineItem: (line_item_id)->
    $http.delete("http://#{API}/wpww/line_items/#{line_item_id}")
])
