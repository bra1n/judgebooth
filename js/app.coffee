boothApp = angular.module 'judgebooth', [
  'ionic'
  'angular-cache'
  'pascalprecht.translate'
  'boothServices'
]

boothApp.config [
  '$locationProvider', '$stateProvider', '$urlRouterProvider'
  ($locationProvider, $stateProvider, $urlRouterProvider) ->
    $locationProvider.html5Mode !ionic.Platform.isWebView()
    $stateProvider
    .state 'home',
      url: '/'
      templateUrl: 'views/home.html'
      controller: 'HomeCtrl'
      resolve:
        questions: ['questionsAPI', (questionsAPI) -> questionsAPI.questions()]
        sets: ['questionsAPI', (questionsAPI) -> questionsAPI.sets()]
    .state 'question',
      url: '/question/:id'
      templateUrl: 'views/question.html'
      controller: 'QuestionCtrl'
      resolve:
        question: [
          'questionsAPI', '$stateParams', (questionsAPI, $stateParams) -> questionsAPI.question($stateParams.id)
        ]
    $urlRouterProvider.otherwise '/'
]

boothApp.run [
  'questionsAPI', '$rootScope', '$state'
  (questionsAPI, $rootScope, $state) ->
    $rootScope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      $rootScope.state = toState
    $rootScope.next = ->
      # todo move to service
      questionsAPI.questions().then (response) ->
        questions = response.data
        $state.go "question", id: questions[Math.floor(Math.random()*questions.length)].id
]

boothApp.controller 'SideCtrl', [
  "$scope", "questionsAPI"
  ($scope, questionsAPI) ->
    # get data
    $scope.languages = questionsAPI.languages()
    $scope.languageCounts = {}
    questionsAPI.sets().then (response) -> $scope.sets = response.data
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

    $scope.filter =
      language: 1
      sets: {}
      difficulty: []

    # filter out a single set or many of them
    $scope.toggleSet = (id) ->
      switch id
        when "all" then $scope.filter.sets = {}
        when "standard" then $scope.filter.sets[set.id] = !set.standard for set in $scope.sets
        when "modern" then $scope.filter.sets[set.id] = !set.modern for set in $scope.sets
        when "none" then $scope.filter.sets[set.id] = yes for set in $scope.sets
        else $scope.filter.sets[id] = !$scope.filter.sets[id]
      $scope.updateCount()

    $scope.toggleDifficulty = (level) ->
      if level in $scope.filter.difficulty
        $scope.filter.difficulty.splice $scope.filter.difficulty.indexOf(level), 1
      else
        $scope.filter.difficulty.push level
      $scope.updateCount()

    $scope.updateCount = ->
      questionsAPI.filterQuestions($scope.filter).then (questions) -> $scope.count = questions.length
      # calculate number of valid sets for this language
      $scope.setCount = Object.keys($scope.setCounts[$scope.filter.language]).length
      $scope.setCount-- for set, isOn of $scope.filter.sets when isOn and $scope.setCounts[$scope.filter.language][set]
]

boothApp.controller 'HomeCtrl', [
  "$scope", "questions", "sets"
  ($scope, questions, sets) ->
    $scope.questions = questions.data
    $scope.sets = sets.data
]


boothApp.controller 'QuestionCtrl', [
  "$scope", "question"
  ($scope, question) ->
    $scope.question = question
    $scope.showAnswer = -> $scope.answer = true
]