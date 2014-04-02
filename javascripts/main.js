var spreadsheet = 'https://spreadsheets.google.com/feeds/cells/0Aig7p68d7NwYdFdhVVNHXzdDQ0Qwd0U3R0FNbkd6Ync/oda/public/values?alt=json-in-script&callback=?',
    temp = []
    questions = []
    current = 0;
$(function(){
  var cell;
	$.getJSON(spreadsheet, function(data){
    if(data.feed.entry.length > 0) {
      // parse questions
      for(var x = 0, y = data.feed.entry.length; x < y; x++) {
        cell = data.feed.entry[x];
        if(temp[cell['gs$cell'].row] == null) {
          temp[cell['gs$cell'].row] = [];
        }
        temp[cell['gs$cell'].row][cell['gs$cell'].col] = cell['gs$cell']['$t'];
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
            questions.push(question);  
          }
        }
      }
      $('.loading').fadeOut();
      if(window.location.hash) {
        showQuestion(window.location.hash.substr(1));
      } else {
        $('button.next').click();
      }
    }
  });
  $('button.answer').on('click',function(){
    $('div.answer').slideToggle();
  });
  $('button.next').on('click',function(){
    showQuestion(Math.round(Math.random()*(questions.length-1))+1);
  });
  $('.menu .print').on('click',function(){
    if(confirm("Are you sure? This will take several seconds per sheet to generate!")) {
      $('.buttons,.menu').hide();
      $('.loading').fadeIn();
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
                $('.content').remove();
                $('.loading').fadeOut();
                alert("Done! You can print the sheets now...");
              }
            },x*1000);
          })(x);
        }
      }  
    }
  });
  $(window).on('hashchange', function(){
    showQuestion(window.location.hash.substr(1));
  });
});

var showQuestion = function(index) {
  if(index == null) {
    index = current+1;
  }
  if(index != current && questions[index] != null) {
    $('.content').fadeOut(400, function(){
      current = parseInt(index,10);
      window.location.hash = index;
      renderQuestion(index);
      $('.content').fadeIn();
    });
  } else {
    console.log("invalid",index);
  }
}

function renderQuestion(index) {
  var q = questions[index];
  $('.content h1').text("Judge Booth: Question "+q['Number']);
  if(q['Author'] != null) {
    $('.content .author').show().text("Written by: "+q['Author']);  
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
        code += "<img src='http://gatherer.wizards.com/Handlers/Image.ashx?type=card&size=small&name="+escape(q['Card '+x])+"'>";
      }
      code += q['Card '+x];
      code += "</div>";
      $('.content .cards').append(code);
      q['Questions'] = q['Questions'].replace(new RegExp('('+escapeRegExp(q['Card '+x])+')','gi'),'<b>$1</b>');
      q['Answers'] = q['Answers'].replace(new RegExp('('+escapeRegExp(q['Card '+x])+')','gi'),'<b>$1</b>');
    }
  }
  $('.content .question').html(q['Questions']);
  $('.content div.answer').hide().html(q['Answers']);
}

function escapeRegExp(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}
