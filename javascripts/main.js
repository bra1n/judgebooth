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
      // filter invalid
      for(var x = 0, y = temp.length; x < y; x++) {
        if(temp[x] != undefined && temp[x][2] != null && temp[x][2].toLowerCase().replace(/ /g,"") == "done") {
          questions.push(temp[x]);
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
    $(this).addClass('hidden');
    $('div.answer').slideDown();
  });
  $('button.next').on('click',function(){
    showQuestion(Math.round(Math.random()*(questions.length-1))+1);
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
      var q = questions[index];
      $('h1').text("Judge Booth: Question "+q[1]);
      $('button.answer').removeClass('hidden');
      if(q[11] != null) {
        $('.author').show().text("Written by: "+q[11]);  
      } else {
        $('.author').hide();
      }
      $('.cards').empty();
      for(var x=0;x<5;x++) {
        if(q[4+x]) {
          var code = "<div class='card'>"; 
          if(q[4+x].match(/([a-z]+) token/i) != null) {
            code += "<img src='images/"+q[4+x].match(/([a-z]+) token/i)[1].toLowerCase()+".jpg'>";
          } else {
            code += "<img src='http://gatherer.wizards.com/Handlers/Image.ashx?type=card&size=small&name="+escape(q[4+x])+"'>";
          }
          code += q[4+x];
          code += "</div>";
          $('.cards').append(code);
          q[9] = q[9].replace(new RegExp('('+escapeRegExp(q[4+x])+')','gi'),'<b>$1</b>');
          q[10] = q[10].replace(new RegExp('('+escapeRegExp(q[4+x])+')','gi'),'<b>$1</b>');
        }
      }
      $('.question').html(q[9]);
      $('div.answer').hide().html(q[10]);
      $('.content').fadeIn();
    });
  } else console.log("invalid",index);
}

function escapeRegExp(str) {
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}
