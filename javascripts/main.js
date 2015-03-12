var spreadsheet,
    language = location.pathname.split("/").pop().split(".").splice(1,1).pop(),
    temp = [],
    questions = [],
    questionMap = [],
    current = -1,
    difficulties = ["Easy", "Medium", "Hard"],
    offline = !navigator.onLine;
$(function(){
  var cell;
  switch(language) {
    case "zhs":
      spreadsheet = offline ? 'javascripts/questions.zhs.js' : 'https://spreadsheets.google.com/feeds/cells/0AqlIQacaL79AdDZoM0toVk5YTG9CWndTSldQODVuVlE/oda/public/values?alt=json-in-script&callback=?';
      break;
    case "zht":
      spreadsheet = offline ? 'javascripts/questions.zht.js' : 'https://spreadsheets.google.com/feeds/cells/0AvKY1T4Hb-_GdG1LZFhDNFpmcFNKZmt0LTZHcmllM2c/oda/public/values?alt=json-in-script&callback=?';
      break;
    case "ru":
      spreadsheet = offline ? 'javascripts/questions.ru.js' : 'https://spreadsheets.google.com/feeds/cells/0AqlIQacaL79AdFlCV2dOaTdzYlhsaHF3UVk0b2JlVVE/oda/public/values?alt=json-in-script&callback=?';
      break;
    case "fr":
      spreadsheet = offline ? 'javascripts/questions.fr.js' : 'https://spreadsheets.google.com/feeds/cells/0AqlIQacaL79AdDdEYVNaYWt3LUo0emxWenhMakRvYXc/oda/public/values?alt=json-in-script&callback=?';
      break;
    default:
      spreadsheet = offline ? 'javascripts/questions.en.js' : 'https://spreadsheets.google.com/feeds/cells/0Aig7p68d7NwYdFdhVVNHXzdDQ0Qwd0U3R0FNbkd6Ync/oda/public/values?alt=json-in-script&callback=?';
  }
	$.ajax({
    url: spreadsheet,
    dataType: "jsonp",
    jsonp: "callback",
    cache: "true",
    jsonpCallback: 'jsoncallback',
    success: function(data){
      if(data.feed.entry.length > 0) {
        // parse questions
        for(var x = 0, y = data.feed.entry.length; x < y; x++) {
          cell = data.feed.entry[x];
          if(temp[cell['gs$cell'].row] == null) {
            temp[cell['gs$cell'].row] = [];
          }
          temp[cell['gs$cell'].row][cell['gs$cell'].col] = cell['gs$cell']['$t'].trim();
        }
        // create questions table and filter invalid
        var map = [];
        for(var x = 0, y = temp.length; x < y; x++) {
          if(x == 1) {
            for(var column = 0; column < temp[x].length; column++) {
              if(temp[x][column] != undefined) map[column] = temp[x][column];
            }
          } else if(temp[x] != undefined) {
            var question = {};
            for(var column = 0; column < temp[x].length; column++) {
              if(temp[x][column] != undefined) question[map[column]] = temp[x][column];
            }
            if(question.Sheeted != null && question.Sheeted.toLowerCase().replace(/ /g,"") == "done") {
              questionMap[question['Number']] = questions.length;
              questions.push(question);
            }
          }
        }
        $('.loading').fadeOut();
        if(window.location.hash && questionMap[window.location.hash.substr(1)] != undefined) {
          showQuestion(questionMap[window.location.hash.substr(1)]);
        } else {
          $('button.next').click();
        }
      }
    }
  });
  // answer button
  $('button.answer').on('click',function(){
    $('.content').toggleClass('show-answer');
  });
  // next button
  $('button.next').on('click',function(){
    showQuestion(Math.round(Math.random()*(questions.length-1))+1);
  });
  // difficulty button
  $('.difficulty').on('click',function(){
    if(questions[current]["Difficulty"]) {
      var nextLevel = difficulties[(difficulties.indexOf(questions[current]["Difficulty"]) + 1) % difficulties.length],
          nextQuestions = [];
      for(var x=0; x<questions.length;x++) {
        if(x == current || questions[x]["Difficulty"] != nextLevel) continue;
        nextQuestions.push(x);
      }
      if(nextQuestions.length) showQuestion(nextQuestions[Math.floor(Math.random()*nextQuestions.length)]);
    }
  });
  // clicking on a card
  $('.cards').on('click','img',function(){
    $(this).clone().appendTo('body').addClass('fullcard').css({
      left: $(this).offset().left - (400 - $(this).width())/2,
      top: Math.max(10,$(this).offset().top - (567 - $(this).height())/2)
    }).fadeIn().on('click',function(){
      $(this).fadeOut(function(){
        $(this).remove();
      });
    });
  });
  // print mode
  $('.menu .print').on('click',function(){
    if(confirm("Are you sure? This will take several seconds per sheet to generate!")) {
      $('.buttons,.menu').hide();
      $('.loading').fadeIn();
      $('.content').css('display','');
      var last = 0;
      for(var x=0;x<questions.length;x++) {
        if(questions[x]) {
          last = x;
          (function(x) {
            setTimeout(function(){
              $('.loading').text("Rendering question "+(x+1)+" of "+(questions.length)+"...");
              renderQuestion(x);
              $('.content').clone().toggleClass('content copy').appendTo('body');  
              if(x == last) {
                var answers = $('.content').toggleClass('content answers').empty();
                for(var y=0;y<questions.length;y++) {
                  if(questions[y]) {
                    answers.append('<p><b>'+questions[y]['Number']+':</b> '+questions[y]['Answers']+'</p>');
                  }
                }
                $('.loading').text('Ready for printing. Click here to show answers').on('click', function(){
                  $('body').toggleClass('answers');
                  $('.loading').text($('body').hasClass('answers') ? 'Click here to show questions':'Click here to show answers')
                });
                setTimeout(function(){
                  window.print();
                }, 1000);
              }
            },x*1000);
          })(x);
        }
      }  
    }
  });
  // offline mode
  $('.menu .offline').on('click', function(){
    /*
    if(!$(this).hasClass('active') && confirm("Are you sure? This can take some minutes to download all data!")) {
      var cards = [];
      for(var x=0;x<questions.length;x++) {
        if(questions[x]) {
          for(var y=1;y<=5;y++) {
            if(questions[x]['Card '+y]) {
              var card = questions[x]['Card '+y].replace(/\/\/ /,'').toLowerCase();
              if(card.match(/([a-z]+) token/i) === null && cards.indexOf(card) == -1) {
                cards.push(card);
              }              
            }
          }
        }
      }
      if(cards.length) {
        cards.sort();
        var container = $("<div></div>").appendTo('body');
        for(var x=0;x<cards.length;x++) {
          container.append('<div>http://mtgimage.com/card/'+escape(cards[x].replace(/\/\/ /,''))+'.jpg</div>');
        }
      }
    }
    return false;
//    */
  });
  if(offline) updateOfflineStatus();
  applicationCache.addEventListener('progress', cacheProgress, false);
  applicationCache.addEventListener("error", function(e) { offline = true; updateOfflineStatus(); });
  applicationCache.addEventListener('cached', updateOfflineStatus, false);
  applicationCache.addEventListener('updateready', updateOfflineStatus, false);
  applicationCache.addEventListener('noupdate', updateOfflineStatus, false);

  // hash logic
  $(window).on('hashchange', function(){
    if(questionMap[window.location.hash.substr(1)] != undefined && questionMap[window.location.hash.substr(1)] != current) {
      showQuestion(questionMap[window.location.hash.substr(1)]);  
    }
  });
});

var updateOfflineStatus = function(e) {
  cache = (e ? e.target:false) || applicationCache;
  $('.menu .offline').attr('class','offline').toggleClass('active',offline).addClass('cache-'+cache.status);
  if(cache.status == cache.IDLE) $('.menu .offline span').text(100);
};

var cacheProgress = function(e) {
  cache = (e ? e.target:false) || applicationCache;
  $('.menu .offline').attr('class','offline').addClass('cache-'+cache.status);
  $('.menu .offline span').text(Math.round(e.loaded/ e.total*100));
};

var showQuestion = function(index) {
  if(index == null) {
    index = current+1;
  }
  if(index != current && questions[index] != null) {
    $('.fullcard').remove();
    $('.content').fadeOut(400, function(){
      current = parseInt(index,10);
      window.location.hash = questions[index]['Number'];
      renderQuestion(index);
      $('.content').removeClass('show-answer').fadeIn();
    });
  } else {
    console.log("invalid",index);
  }
};

function renderQuestion(index) {
  var q = questions[index];
  $('.content h1 span').text(q['Number']);
  $('.content .difficulty').attr('src','images/'+q['Difficulty'].toLowerCase()+'.png').toggle(!!q['Difficulty']);
  if(q['Author'] != null) {
    $('.content .author').show().find('span').text(q['Author']);  
  } else {
    $('.content .author').hide();
  }
  $('.content .cards .card').remove();
  for(var x=1;x<=5;x++) {
    if(q['Card '+x]) {
      var code = "<div class='card'>"; 
      if(q['Card '+x].match(/([a-z]+) token/i) != null) {
        code += "<img src='images/"+q['Card '+x].match(/([a-z]+) token/i)[1].toLowerCase()+".jpg'>";
      } else {
        code += "<img crossorigin='anonymous' src='http://gatherer.wizards.com/Handlers/Image.ashx?type=card&name="+escape(q['Card '+x].toLowerCase())+"'>";
      }
      code += q['Card '+x];
      code += "</div>";
      $('.content .cards').append(code);
      q['Questions'] = q['Questions'].replace(new RegExp('('+escapeRegExp(q['Card '+x])+')','gi'),'<b>$1</b>');
      q['Answers'] = q['Answers'].replace(new RegExp('('+escapeRegExp(q['Card '+x])+')','gi'),'<b>$1</b>');
    }
  }
  $('.content .question').html(q['Questions']);
  $('.content div.answer').html(q['Answers']);
}

function escapeRegExp(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}
