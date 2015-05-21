<?php
require("config.php");
session_start();
$db = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
$db->set_charset("utf8");

header("Content-type: application/json");

// Authenticate the user through the Google API and return their data
function auth($db, $token = "") {
  $auth = isset($_SESSION['auth']) ? $_SESSION['auth']:"";
  $query = "SELECT * FROM users WHERE email = '".$db->real_escape_string($auth)."' LIMIT 1";
  $result = $db->query($query) or die($db->error());
  $user = $result->fetch_assoc();
  $result->free();
  if($user) {
    if(!isset($user['languages']) || empty($user['languages'])) $user['languages'] = array();
    else $user['languages'] = array_map('intval',explode(',',$user['languages']));
    return $user;
  } elseif($auth) {
    return array("error"=>"unauthorized");
  } elseif($token) {
    $postData = "code=".urlencode($token).
                "&client_id=".urlencode(GAPPS_CLIENTID).
                "&client_secret=".urlencode(GAPPS_CLIENTSECRET).
                "&redirect_uri=".urlencode(GAPPS_REDIRECT).
                "&grant_type=authorization_code";
    $ch = curl_init();
    curl_setopt($ch,CURLOPT_URL, "https://www.googleapis.com/oauth2/v3/token");
    curl_setopt($ch,CURLOPT_POST, count($postData));
    curl_setopt($ch,CURLOPT_POSTFIELDS, $postData);
    curl_setopt($ch,CURLOPT_RETURNTRANSFER,true);
    $result = json_decode(curl_exec($ch));
    curl_close($ch);
    if(isset($result->error)) {
      return array("error"=>"invalid_token");
    } else {
      $token = $result->access_token;
      $userinfo = json_decode(file_get_contents("https://www.googleapis.com/oauth2/v2/userinfo?access_token=".$token));
      if($userinfo->verified_email) {
        $_SESSION['auth'] = $userinfo->email;
        return auth($db);
      } else {
        return array("error"=>"invalid_email");
      }
    }
  } else {
    $url = 'https://accounts.google.com/o/oauth2/auth?'.
           'scope=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email'.
           '&response_type=code'.
           '&redirect_uri='.urlencode(GAPPS_REDIRECT).
           '&client_id='.urlencode(GAPPS_CLIENTID);
    return array("login"=>$url);
  }
}

// get a list of all questions with sets and languages
function getQuestions($db) {
  $query = "SELECT q.*, GROUP_CONCAT(DISTINCT set_id) sets, GROUP_CONCAT(DISTINCT qt.language_id) languages FROM questions q
        LEFT JOIN question_cards qc ON qc.question_id = q.id
        LEFT JOIN card_sets cs ON cs.card_id = qc.card_id
        LEFT JOIN sets s ON s.id = cs.set_id
        LEFT JOIN question_translations qt ON qt.question_id = q.id
        WHERE s.regular = 1 AND q.live = 1
        GROUP BY q.id, qc.card_id";
  $result = $db->query($query) or die($db->error());
  $questions = array();
  while($row = $result->fetch_assoc()) {
    $row["difficulty"] = intval($row["difficulty"]);
    $row["id"] = intval($row["id"]);
    $row["sets"] = array_map('intval',explode(",",$row["sets"]));
    $row["languages"] = array_map('intval',explode(",",$row["languages"]));
    if(!$row["author"]) unset($row["author"]);
    if(!isset($questions[$row["id"]])) {
      $questions[$row["id"]] = $row;
      $questions[$row["id"]]['cards'] = array();
      unset($questions[$row["id"]]["sets"]);
      unset($questions[$row["id"]]["live"]);
    }
    array_push($questions[$row["id"]]['cards'], $row["sets"]);
  }
  $result->free();
  return array_values($questions);
}

// get a single question with cards and texts
function getQuestion($db, $id = false, $lang = false) {
  $output = array();
  if($id && $lang && intval($id) && intval($lang)) {
    $query = "SELECT c.*, IFNULL(ct.name, c.name) name, c.name name_en, qt.question, qt.answer FROM question_cards qc
          LEFT JOIN cards c ON c.id = qc.card_id
          LEFT JOIN card_translations ct ON ct.card_id = qc.card_id AND ct.language_id = ".$db->real_escape_string($lang)."
          LEFT JOIN question_translations qt ON qt.question_id = qc.question_id AND qt.language_id = ".$db->real_escape_string($lang)."
          WHERE qc.question_id = ".$db->real_escape_string($id)."
          ORDER BY c.layout, c.id ASC";
    $result = $db->query($query) or die($db->error);
    $output = array("cards"=>array());
    while($row = $result->fetch_assoc()) {
      $output["question"] = strip_tags($row["question"]);
      $output["answer"] = strip_tags($row["answer"]);
      unset($row["question"]);
      unset($row["answer"]);
      $row["text"] = nl2br($row["text"]);
      foreach($row as $field=>$value) {
        if($value === "" || $value === null || $field == "id") unset($row[$field]);
      }
      array_push($output["cards"], $row);
    }
    $result->free();
  }
  return $output;
}

// get a list of sets
function getSets($db) {
  $query = "SELECT id, name, code, releasedate, standard, modern FROM sets
        WHERE regular = 1
        ORDER BY releasedate DESC";
  $result = $db->query($query) or die($db->error());
  $output = array();
  while($row = $result->fetch_assoc()) {
    $row["id"] = intval($row["id"]);
    $row["standard"] = intval($row["standard"]);
    $row["modern"] = intval($row["modern"]);
    array_push($output, $row);
  }
  $result->free();
  return $output;
}

// get all the data for offline mode
function getQuestionsAndCards($db) {
  $questionQuery = "SELECT qt.* FROM question_translations qt
    LEFT JOIN questions q ON q.id = qt.question_id
    WHERE q.live = 1";
  $result = $db->query($questionQuery) or die($db->error());
  $questions = array();
  while($row = $result->fetch_assoc()) {
    if(!isset($questions[$row['question_id']])) $questions[$row['question_id']] = array();
    $questions[$row['question_id']][$row['language_id']] = array(
      "question" => $row["question"],
      "answer" => $row["answer"]
    );
  }
  $result->free();
  $cardQuery = "SELECT c.*, GROUP_CONCAT(language_id,':',ct.name SEPARATOR '|') AS translations,
    GROUP_CONCAT(DISTINCT qc.question_id) questions FROM cards c
    LEFT JOIN card_translations ct ON ct.card_id = c.id
    LEFT JOIN question_cards qc ON qc.card_id = c.id
    WHERE question_id
    GROUP BY c.id";
  $result = $db->query($cardQuery) or die($db->error());
  $cards = array();
  while($row = $result->fetch_assoc()) {
    if ( $row['translations'] != null ) {
      $translations = explode( "|", $row['translations'] );
      $row['translations'] = array();
      foreach ( $translations as $translation ) {
        $translation = explode( ":", $translation, 2 );
        $row['translations'][ $translation[0] ] = $translation[1];
      }
    }
    $questionIds = explode(",",$row['questions']);
    foreach($questionIds as $question) {
      if(!isset($questions[$question]["cards"])) $questions[$question]["cards"] = array();
      array_push($questions[$question]["cards"], $row['id']);
    }
    foreach($row as $field=>$value) {
      if($value === "" || $value === null || $field == "questions") unset($row[$field]);
    }
    $cards[$row['id']] = $row;
  }
  return array("questions"=>$questions, "cards"=>$cards);
}

function getAdminQuestions($db, $page) {
  $user = auth($db);
  $pagesize = 20;
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor", "translator"))){
    $start = intval($page) * $pagesize;
    $query = "SELECT SQL_CALC_FOUND_ROWS q.*,
      GROUP_CONCAT(DISTINCT c.name SEPARATOR '|') cards,
      GROUP_CONCAT(DISTINCT qt2.language_id) languages,
      GROUP_CONCAT(DISTINCT qt3.language_id) outdated
      FROM questions q
      LEFT JOIN question_cards qc ON qc.question_id = q.id
      LEFT JOIN cards c ON qc.card_id = c.id
      LEFT JOIN question_translations qt ON qt.question_id = q.id AND qt.language_id = 1
      LEFT JOIN question_translations qt2 ON qt2.question_id = q.id
      LEFT JOIN question_translations qt3 ON qt3.question_id = q.id AND qt3.changedate < qt.changedate
      GROUP BY q.id
      ORDER BY q.id DESC
      LIMIT $start, $pagesize;";
    $result = $db->query($query) or die($db->error);
    $questions = array();
    while(count($questions) < $pagesize && $row = $result->fetch_assoc()) {
      $row['id'] = intval($row['id']);
      $row['difficulty'] = intval($row['difficulty']);
      $row['live'] = !!$row['live'];
      $row['cards'] = explode("|", $row['cards']);
      $row['languages'] = array_map("intval",explode(",", $row['languages']));
      if(!$row['author']) unset($row['author']);
      if($row['outdated']) $row['outdated'] = array_map("intval",explode(",", $row['outdated']));
      else unset($row['outdated']);
      array_push($questions, $row);
    }
    $result->free();
    $query = "SELECT FOUND_ROWS() rows;";
    $result = $db->query($query) or die($db->error);
    $total = $result->fetch_assoc();
    $result->free();
    $response = array("questions"=>$questions, "pages"=>ceil($total['rows']/$pagesize));
    return $response;
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return array();
  }
}

function getAdminQuestion($db, $id) {
  $user = auth($db);
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor", "translator"))){
    $query = "SELECT q.*, qt.question, qt.answer, qt.changedate, GROUP_CONCAT(DISTINCT c.id,':',c.name SEPARATOR '|') cards
       FROM questions q
       LEFT JOIN question_cards qc ON qc.question_id = q.id
       LEFT JOIN cards c ON c.id = qc.card_id
       LEFT JOIN question_translations qt ON qt.question_id = q.id
       WHERE q.id = '".$db->real_escape_string($id)."' AND qt.language_id = 1
       GROUP BY q.id";
    $result = $db->query($query) or die($db->error);
    $question = $result->fetch_assoc();
    $question['difficulty'] = intval($question['difficulty']);
    $question['id'] = intval($question['id']);
    $question['live'] = !!$question['live'];
    $cards = explode("|",$question['cards']);
    $question['cards'] = array();
    foreach($cards as $card) {
      $card = explode(":",$card,2);
      $question['cards'][] = array("id"=>intval($card[0]),"name"=>$card[1]);
    }
    $result->free();
    return $question;
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return array();
  }
}

function getAdminSuggest($db, $name) {
  $query = "SELECT id, name FROM `cards`
     WHERE name LIKE '".$db->real_escape_string($name)."%'
     ORDER BY name ASC LIMIT 10";
  $result = $db->query($query) or die($db->error);
  $cards = array();
  while($row = $result->fetch_assoc()) {
    $row['id'] = intval($row['id']);
    array_push($cards, $row);
  }
  $result->free();
  return $cards;
}

function postAdminSave($db) {
  $user = auth($db);
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor"))){
    $question = json_decode(file_get_contents('php://input'));
    if(intval($question->id)) {
      // question basics
      $parameters = array();
      if(isset($question->live)) $parameters[] = "live = '".intval($question->live)."'";
      if(isset($question->author)) $parameters[] = "author = '".$db->real_escape_string($question->author)."'";
      if(isset($question->difficulty)) $parameters[] = "difficulty = '".intval($question->difficulty)."'";
      if(count($parameters)) $db->query("UPDATE questions SET ".join(",",$parameters)." WHERE id = '".intval($question->id)."' LIMIT 1") or die($db->error);
      // english text
      if(isset($question->question)) {
        $query = "UPDATE question_translations SET
          question = '".$db->real_escape_string($question->question)."',
          answer = '".$db->real_escape_string($question->answer)."'
          WHERE question_id = '".intval($question->id)."' AND language_id = 1 LIMIT 1";
        $db->query($query) or die($db->error);
      }
      // cards
      if(isset($question->cards)) {
        $db->query("DELETE FROM question_cards WHERE question_id = '".intval($question->id)."'") or die($db->error);
        $cards = array();
        foreach($question->cards as $card) {
          if(intval($card->id)) $cards[] = "(".intval($question->id).",".intval($card->id).")";
        }
        $query = "INSERT INTO question_cards (question_id, card_id) VALUES ".join(",",$cards);
        $db->query($query) or die($db->error);
      }
      return "success";
    } else {
      return "missingid";
    }
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return "unauthorized";
  }
}

function deleteAdminQuestion($db, $id) {
  $user = auth($db);
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor"))){
    if(intval($id)) {
      $query = "DELETE FROM questions WHERE id = '".intval($id)."' LIMIT 1";
      $db->query($query) or die($db->error);
      return "success";
    } else {
      return "missingid";
    }
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return "unauthorized";
  }
}

function getAdminTranslations($db, $language) {
  $user = auth($db);
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor", "translator"))
     && (!count($user['languages']) || in_array($language,$user['languages']))) {
    $language = intval($language);
    $query = "SELECT qt.question_id, qt2.changedate, q.live, GROUP_CONCAT(IFNULL(ct.name, c.name) SEPARATOR '|') cards,
      IF(qt2.question IS NULL OR qt2.answer IS NULL,'untranslated',IF(qt.changedate > qt2.changedate,'outdated','translated')) status
      FROM question_translations qt
      LEFT JOIN question_translations qt2 ON qt2.question_id = qt.question_id AND qt2.language_id = '$language'
      LEFT JOIN questions q ON q.id = qt.question_id
      LEFT JOIN question_cards qc ON qc.question_id = qt.question_id
      LEFT JOIN cards c ON c.id = qc.card_id
      LEFT JOIN card_translations ct ON ct.card_id = qc.card_id AND ct.language_id = '$language'
      WHERE qt.language_id = 1
      GROUP BY qt.question_id
      ORDER BY qt.question_id DESC";
    $result = $db->query($query) or die($db->error);
    $translations = array();
    while($row = $result->fetch_assoc()) {
      $row['question_id'] = intval($row['question_id']);
      $row['live'] = !!$row['live'];
      $row['cards'] = explode("|", $row['cards']);
      foreach($row as $field=>$value) {
        if($value === null) unset($row[$field]);
      }
      $translations[] = $row;
    }
    $result->free();
    return $translations;
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return array();
  }
}

if(isset($_GET['action'])) {
  switch(strtolower($_GET['action'])) {
    case "questions":
      echo json_encode(getQuestions($db));
      break;
    case "sets":
      echo json_encode(getSets($db));
      break;
    case "question":
      if(!isset($_GET['id'])) $_GET['id'] = 0;
      if(!isset($_GET['lang'])) $_GET['lang'] = 0;
      echo json_encode(getQuestion($db, $_GET['id'], $_GET['lang']));
      break;
    case "offline":
      echo json_encode(getQuestionsAndCards($db));
      break;
    case "auth":
      if(!isset($_GET['token'])) $_GET['token'] = "";
      echo json_encode(auth($db, $_GET['token']));
      break;
    case "admin-questions":
      if(!isset($_GET['page'])) $_GET['page'] = 0;
      echo json_encode(getAdminQuestions($db, $_GET['page']));
      break;
    case "admin-question":
      if(!isset($_GET['id'])) $_GET['id'] = 0;
      echo json_encode(getAdminQuestion($db, $_GET['id']));
      break;
    case "admin-suggest":
      if(!isset($_GET['name'])) $_GET['name'] = "";
      echo json_encode(getAdminSuggest($db, $_GET['name']));
      break;
    case "admin-save":
      echo json_encode(postAdminSave($db));
      break;
    case "admin-delete":
      if(!isset($_GET['id'])) $_GET['id'] = 0;
      echo json_encode(deleteAdminQuestion($db, $_GET['id']));
      break;
    case "admin-translations":
      if(!isset($_GET['lang'])) $_GET['lang'] = 0;
      echo json_encode(getAdminTranslations($db, $_GET['lang']));
      break;
  }
}
