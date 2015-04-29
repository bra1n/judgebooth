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
    $rootScope.$on '$stateChangeSuccess', (event, toState) -> $rootScope.state = toState
    $rootScope.next = -> questionsAPI.nextQuestion().then (id) ->  $state.go "question", {id}
]

boothApp.controller 'SideCtrl', [
  "$scope", "questionsAPI"
  ($scope, questionsAPI) ->
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
]

boothApp.controller 'HomeCtrl', [
  "$scope", "questions", "sets"
  ($scope, questions, sets) ->
    $scope.questions = questions.data
    $scope.sets = sets.data
]

boothApp.controller 'QuestionCtrl', [
  "$scope", "question", "$state"
  ($scope, question, $state) ->
    $scope.question = question
    $state.go "home" unless question.metadata?.id
    $scope.showAnswer = -> $scope.answer = true
]