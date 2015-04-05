boothApp = angular.module 'judgebooth', [
  'ionic'
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
    .state 'question',
      url: '/question/:id'
      templateUrl: 'views/question.html'
      controller: 'QuestionCtrl'
    $urlRouterProvider.otherwise '/'
]

boothApp.controller 'MainCtrl', [
  "$scope", "$ionicSideMenuDelegate"
  ($scope, $ionicSideMenuDelegate) ->
    console.log "MAIN; BABY"
    $scope.toggleLeft = -> $ionicSideMenuDelegate.toggleLeft()
]

boothApp.controller 'SideCtrl', [
  "$scope",
  ($scope) ->
    console.log "SIDE; BABY"

]

boothApp.controller 'HomeCtrl', [
  "$scope",
  ($scope) ->
    console.log "HOME; BABY"
]


boothApp.controller 'QuestionCtrl', [
  "$scope",
  ($scope) ->
    console.log "QUESTION TIME; BABY"
]