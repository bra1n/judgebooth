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
    $locationProvider.html5Mode !ionic.Platform.isWebView()
    $stateProvider
    .state 'app',
      url: ''
      abstract: yes
      templateUrl: 'views/menu.html'
      controller: 'SideCtrl'
    .state 'app.home',
      url: '/'
      views:
        menuContent:
          templateUrl: 'views/home.html'
          controller: 'HomeCtrl'
    .state 'app.question',
      url: '/question/:id'
      views:
        menuContent:
          templateUrl: 'views/question.html'
          controller: 'QuestionCtrl'
    $urlRouterProvider.otherwise '/'
]

boothApp.config [
  '$translateProvider', ($translateProvider) ->
    # detect language
    availableLanguages = ["en", "ru", "cn", "tw", "fr"]
    navigatorLanguage = (navigator.language or navigator.userLanguage).toLowerCase().substr(0,2)
    language = "en"
    # todo: detect zh_cn/zh_tw languages correctly
    language = navigatorLanguage if navigatorLanguage in availableLanguages
    $translateProvider.useSanitizeValueStrategy 'escaped'
    $translateProvider.registerAvailableLanguageKeys availableLanguages
    .preferredLanguage language
    .fallbackLanguage 'en'
]

boothApp.run [
  'questionsAPI', '$rootScope', '$state'
  (questionsAPI, $rootScope, $state) ->
    $rootScope.$on '$stateChangeSuccess', (event, toState) -> $rootScope.state = toState
    $rootScope.next = -> questionsAPI.nextQuestion().then (id) ->  $state.go "app.question", {id}
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