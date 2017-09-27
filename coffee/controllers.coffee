controllers = angular.module "judgebooth.controllers", []

controllers.controller 'SideCtrl', [
  "$scope", "questionsAPI", "$ionicScrollDelegate", "$location", "$ionicSideMenuDelegate"
  ($scope, questionsAPI, $ionicScrollDelegate, $location, $ionicSideMenuDelegate) ->
    # get data / basic vars
    $scope.filter = questionsAPI.filter()
    $scope.filteredQuestions = []
    $scope.languages = questionsAPI.languages()
    $scope.languageCounts = {}
    $scope.offlineMode = window.offlineMode
    questionsAPI.sets().then (response) -> $scope.sets = response.data

    $scope.languageFilter = (language) -> $scope.languageCounts[language.id] > 0

    # get questions and generate maps with counts
    questionsAPI.questions().then (response) ->
      $scope.setCounts = {}
      for question in response.data
        sets = []
        for card in question.cards
          sets.push set for set in card when set not in sets
        for language in question.languages
          $scope.languageCounts[language] or= 0
          $scope.languageCounts[language]++
          for set in sets
            $scope.setCounts[language] or= {}
            $scope.setCounts[language][set] or= 0
            $scope.setCounts[language][set]++
      $scope.updateCount()

    # show list of sets
    $scope.showSets = ->
      $scope.setsShown = !$scope.setsShown
      $ionicScrollDelegate.resize()

    # filter out a single set or many of them
    $scope.toggleSet = (id) ->
      $scope.filter.sets = [] if id in ["all", "modern", "standard", "none"]
      switch id
        when "standard" then $scope.filter.sets.push set.id for set in $scope.sets when !set.standard
        when "modern" then $scope.filter.sets.push set.id for set in $scope.sets when !set.modern
        when "none" then $scope.filter.sets.push set.id for set in $scope.sets
        else
          if id in $scope.filter.sets
            $scope.filter.sets.splice $scope.filter.sets.indexOf(id), 1
          else
            $scope.filter.sets.push id
      $scope.updateCount()

    # filter out difficulty levels
    $scope.toggleDifficulty = (level) ->
      if level in $scope.filter.difficulty
        $scope.filter.difficulty.splice $scope.filter.difficulty.indexOf(level), 1
      else
        $scope.filter.difficulty.push level
      $scope.updateCount()

    # calculate number of resulting questions and selected sets
    $scope.updateCount = ->
      questionsAPI.filterQuestions($scope.filter, no).then (questions) -> $scope.filteredQuestions = questions
      $scope.setCount = 0
      if $scope.setCounts[$scope.filter.language]
        $scope.setCount = Object.keys($scope.setCounts[$scope.filter.language]).length
        $scope.setCount-- for set in $scope.filter.sets when $scope.setCounts[$scope.filter.language][set]

    # show the questions
    $scope.showQuestions = ->
      return unless $scope.filteredQuestions.length
      questionsAPI.filter $scope.filter
      $scope.next()

    # save filter when sidebar is closed
    $scope.$watch (() => $ionicSideMenuDelegate.isOpenLeft()), (isOpen) =>
      if !isOpen and $scope.filteredQuestions.length
        questionsAPI.filter $scope.filter

    # auth handling
    $scope.tab = "filter"
    $scope.user = questionsAPI.user()

    # login
    $scope.login = ->
      questionsAPI.auth().then (auth) ->
        window.location.href = auth.login if auth.login?
        $scope.user = auth if auth.role?
      , (response) -> $scope.user = response.data

    # logout
    $scope.logout = ->
      questionsAPI.logout()
      $scope.user = false
      $scope.tab = "filter"

    # toggle sidebar tab
    $scope.toggleTab = (tab) -> $scope.tab = tab

    # login 2nd step (oauth)
    if $location.search().code?
      questionsAPI.auth($location.search().code).then (auth) ->
        $location.search('code',null)
        $location.path auth.redirect if auth.redirect?
        $scope.user = auth if auth.role?
      , (response) ->
        $location.search('code',null)
        $scope.user = response.data
]

controllers.controller 'HomeCtrl', [
  "$scope", "questionsAPI"
  ($scope, questionsAPI) ->
    $scope.sets = []
    $scope.languages = []
    $scope.authors = []
    $scope.questions = null
    $scope.filtered = []
    $scope.$on "$ionicView.enter", ->
      questionsAPI.questions().then (response) ->
        $scope.questions = response.data
        questionsAPI.filterQuestions().then (questions) -> $scope.filtered = questions
        for question in $scope.questions
          $scope.authors.push question.author unless question.author in $scope.authors
          for card in question.cards
            $scope.sets.push set for set in card when set not in $scope.sets
          for language in question.languages
            $scope.languages.push language if language not in $scope.languages
]

controllers.controller 'QuestionCtrl', [
  "$scope", "questionsAPI", "$stateParams", "$state", "$ionicScrollDelegate"
  ($scope, questionsAPI, $stateParams, $state, $ionicScrollDelegate) ->
    gatherer = 'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&'
    $scope.$on "$ionicView.enter", ->
      questionsAPI.question($stateParams.id).then (question) ->
        return $state.go "app.home" unless question.metadata?.id
        $scope.question = question
        for card in question.cards
          card.src = gatherer + 'name=' + card.name
          card.src = gatherer + 'name=' + card.full_name if card.layout in ["split","aftermath"]
          card.src = gatherer + 'multiverseid=' + card.multiverseid if card.multiverseid
          card.src = card.url if card.url
          # aftermath layout only for the second half of the card
          if card.layout is 'aftermath' and card.name_en is card.full_name.substr(0, card.name_en.length)
            card.layout = 'normal'
          card.manacost = (card.manacost or "")
          .replace /\{([cwubrgx0-9]+)\}/ig, (a,b) -> "<i class='mtg mana-#{b.toLowerCase()}'></i>"
          .replace /\{([2wubrg])\/([wubrg])\}/ig, (a,b,c) -> "<i class='mtg hybrid-#{(b+c).toLowerCase()}'></i>"
          card.text = (card.text or "")
          .replace /\{([cwubrgx0-9]+)\}/ig, (a,b) -> "<i class='mtg mana-#{b.toLowerCase()}'></i>"
          .replace /\{t\}/ig, "<i class='mtg tap'></i>"
          .replace /\{q\}/ig, "<i class='mtg untap'></i>"
          .replace /\{([2wubrg])\/([wubrg])\}/ig, (a,b,c) -> "<i class='mtg hybrid-#{(b+c).toLowerCase()}'></i>"
          .replace /(\(.*?\))/ig, '<em>$1</em>'
          question.question = question.question.replace RegExp("("+card.name+")", "ig"), "<b>$1</b>"
          question.answer = question.answer.replace RegExp("("+card.name+")", "ig"), "<b>$1</b>"
    $scope.toggleAnswer = ->
      $scope.answer = !$scope.answer
      $ionicScrollDelegate.resize()
      $ionicScrollDelegate.scrollBottom yes if $scope.answer
    $scope.$on 'keydown', (event, keycode) ->
      switch keycode
        when 37 then history.back()
        when 39 then $scope.next()
        when 38, 40 then $scope.toggleAnswer()
]

#########################################
#          Admin Controllers            #
#########################################
controllers.controller 'AdminNewCtrl', [
  "$scope", "questionsAPI", "$stateParams", "$window"
  ($scope, questionsAPI, $stateParams, $window) ->
    $scope.$on "$ionicView.enter", ->
      $scope.question =
        author: $scope.user.name
        difficulty: "1"
        cards: []
    $scope.add = -> $scope.question.cards.push {}
    # delete a card
    $scope.delete = (index) ->
      message = "Do you really want to delete '"+$scope.question.cards[index].name+"'?"
      if !$scope.question.cards[index].id or confirm message
        $scope.question.cards.splice index, 1
    # suggest cards
    $scope.suggest = (card) ->
      card.id = ""
      card.preview = no
      if card.name.length > 1
        questionsAPI.admin.suggest(card.name).then (response) ->
          card.suggestions = response.data
          card.id = card.suggestions[0].id if card.suggestions.length is 1
      else
        card.suggestions = []
    # select a suggested card
    $scope.select = (card, suggestion) ->
      card.name = suggestion.name
      card.id = suggestion.id
      delete card.suggestions
    # catch enter key in card fields
    $scope.keypress = (event, card) ->
      if event.keyCode is 13
        $scope.select card, card.suggestions[0] if card.suggestions?.length
        event.preventDefault()
    # change card order
    $scope.movecard = (index, direction) ->
      card = $scope.question.cards[index]
      $scope.question.cards[index] = $scope.question.cards[index+direction]
      $scope.question.cards[index+direction] = card
    # go back
    $scope.back = -> $window.history.back()
    # save question
    $scope.save = ->
      delete card.suggestions for card in $scope.question.cards
      questionsAPI.admin.save($scope.question).then (response) ->
        if response.data is "success"
          alert "Question submitted"
          questionsAPI.admin.clearShortCache()
          $scope.question =
            author: $scope.user.name
            difficulty: "1"
            cards: []
        else
          alert "Error when submitting question"
]

controllers.controller 'AdminQuestionsCtrl', [
  "$scope", "questionsAPI", "$stateParams", "$state"
  ($scope, questionsAPI, $stateParams, $state) ->
    # paging
    $scope.page = parseInt $stateParams.page, 10
    $scope.goto = ->
      page = prompt "Go to page"
      $state.go "app.admin.questions", page: page-1 if page > 0
    # load data
    $scope.questions = []
    $scope.reload = ->
      questionsAPI.admin.questions($scope.page).then (response) ->
        $scope.questions = response.data.questions
        $scope.pages = response.data.pages
      , ->
        questionsAPI.logout()
        $state.go "app.home"
    $scope.$on "$ionicView.enter", -> $scope.reload()
    $scope.languages = questionsAPI.languages()
    # toggle question live
    $scope.toggle = ({id, live}) -> questionsAPI.admin.save({id, live})
    # delete a question
    $scope.delete = (question) ->
      if confirm "Are you sure?"
        questionsAPI.admin.delete(question.id).then ->
          questionsAPI.admin.clearShortCache()
          question.deleted = yes
          $scope.reload()

]

controllers.controller 'AdminQuestionCtrl', [
  "$scope", "questionsAPI", "$stateParams", "$window", "$state"
  ($scope, questionsAPI, $stateParams, $window, $state) ->
    $scope.$on "$ionicView.enter", ->
      questionsAPI.admin.question($stateParams.id).then (response) ->
        $scope.question = response.data
      , ->
        questionsAPI.logout()
        $state.go "app.home"
    $scope.add = -> $scope.question.cards.push {}
    $scope.delete = (index) ->
      message = "Do you really want to delete "+$scope.question.cards[index].name+"?"
      if !$scope.question.cards[index].id or confirm message
        $scope.question.cards.splice index, 1
    # suggest cards
    $scope.suggest = (card) ->
      card.id = ""
      card.preview = no
      if card.name.length > 1
        questionsAPI.admin.suggest(card.name).then (response) ->
          card.suggestions = response.data
          card.id = card.suggestions[0].id if card.suggestions.length is 1
      else
        card.suggestions = []
    # select a suggested card
    $scope.select = (card, suggestion) ->
      card.name = suggestion.name
      card.id = suggestion.id
      delete card.suggestions
    # catch enter key in card fields
    $scope.keypress = (event, card) ->
      if event.keyCode is 13
        $scope.select card, card.suggestions[0] if card.suggestions?.length
        event.preventDefault()
    # change card order
    $scope.movecard = (index, direction) ->
      card = $scope.question.cards[index]
      $scope.question.cards[index] = $scope.question.cards[index+direction]
      $scope.question.cards[index+direction] = card
    # go back
    $scope.back = -> $window.history.back()
    # save the question
    $scope.save = ->
      delete card.suggestions for card in $scope.question.cards
      questionsAPI.admin.save($scope.question).then (response) ->
        if response.data is "success"
          questionsAPI.admin.clearMemoryCache()
          $scope.back()
        else
          alert "Error when saving question"
]

controllers.controller 'AdminTranslationsCtrl', [
  "$scope", "questionsAPI", "$state"
  ($scope, questionsAPI, $state) ->
    $scope.user = questionsAPI.user()
    $scope.selected =
      language: $scope.user?.languages[0] or $scope.languages[1].id
      search: ""
    if $scope.user? and $scope.user.languages.length
      $scope.languages = []
      $scope.languages.push language for language in questionsAPI.languages() when language.id in $scope.user.languages
    $scope.reload = (clear = no) ->
      $scope.translations = [] if clear
      $scope.selected.search = "" if clear
      questionsAPI.admin.translations($scope.selected.language).then (response) ->
        $scope.translations = response.data
      , ->
        questionsAPI.logout()
        $state.go "app.home"
    $scope.$on "$ionicView.enter", -> $scope.reload()
]

controllers.controller 'AdminTranslationCtrl', [
  "$scope", "$stateParams", "questionsAPI", "$window", "$state"
  ($scope, $stateParams, questionsAPI, $window, $state) ->
    $scope.$on "$ionicView.enter", ->
      questionsAPI.admin.translation($stateParams.language, $stateParams.id).then (response) ->
        $scope.translation = response.data
      , ->
        questionsAPI.logout()
        $state.go "app.home"
    $scope.language = language for language in $scope.languages when language.id is parseInt($stateParams.language, 10)
    $scope.back = -> $window.history.back()
    $scope.save = ->
      translation =
        id: $scope.translation.id
        language_id: $scope.translation.language_id
        question: $scope.translation.question_translated
        answer: $scope.translation.answer_translated
      questionsAPI.admin.translate(translation).then (response) ->
        if response.data is "success"
          questionsAPI.admin.clearMemoryCache()
          $scope.back()
        else
          alert "Error when saving question"
]

controllers.controller 'AdminUsersCtrl', [
  "$scope", "questionsAPI", "$state"
  ($scope, questionsAPI, $state) ->
    $scope.languages = []
    $scope.roles = ["admin", "editor", "translator", "guest"]
    $scope.languages[language.id] = language for language in questionsAPI.languages() when language.code isnt "en"
    $scope.$on "$ionicView.enter", ->
      questionsAPI.admin.users().then (response) ->
        $scope.users = response.data
      , ->
        questionsAPI.logout()
        $state.go "app.home"
    $scope.add = -> $scope.users.push edit: yes
    $scope.save = (index) ->
      questionsAPI.admin.saveUser($scope.users[index]).then ->
        $scope.users[index].edit = no
    $scope.delete = (index) ->
      return unless !$scope.users[index].email or confirm "Do you really want to delete this user?"
      questionsAPI.admin.deleteUser($scope.users[index].email).then ->
        $scope.users.splice index, 1
]
