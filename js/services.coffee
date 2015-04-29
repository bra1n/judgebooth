services = angular.module "boothServices", []

services.service 'questionsAPI', [
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
    # get all sets
    sets: -> $http.get apiURL + "sets", cache: caches.short
    # list of available languages
    languages: -> [
      {id: 1,name: "English",code: "en"}
      {id: 2,name: "German",code: "de"}
      {id: 3,name: "Italian",code: "it"}
      {id: 4,name: "Japanese",code: "jp"}
      {id: 5,name: "Korean",code: "ko"}
      {id: 6,name: "Portuguese (Brazil)",code: "pt"}
      {id: 7,name: "Russian",code: "ru"}
      {id: 8,name: "Spanish",code: "es"}
      {id: 9,name: "Chinese Simplified",code: "cn"}
      {id: 10,name: "Chinese Traditional",code: "tw"}
      {id: 11,name: "French",code: "fr"}
    ]
    # get all questions with basic metadata
    questions: -> $http.get apiURL + "questions", cache: caches.short
    # get a single question with translations
    question: (id) ->
      deferred = $q.defer()
      questionPromise = $http.get apiURL + "question&lang=1&id=" + id, cache: caches.memory
      $q.all([@questions(), questionPromise]).then ([questionsResponse, questionResponse]) ->
        question = questionResponse.data
        question.metadata = metadata for metadata in questionsResponse.data when metadata.id is id
        deferred.resolve question
      , -> deferred.reject()
      deferred.promise
    # set or get the question filter
    filter: (filter) ->
      caches.persistent.put "filter", filter if filter?
      caches.persistent.get "filter"
    # filter all questions with the passed / cached filter
    filterQuestions: (filter = @filter()) ->
      console.log filter
      deferred = $q.defer()
      @questions().then (response) ->
        questions = response.data
        filteredQuestions = []
        for question in questions
          continue unless parseInt(filter.language, 10) in question.languages
          continue if filter.difficulty.length and question.difficulty in filter.difficulty
          if Object.keys(filter.sets).length
            # super complicated check to make sure that the question only contains cards which are allowed by the filter
            hasIllegalCard = no
            for card in question.cards
              isLegalCard = no
              isLegalCard = yes for set in card when !filter.sets[set]
              hasIllegalCard = !isLegalCard
              break if hasIllegalCard # we stop as soon as we find a single illegal card
            continue if hasIllegalCard
          filteredQuestions.push question.id
        deferred.resolve filteredQuestions
      , -> deferred.reject()
      deferred.promise
]