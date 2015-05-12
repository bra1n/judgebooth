services = angular.module "judgebooth.services", []

services.service 'questionsAPI', [
  "$http", "CacheFactory", "$q", "$translate"
  ($http, CacheFactory, $q, $translate) ->
    # vars
    caches =
      persistent: CacheFactory 'persistentCache', # forever
        storageMode: 'localStorage'
      short: CacheFactory 'shortCache',
        maxAge: 24 * 3600 * 1000 # 24 hours
        storageMode: 'localStorage'
      memory: CacheFactory 'memoryCache',
        maxAge: 3600 * 1000 # 1 hour
        capacity: 20
    availableLanguages = [
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
    apiURL = "http://" + window.location.host + "/backend/?action="
    # set app language from cache
    if caches.persistent.get "filter"
      for language in availableLanguages when language.id is parseInt caches.persistent.get("filter").language, 10
        $translate.use language.code
        break

    #################  API methods   ###################
    # get all sets
    sets: -> $http.get apiURL + "sets", cache: caches.short
    # list of available languages
    languages: -> availableLanguages
    # get all questions with basic metadata
    questions: -> $http.get apiURL + "questions", cache: caches.short
    # get a single question with translations
    question: (id) ->
      deferred = $q.defer()
      language = @filter().language
      if !navigator.onLine
        # we have internet access
        questionPromise = $http.get apiURL + "question&lang=" + language + "&id=" + id, cache: caches.memory
        $q.all([@questions(), questionPromise]).then ([questionsResponse, questionResponse]) ->
          question = questionResponse.data
          question.metadata = metadata for metadata in questionsResponse.data when metadata.id is parseInt(id, 10)
          deferred.resolve question
        , -> deferred.reject()
      else
        # we don't have internet access, use the offline endpoint
        questionPromise = $http.get apiURL + "offline", cache: caches.memory
        $q.all([@questions(), questionPromise]).then ([questionsResponse, questionResponse]) ->
          if questionResponse.data.questions[id]
            question = questionResponse.data.questions[id][language] or questionResponse.data.questions[id][1]
            question.cards = []
            for cardId in questionResponse.data.questions[id].cards
              card = questionResponse.data.cards[cardId]
              card.name_en = card.name
              card.name = card.translations[language] if card.translations?[language]
              question.cards.push card
            question.metadata = metadata for metadata in questionsResponse.data when metadata.id is parseInt(id, 10)
            deferred.resolve question
          else
            deferred.reject()
        , -> deferred.reject()
      deferred.promise
    # set or get the question filter
    # purge cached filtered question lists when updating the filter
    filter: (filter) ->
      currentLanguage = language.id for language in @languages() when language.code is $translate.use()
      filterDefault =
        language: currentLanguage
        sets: []
        difficulty: []
      if filter?
        console.log "filter set", filter
        for language in availableLanguages when language.id is parseInt filter.language, 10
          console.log "use", language.code
          $translate.use language.code
        caches.persistent.put "filter", filter
        caches.memory.remove "filteredQuestions"
      caches.persistent.get("filter") or filterDefault
    # filter all questions with the passed / cached filter
    # return an array of question IDs
    filterQuestions: (filter, useCache = yes) ->
      deferred = $q.defer()
      if useCache and caches.memory.get "filteredQuestions"
        deferred.resolve caches.memory.get "filteredQuestions"
      else
        filter or= @filter()
        @questions().then (response) ->
          questions = response.data
          filteredQuestions = []
          for question in questions
            continue unless parseInt(filter.language, 10) in question.languages
            continue if filter.difficulty.length and question.difficulty in filter.difficulty
            if filter.sets.length
              # super complicated check to make sure that the question only contains cards which are allowed by the filter
              hasIllegalCard = no
              for card in question.cards
                isLegalCard = no
                isLegalCard = yes for set in card when set not in filter.sets
                hasIllegalCard = !isLegalCard
                break if hasIllegalCard # we stop as soon as we find a single illegal card
              continue if hasIllegalCard
            filteredQuestions.push question.id
          # shuffle questions - https://gist.github.com/ddgromit/859699
          i = filteredQuestions.length
          while --i > 0
            j = ~~(Math.random() * (i + 1))
            t = filteredQuestions[j]
            filteredQuestions[j] = filteredQuestions[i]
            filteredQuestions[i] = t
          caches.memory.put "filteredQuestions", filteredQuestions if useCache
          deferred.resolve filteredQuestions
        , -> deferred.reject()
      deferred.promise
    # get next question ID
    nextQuestion: ->
      deferred = $q.defer()
      @filterQuestions().then (questions) ->
        questions.push questions.shift()
        caches.memory.put "filteredQuestions", questions
        deferred.resolve questions[0]
      , -> deferred.reject()
      deferred.promise
]