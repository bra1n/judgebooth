controllers = angular.module "judgebooth.controllers", []

controllers.controller 'SideCtrl', [
  "$scope", "questionsAPI", "$ionicScrollDelegate", "$location"
  ($scope, questionsAPI, $ionicScrollDelegate, $location) ->
    # get data
    $scope.filter = questionsAPI.filter()
    $scope.languages = questionsAPI.languages()
    $scope.languageCounts = {}
    questionsAPI.sets().then (response) -> $scope.sets = response.data
    # get questions and generate maps with counts
    questionsAPI.questions().then (response) ->
      $scope.questions = response.data
      $scope.setCounts = {}
      for question in $scope.questions
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
      $scope.setCount = Object.keys($scope.setCounts[$scope.filter.language]).length
      $scope.setCount-- for set in $scope.filter.sets when $scope.setCounts[$scope.filter.language][set]

    $scope.showQuestions = ->
      return unless $scope.filteredQuestions.length
      questionsAPI.filter $scope.filter
      $scope.next()

    # auth handling
    $scope.tab = "filter"
    $scope.user = questionsAPI.user()
    $scope.login = ->
      questionsAPI.auth().then (auth) ->
        window.location.href = auth.login if auth.login?
        $scope.user = auth if auth.name?
    $scope.logout = ->
      questionsAPI.logout()
      $scope.user = false
      $scope.tab = "filter"
    $scope.toggleTab = (tab) -> $scope.tab = tab
    if $location.search().code?
      questionsAPI.auth($location.search().code).then (auth) ->
        $location.search('code',null)
        if auth.status is "success"
          questionsAPI.auth().then (auth) ->
            $scope.user = auth if auth.name?
        else
          $scope.user = auth
]

controllers.controller 'HomeCtrl', [
  "$scope", "questionsAPI"
  ($scope, questionsAPI) ->
    $scope.sets = []
    $scope.languages = []
    $scope.authors = []
    $scope.questions = []
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
    gatherer = 'http://gatherer.wizards.com/Handlers/Image.ashx?type=card&name='
    questionsAPI.question($stateParams.id).then (question) ->
      $scope.question = question
      for card in question.cards
        card.src = gatherer + card.name
        card.src = gatherer + card.full_name if card.layout is "split"
        card.src = card.url if card.url
        card.manacost = (card.manacost or "")
        .replace /\{([wubrgx0-9]+)\}/ig, (a,b) -> "<i class='mtg mana-#{b.toLowerCase()}'></i>"
        .replace /\{([2wubrg])\/([wubrg])\}/ig, (a,b,c) -> "<i class='mtg hybrid-#{(b+c).toLowerCase()}'></i>"
        card.text = (card.text or "")
        .replace /\{([wubrgx0-9]+)\}/ig, (a,b) -> "<i class='mtg mana-#{b.toLowerCase()}'></i>"
        .replace /\{t\}/ig, "<i class='mtg tap'></i>"
        .replace /\{q\}/ig, "<i class='mtg untap'></i>"
        .replace /\{([2wubrg])\/([wubrg])\}/ig, (a,b,c) -> "<i class='mtg hybrid-#{(b+c).toLowerCase()}'></i>"
        .replace /(\(.*?\))/ig, '<em>$1</em>'
        question.question = question.question.replace RegExp("("+card.name+")", "ig"), "<b>$1</b>"
        question.answer = question.answer.replace RegExp("("+card.name+")", "ig"), "<b>$1</b>"
      $state.go "home" unless question.metadata?.id
    $scope.toggleAnswer = ->
      $scope.answer = !$scope.answer
      $ionicScrollDelegate.resize()
      $ionicScrollDelegate.scrollBottom yes
]

controllers.controller 'AdminNewCtrl', [
  "$scope"
  ($scope) ->
    console.log "AdminNewCtrl"
]

controllers.controller 'AdminQuestionCtrl', [
  "$scope"
  ($scope) ->
    console.log "AdminQuestionCtrl"
]

controllers.controller 'AdminTranslationCtrl', [
  "$scope"
  ($scope) ->
    console.log "AdminTranslationCtrl"
]

controllers.controller 'AdminUserCtrl', [
  "$scope"
  ($scope) ->
    console.log "AdminUserCtrl"
]