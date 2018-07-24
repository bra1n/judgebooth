<?php
require("config.php");
if(php_sapi_name() != "cli") exit;
if(count($_SERVER['argv']) < 2) die("possible arguments: sets, cards, questions, cardtranslations, tokens, questiontranslations\n");
ini_set('memory_limit', '1024M');
ini_set('max_execution_time', '0');
$db = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
$db->set_charset("utf8");
$argv = strtolower($_SERVER['argv'][1]);

#/*------- card data --------
// Sets
if($argv == "sets") {
  $sets = json_decode(file_get_contents("https://mtgjson.com/json/SetList.json"));
  echo "loaded ".count($sets)." sets\n";
  foreach($sets as $set) {
    $query = "name='".$db->real_escape_string($set->name)."',";
    if(isset($set->gathererCode)) {
      $query .= "code='".$db->real_escape_string($set->gathererCode)."',";
    } else {
      $query .= "code='".$db->real_escape_string($set->code)."',";
    }
    $query .= "releasedate='".$db->real_escape_string($set->releaseDate)."'";
    $query = "INSERT INTO sets SET $query ON DUPLICATE KEY UPDATE $query";
    $db->query($query) or die($db->error." ".$query);
  }
}
#*/

#/*
// Card texts, translations and printings
if($argv == "cards") {
  $cards = json_decode(file_get_contents("http://mtgjson.com/json/AllCards-x.json"));
  echo "loaded ".count((array) $cards)." cards\n";

  foreach($cards as $card) {
    $query = "name='".$db->real_escape_string($card->name)."',";
    if(isset($card->manaCost)) $query .= "manacost='".$db->real_escape_string($card->manaCost)."',";
    if(isset($card->type)) $query .= "type='".$db->real_escape_string($card->type)."',";
    if(isset($card->text)) $query .= "text='".$db->real_escape_string($card->text)."',";
    if(isset($card->loyalty)) $query .= "loyalty='".$db->real_escape_string($card->loyalty)."',";
    if(isset($card->power)) $query .= "power='".$db->real_escape_string($card->power)."',";
    if(isset($card->toughness)) $query .= "toughness='".$db->real_escape_string($card->toughness)."',";
    $query .= "layout='".$db->real_escape_string($card->layout)."'";
    if(isset($card->names)) $query .= ", full_name='".$db->real_escape_string(join(" // ",$card->names))."'";
    $query = "INSERT INTO cards SET $query ON DUPLICATE KEY UPDATE $query";
    $db->query($query) or die($db->error);
    $result = $db->query("SELECT id FROM cards WHERE name = '".$db->real_escape_string($card->name)."' LIMIT 1");
    while($row = $result->fetch_assoc()) {
      $card->id = $row['id'];
    }
    $result->free();

    # printings
    foreach($card->printings as $printing) {
      $result = $db->query("SELECT id FROM sets WHERE code = '".$db->real_escape_string($printing)."' LIMIT 1");
      while($row = $result->fetch_assoc()) {
        $db->query("INSERT IGNORE INTO card_sets SET card_id='".$card->id."', set_id='".$row['id']."'") or die($db->error);
      }
      $result->free();
    }
    # translations - currently doesnt work
    if(isset($card->foreignNames) && count($card->foreignNames)) {
      foreach($card->foreignNames as $translation) {
        $result = $db->query("SELECT id FROM languages WHERE name = '".$db->real_escape_string($translation->language)."' LIMIT 1");
        while($row = $result->fetch_assoc()) {
          $db->query("INSERT IGNORE INTO card_translations SET card_id='".$card->id."', language_id='".$row['id']."', name='".$db->real_escape_string($translation->name)."', multiverseid='".$db->real_escape_string($translation->multiverseid)."'");
        }
        $result->free();
      }
    }
  }

  // mirror PT-BR (6) to PT-PT (12)
  $db->query("REPLACE INTO card_translations SELECT card_id, 12 AS language_id, name, multiverseid FROM `card_translations` WHERE language_id = 6");
}
#*/

#/*
// Card translations
if($argv == "cardtranslations") {
  $sets = json_decode(file_get_contents("http://mtgjson.com/json/AllSets-x.json"));
  echo "loaded ".count((array) $sets)." sets\n";

  $result = $db->query("SELECT name, id FROM languages");
  $languages = array();
  while($row = $result->fetch_assoc()) {
    $languages[$row['name']] = $row['id'];
  }
  $result->free();

  foreach($sets as $set) {
    echo "loaded ".count((array) $set->cards)." cards from ".$set->name."\n";
    foreach($set->cards as $card) {
      $result = $db->query("SELECT id FROM cards WHERE name = '".$db->real_escape_string($card->name)."' LIMIT 1");
      while($row = $result->fetch_assoc()) {
        $card->id = $row['id'];
      }
      $result->free();
      # multiverse id
      if(isset($card->multiverseid)) {
	      if ($db->query("UPDATE cards SET multiverseid = '".$db->real_escape_string($card->multiverseid)."' WHERE id = '".$card->id."' and multiverseid < '".$db->real_escape_string($card->multiverseid)."'") === TRUE) {
            if ($db->affected_rows) {
			  echo "Record updated successfully for ".$db->real_escape_string($card->name) . " -> " .$db->real_escape_string($card->multiverseid)." (newer multiverseid)\n";
			}
          } else {
            echo "Error updating record: " . $conn->error;
          };
      }

      # translations
      if(isset($card->foreignNames) && count($card->foreignNames)) {
        foreach($card->foreignNames as $translation) {
	      if(isset($languages[$translation->language])) {
			# Look for multiverseid
			$act_multiverseid = 0;
		    $result = $db->query("SELECT multiverseid FROM card_translations WHERE card_id='".$card->id."' and language_id='".$languages[$translation->language]."' LIMIT 1");
            while($row = $result->fetch_assoc()) {
              $act_multiverseid = $row['multiverseid'];
            }
            $result->free();
            $query = "REPLACE INTO card_translations 
                      SET card_id='".$card->id."', 
                      language_id='".$languages[$translation->language]."', 
                      name='".$db->real_escape_string($translation->name)."'";
            if(isset($translation->multiverseid) and ($act_multiverseid < $translation->multiverseid)) {
              $query .= ", multiverseid='".$db->real_escape_string($translation->multiverseid)."'";
			  echo "Updating translation '".$db->real_escape_string($translation->name)."' from multiverseid=".$act_multiverseid." to ".$translation->multiverseid."\n";
            } else {
			  if ($act_multiverseid) {
			    $query .= ", multiverseid='".$db->real_escape_string($act_multiverseid)."'";
			  }
			}
            $db->query($query);
          }
        }
      }
    }
  }

  // mirror PT-BR (6) to PT-PT (12)
  $db->query("REPLACE INTO card_translations SELECT card_id, 12 as language_id, name, multiverseid FROM `card_translations` WHERE language_id = 6");
}
#*/

#/*
// Tokens
if($argv == "tokens") {
  $tokens = json_decode(file_get_contents("tokens.json"));
  echo "loaded ".count($tokens)." tokens\n";

  foreach($tokens as $token) {
    $query = "name='".$db->real_escape_string($token->name)."',
    layout='".$db->real_escape_string($token->layout)."',
    url='".$db->real_escape_string($token->url)."',
    type='".$db->real_escape_string($token->type)."',
    text='".$db->real_escape_string(isset($token->text) ? $token->text:"")."',
    power='".$db->real_escape_string($token->power)."',
    toughness='".$db->real_escape_string($token->toughness)."'";
    $query = "INSERT INTO cards SET $query ON DUPLICATE KEY UPDATE $query";
    $db->query($query) or die($db->error);
    // get ID
    $result = $db->query("SELECT id FROM cards WHERE name = '".$db->real_escape_string($token->name)."' LIMIT 1");
    while($row = $result->fetch_assoc()) {
      $token->id = $row['id'];
    }
    $result->free();
    if(isset($token->translations)) {
      foreach($token->translations as $language=>$translation) {
        $db->query("REPLACE INTO card_translations SET card_id='".$token->id."', language_id='".$language."', name='".$db->real_escape_string($translation)."'");
      }
    }
  }
}
#*/

#/* Import english question base
if($argv == "questions") {
  $questions = json_decode(file_get_contents("https://spreadsheets.google.com/feeds/cells/0Aig7p68d7NwYdFdhVVNHXzdDQ0Qwd0U3R0FNbkd6Ync/oda/public/values?alt=json"));
  echo count($questions->feed->entry)." cells loaded\n";
  $questionsArray = array();
  foreach($questions->feed->entry as $cell) {
    $cell = $cell->{'gs$cell'};
    if(!isset($questionsArray[$cell->row])) $questionsArray[$cell->row] = array();
    $questionsArray[$cell->row][$cell->col] = $cell->{'$t'};
  }
  foreach($questionsArray as $row) {
    if($row[1] == "Number") continue;
    $id = $row[1];
    $live = isset($row[2]) && $row[2] ? 1:0;
    $cards = array();
    for($x = 4;$x<9; $x++) {
      if(isset($row[$x]) && $row[$x]) {
        if(strstr($row[$x],"//") > -1) {
          foreach(explode("//",$row[$x]) as $card) {
            array_push($cards, $db->real_escape_string(trim($card)));
          }
        } else {
          array_push($cards, $db->real_escape_string(trim($row[$x])));
        }
      }
    }
    $question = $db->real_escape_string($row[9]);
    $answer = $db->real_escape_string($row[10]);
    if(!isset($row[11])) $row[11] = null;
    $author = $db->real_escape_string($row[11]);
    $difficulty = array_search(strtolower($row[12]),array("easy","medium","hard"));
    $questionQuery = "id='".$id."', live='".$live."', author='".$author."', difficulty='".$difficulty."'";
    $db->query("INSERT INTO questions SET $questionQuery ON DUPLICATE KEY UPDATE $questionQuery") or die($db->error);
    $db->query("REPLACE INTO question_translations SET question_id='".$id."', language_id='1', question='".$question."', answer='".$answer."'") or die($db->error);
    foreach($cards as $card) {
      $card = str_replace(" token", "", $card);
      $result = $db->query("SELECT * FROM cards WHERE name = '".$card."' LIMIT 1");
      $row = $result->fetch_assoc();
      if(isset($row['id'])) {
        $db->query("REPLACE INTO question_cards SET question_id='".$id."', card_id='".$row['id']."'") or die($db->error);
      } else {
        die("can't find card ".$card."\n");
      }
      $result->free();
    }
  }
}
#*/

#/* Import translations
if($argv == "questiontranslations") {
  $translations = array(
    "cn" => 'https://spreadsheets.google.com/feeds/cells/0AqlIQacaL79AdDZoM0toVk5YTG9CWndTSldQODVuVlE/oda/public/values?alt=json',
    "tw" => 'https://spreadsheets.google.com/feeds/cells/0AvKY1T4Hb-_GdG1LZFhDNFpmcFNKZmt0LTZHcmllM2c/oda/public/values?alt=json',
    "ru" => 'https://spreadsheets.google.com/feeds/cells/0AqlIQacaL79AdFlCV2dOaTdzYlhsaHF3UVk0b2JlVVE/oda/public/values?alt=json',
    "fr" => 'https://spreadsheets.google.com/feeds/cells/0AqlIQacaL79AdDdEYVNaYWt3LUo0emxWenhMakRvYXc/oda/public/values?alt=json'
  );
  foreach($translations as $language=>$translation) {
    $count = 0;
    $questions = json_decode(file_get_contents($translation));
    echo count($questions->feed->entry)." cells loaded\n";
    $questionsArray = array();
    foreach($questions->feed->entry as $cell) {
      $cell = $cell->{'gs$cell'};
      if(!isset($questionsArray[$cell->row])) $questionsArray[$cell->row] = array();
      $questionsArray[$cell->row][$cell->col] = $cell->{'$t'};
    }
    foreach($questionsArray as $row) {
      if(isset($row[1]) && $row[1] == "Number") continue;
      if(!isset($row[2]) || !$row[2]) continue; # skip questions not marked as "done"
      $id = $row[1];
      $question = $db->real_escape_string(strip_tags($row[9]));
      $answer = $db->real_escape_string(strip_tags($row[10]));
      $db->query("REPLACE INTO question_translations SET question_id='".$id."', language_id=(SELECT id FROM languages WHERE code='".$language."' LIMIT 1), question='".$question."', answer='".$answer."'") or die($db->error);
      $count++;
    }
    echo "$count questions translated to $language\n";
  }
}
#*/
$db->close();

