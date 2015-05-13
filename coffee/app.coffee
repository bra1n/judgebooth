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
    $locationProvider.html5Mode navigator.onLine
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
    .state 'app.admin.question', # all questions
      url: '/question/:id'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/question.html'
          controller: 'AdminQuestionCtrl'
    .state 'app.admin.translation', # translations
      url: '/translation/:id/:language'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/translation.html'
          controller: 'AdminTranslationCtrl'
    .state 'app.admin.user', # users
      url: '/user'
      views:
        'menuContent@app':
          templateUrl: 'views/admin/user.html'
          controller: 'AdminUserCtrl'
    $urlRouterProvider.otherwise '/'
]

boothApp.config [
  '$translateProvider', ($translateProvider) ->
    # detect language
    availableLanguages = ["en", "ru", "cn", "tw", "fr"]
    navigatorLanguage = (navigator.language or navigator.userLanguage)
    navigatorLanguage = navigatorLanguage.replace(/^zh_/i,'').toLowerCase().substr(0,2)
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
    $rootScope.$on '$stateChangeSuccess', (event, toState) -> $rootScope.state = toState
    $rootScope.next = -> questionsAPI.nextQuestion().then (id) ->  $state.go "app.question", {id}
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