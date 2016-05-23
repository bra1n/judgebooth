services = angular.module "judgebooth.services", []

services.service 'questionsAPI', [
  "$http", "CacheFactory", "$q", "$translate", "$location"
  ($http, CacheFactory, $q, $translate, $location) ->
    # vars
    caches =
      persistent: CacheFactory 'persistentCache', # forever
        storageMode: 'localStorage'
      short: CacheFactory 'shortCache',
        maxAge: 24 * 3600 * 1000 # 24 hours
        storageMode: 'localStorage'
        deleteOnExpire: 'passive'
      session: CacheFactory 'sessionCache',
        storageMode: 'sessionStorage' # session cache
      memory: CacheFactory 'memoryCache',
        maxAge: 3600 * 1000 # 1 hour
        capacity: 20
        deleteOnExpire: 'passive'
    availableLanguages = [
      {id:  1, code: "en", name: "English"}
      {id:  2, code: "de", name: "German"}
      {id:  3, code: "it", name: "Italian"}
      {id:  4, code: "jp", name: "Japanese"}
      {id:  5, code: "ko", name: "Korean"}
      {id:  6, code: "br", name: "Portuguese (Brazil)"}
      {id:  7, code: "ru", name: "Russian"}
      {id:  8, code: "es", name: "Spanish"}
      {id:  9, code: "cn", name: "Chinese Simplified"}
      {id: 10, code: "tw", name: "Chinese Traditional"}
      {id: 11, code: "fr", name: "French"}
      {id: 12, code: "pt", name: "Portuguese (Portugal)"}
    ]
    apiURL = "backend/?action="
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
      if navigator.onLine
        # we have internet access
        $http.get(apiURL + "question&lang=" + language + "&id=" + id, cache: caches.memory).then (questionResponse) ->
          question = questionResponse.data
          question.language = language
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
            question.language = language
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
        $translate.use language.code for language in availableLanguages when language.id is parseInt filter.language, 10
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
        @questions().then (response) =>
          questions = response.data
          questionsByDifficulty = []
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
            questionsByDifficulty[question.difficulty] or= []
            questionsByDifficulty[question.difficulty].push question.id
          filteredQuestions = []
          for questions, difficulty in questionsByDifficulty
            questions = @randomize questions
            filteredQuestions[index*questionsByDifficulty.length+difficulty] = question for question, index in questions
          filteredQuestions = filteredQuestions.filter (v) -> v isnt undefined
          caches.memory.put "filteredQuestions", filteredQuestions if useCache
          deferred.resolve filteredQuestions
        , -> deferred.reject()
      deferred.promise

    # get next question ID
    nextQuestion: ->
      deferred = $q.defer()
      @filterQuestions().then (questions) ->
        question = questions[0]
        questions.push questions.shift()
        caches.memory.put "filteredQuestions", questions
        deferred.resolve question
      , -> deferred.reject()
      deferred.promise

    ### admin stuff ###

    # get user
    user: -> caches.session.get "user"

    # logout user
    logout: ->
      $http.get apiURL + "logout"
      caches.session.remove "user"
      caches.session.remove "loginRedirect"

    # login user
    auth: (token) ->
      deferred = $q.defer()
      url = apiURL + "auth"
      if token
        url+= "&token=" + encodeURIComponent(token)
      else
        caches.session.put "loginRedirect", $location.path()
      $http.get(url).then (response) ->
        if response.data.role?
          caches.session.put 'user', response.data
          response.data.redirect = caches.session.get "loginRedirect"
          caches.session.remove "loginRedirect"
        deferred.resolve response.data
      , (response) -> deferred.reject response
      deferred.promise

    # randomize array - https://gist.github.com/ddgromit/859699
    randomize: (arr = []) ->
      i = arr.length
      while --i > 0
        j = ~~(Math.random() * (i + 1))
        t = arr[j]
        arr[j] = arr[i]
        arr[i] = t
      arr

    # admin API
    admin:
      questions: (page) -> $http.get apiURL + "admin-questions&page="+page
      question: (id) -> $http.get apiURL + "admin-question&id="+id
      suggest: (name) -> $http.get apiURL + "admin-suggest&name="+name
      save: (question) -> $http.post apiURL + "admin-save", question
      delete: (id) -> $http.post apiURL + "admin-delete&id="+id
      translations: (language) -> $http.get apiURL + "admin-translations&lang=" + language
      translation: (language, id) -> $http.get apiURL + "admin-translation&lang="+language+"&id="+id
      translate: (translation) -> $http.post apiURL + "admin-translate", translation
      users: -> $http.get apiURL + "admin-users"
      saveUser: (user) -> $http.post apiURL + "admin-saveuser", user
      deleteUser: (email) -> $http.post apiURL + "admin-deleteuser&email="+encodeURIComponent(email)
      clearMemoryCache: -> caches.memory.removeAll()
      clearShortCache: -> caches.short.removeAll()
]