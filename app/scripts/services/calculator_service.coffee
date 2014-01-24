angular.module('services.calculator', [])
.factory 'Calculator', -> 
  this.users_ary = []

  totalSpend: (users)->
    total = 0
    for user in users
      total = total + user.amount_paid_cents
    total

  addOwing: (ower, user, amount, users)->
    for u in users
      if u.id == ower.id
        if ower.owings?
          ower.owings.push {user: user, amount: amount}
        else
          ower.owings = []
          ower.owings.push {user: user, amount: amount}

  getEventSplit: (users)->
    @totalSpend(users) / users.length

  getOwers: (user, users_order_least_owed)->
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
          @addOwing(ower, user, rest_of_owed, users_order_least_owed)
          #setting the user and ower new from_even vals
          user.from_even -= rest_of_owed
          ower.from_even = remainder_after
        else
          #building the owers array
          @addOwing(ower, user, ower.from_even * -1, users_order_least_owed)
          #setting the user and ower new from_even vals
          user.from_even -= (ower.from_even * -1)
          ower.from_even = 0

  calculateWhoPaysWhat: (users)->
    console.log this.users_ary 
    even_split = @getEventSplit(users)

    for user in users
      user.owings = []
      #get the negative(owing) or positive(owed) distance from the even split
      user.from_even = user.amount_paid_cents - even_split

    users_order_least_owed = _.sortBy users, "from_even", _.values
    users_order_most_owed = users_order_least_owed.reverse()

    for owed_user, i in users_order_most_owed
      if owed_user.from_even == 0
        users_order_most_owed.splice i, 1
        return
      else
        @getOwers(owed_user, users_order_least_owed)
