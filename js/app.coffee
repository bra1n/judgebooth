boothApp = angular.module 'judgebooth', [
  'ionic'
  'angular-cache'
  'pascalprecht.translate'
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

boothApp.service 'questionsAPI', [
  "$http", "CacheFactory", "$q"
  ($http, CacheFactory, $q) ->
    caches =
      persistent: CacheFactory 'persistentCache', # forever
        storageMode: 'localStorage'
      short: CacheFactory 'shortCache',
        maxAge: 24 * 3600 * 1000 # 24 hours
        storageMode: 'localStorage'
      memory: CacheFactory 'memoryCache',
        maxAge: 3600 * 1000 # 1 hour
        capacity: 20
    apiURL = "http://" + window.location.host + "/api.php?action="
    # service methods
    sets: -> $http.get apiURL + "sets", cache: caches.short
    questions: -> $http.get apiURL + "questions", cache: caches.short
    question: (id) ->
      deferred = $q.defer()
      questionPromise = $http.get apiURL + "question&lang=1&id=" + id, cache: caches.memory
      $q.all([@questions(), questionPromise]).then ([questionsResponse, questionResponse]) ->
        question = questionResponse.data
        question.metadata = metadata for metadata in questionsResponse.data when metadata.id is id
        deferred.resolve question
      , -> deferred.reject()
      deferred.promise

]

boothApp.controller 'SideCtrl', [
  "$scope", "questionsAPI"
  ($scope, questionsAPI) ->
    # todo handle filters
    questionsAPI.sets().then (response) -> $scope.sets = response.data
    questionsAPI.questions().then (response) -> $scope.questions = response.data
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