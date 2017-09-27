boothApp = angular.module 'judgebooth', [
  'ionic'
  'angular-cache'
  'pascalprecht.translate'
  'judgebooth.services'
  'judgebooth.controllers'
  'judgebooth.translations'
]

boothApp.config [
  '$locationProvider', '$stateProvider', '$urlRouterProvider'
  ($locationProvider, $stateProvider, $urlRouterProvider) ->
    $locationProvider.html5Mode !window.offlineMode and navigator.onLine
    $stateProvider
    # base app route
    .state 'app',
      url: ''
      abstract: yes
      templateUrl: 'views/menu.html'
      controller: 'SideCtrl'
    .state 'app.home', # home screen
      url: '/'
      views:
        menuContent:
          templateUrl: 'views/home.html'
          controller: 'HomeCtrl'
    .state 'app.question', # show a question
      url: '/question/:id'
      views:
        menuContent:
          templateUrl: 'views/question.html'
          controller: 'QuestionCtrl'
    # admin routes
    .state 'app.admin',
      url: '/admin'
      abstract: yes
    .state 'app.admin.new', # new question
      url: '/new'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/new.html'
          controller: 'AdminNewCtrl'
    .state 'app.admin.questions', # all questions
      url: '/questions/:page'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/questions.html'
          controller: 'AdminQuestionsCtrl'
    .state 'app.admin.question', # single question
      url: '/question/:id'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/question.html'
          controller: 'AdminQuestionCtrl'
    .state 'app.admin.translations', # translations
      url: '/translations'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/translations.html'
          controller: 'AdminTranslationsCtrl'
    .state 'app.admin.translation', # single translation
      url: '/translation/:language/:id'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/translation.html'
          controller: 'AdminTranslationCtrl'
    .state 'app.admin.users', # users
      url: '/users'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/users.html'
          controller: 'AdminUsersCtrl'
    $urlRouterProvider.otherwise '/'
]

boothApp.config [
  '$translateProvider', ($translateProvider) ->
    # detect language
    availableLanguages = ["en", "br", "ru", "cn", "tw", "fr", "pt", "es", "jp", "de", "it"]
    navigatorLanguage = (navigator.language or navigator.userLanguage)
    navigatorLanguage = navigatorLanguage.replace(/^(zh|pt)_/i,'').toLowerCase().substr(0,2)
    language = "en"
    language = navigatorLanguage if navigatorLanguage in availableLanguages
    $translateProvider.useSanitizeValueStrategy 'escaped'
    $translateProvider.registerAvailableLanguageKeys availableLanguages
    .preferredLanguage language
    .fallbackLanguage 'en'
]

boothApp.run [
  'questionsAPI', '$rootScope', '$state', '$ionicPlatform', '$window'
  (questionsAPI, $rootScope, $state, $ionicPlatform, $window) ->
    # keep current state name in a global variable
    $rootScope.$on '$stateChangeSuccess', (event, toState) -> $rootScope.state = toState
    # go to next question
    $rootScope.next = -> questionsAPI.nextQuestion().then (id) ->  $state.go "app.question", {id}
    # catch global keyboard events and pass them down the scope hierarchy
    $rootScope.keydown = ({keyCode}) -> $rootScope.$broadcast "keydown", keyCode
    $ionicPlatform.ready ->
      $rootScope.online = navigator.onLine
      appCache = $window.applicationCache
      appCache.addEventListener 'progress', -> $rootScope.cacheStatus = appCache.status
      appCache.addEventListener 'error', -> $rootScope.$apply -> $rootScope.cacheStatus = appCache.status
      appCache.addEventListener 'cached', -> $rootScope.$apply -> $rootScope.cacheStatus = appCache.status
      appCache.addEventListener 'updateready', -> $rootScope.$apply -> $rootScope.cacheStatus = appCache.status
      appCache.addEventListener 'noupdate', -> $rootScope.$apply -> $rootScope.cacheStatus = appCache.status
]

boothApp.directive 'ngLoad', [
  '$parse', ($parse) ->
    restrict: 'A'
    compile: ($element, attr) ->
      fn = $parse attr['ngLoad']
      (scope, element, attr) ->
        element.on 'load', (event) ->
          scope.$apply -> fn scope, $event:event
]