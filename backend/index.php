<?php
require("config.php");
define('MONTH', 60*60*24*30);
// server should keep session data for AT LEAST 1 month
ini_set('session.gc_maxlifetime', MONTH);
// each client should remember their session id for EXACTLY 1 month
session_set_cookie_params(MONTH);
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
    header('HTTP/1.0 401 Unauthorized');
    return array("error"=>"No account found");
  } elseif($token) {
    $postData = "code=".urlencode($token).
                "&client_id=".urlencode(GAPPS_CLIENTID).
                "&client_secret=".urlencode(GAPPS_CLIENTSECRET).
                "&redirect_uri=".urlencode(GAPPS_REDIRECT).
                "&grant_type=authorization_code";
    $ch = curl_init();
    curl_setopt($ch,CURLOPT_URL, "https://www.googleapis.com/oauth2/v3/token");
    curl_setopt($ch,CURLOPT_POST, true);
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
  $query = "SELECT q.*, GROUP_CONCAT(DISTINCT set_id) sets, GROUP_CONCAT(DISTINCT qto.language_id) languages FROM questions q
        LEFT JOIN question_cards qc ON qc.question_id = q.id
        LEFT JOIN card_sets cs ON cs.card_id = qc.card_id
        LEFT JOIN sets s ON s.id = cs.set_id
        LEFT JOIN question_translations qt ON qt.question_id = q.id AND qt.language_id = 1
		LEFT JOIN question_translations qto ON qto.question_id = q.id AND qto.changedate >= qt.changedate
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
    // get question metadata
    $query = "SELECT q.*, qt.question, qt.answer, IF(qto.changedate > qt.changedate, true, false) as outdated
          FROM questions q
          LEFT JOIN question_translations qt ON qt.question_id = q.id AND qt.language_id = ".$db->real_escape_string($lang)."
          LEFT JOIN question_translations qto ON qto.question_id = q.id AND qto.language_id = 1
          WHERE q.id = ".$db->real_escape_string($id)."
          LIMIT 1";
    $result = $db->query($query) or die($db->error);
    $output = array("metadata"=>$result->fetch_assoc());
    if(isset($output['metadata'])) {
      $output['cards'] = array();
      $output["question"] = strip_tags($output["metadata"]["question"]);
      unset($output["metadata"]["question"]);
      $output["answer"] = strip_tags($output["metadata"]["answer"]);
      unset($output["metadata"]["answer"]);
      $output["metadata"]["live"] = !!($output["metadata"]["live"]);
      $output["metadata"]["outdated"] = !!($output["metadata"]["outdated"]);
      $output["metadata"]["id"] = intval($output["metadata"]["id"]);
      $output["metadata"]["difficulty"] = intval($output["metadata"]["difficulty"]);
    }
    $result->free();
    $query = "SELECT c.*, IFNULL(ct.name, c.name) name, c.name name_en, IFNULL(ct.multiverseid, c.multiverseid) multiverseid
          FROM question_cards qc
          LEFT JOIN cards c ON c.id = qc.card_id
          LEFT JOIN card_translations ct ON ct.card_id = qc.card_id AND ct.language_id = ".$db->real_escape_string($lang)."
          WHERE qc.question_id = ".$db->real_escape_string($id)."
          ORDER BY qc.sort ASC, c.layout, name ASC";
    $result = $db->query($query) or die($db->error);
    while($row = $result->fetch_assoc()) {
      $row["text"] = nl2br($row["text"]);
      $row["multiverseid"] = intval($row["multiverseid"]);
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
    GROUP BY c.id
    ORDER BY qc.sort ASC, c.layout, c.name ASC";
  $result = $db->query($cardQuery) or die($db->error);
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
  $pagesize = 10;
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor", "translator"))){
    $start = intval($page) * $pagesize;
    $query = "SELECT SQL_CALC_FOUND_ROWS q.*,
      GROUP_CONCAT(DISTINCT c.name ORDER BY sort ASC SEPARATOR '|') cards,
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
    // get question details
    $query = "SELECT q.*,
       GROUP_CONCAT(DISTINCT c.id,':',c.name ORDER BY sort ASC SEPARATOR '|') cards,
       GROUP_CONCAT(DISTINCT qt.language_id SEPARATOR '|') languages
       FROM questions q
       LEFT JOIN question_cards qc ON qc.question_id = q.id
       LEFT JOIN cards c ON c.id = qc.card_id
       LEFT JOIN question_translations qt ON qt.question_id = q.id
       WHERE q.id = '".$db->real_escape_string($id)."'
       GROUP BY q.id";
    $result = $db->query($query) or die($db->error);
    $question = $result->fetch_assoc();
    $question['id'] = intval($question['id']);
    $question['live'] = !!$question['live'];
    $cards = explode("|",$question['cards']);
    $question['languages'] = explode("|",$question['languages']);
    $question['cards'] = array();
    foreach($cards as $card) {
      $card = explode(":",$card,2);
      $question['cards'][] = array("id"=>intval($card[0]),"name"=>$card[1]);
    }
    $result->free();

    // get english question text
    $query = "SELECT qt.question, qt.answer, qt.changedate
           FROM question_translations qt
           WHERE qt.question_id = '".$db->real_escape_string($id)."' AND qt.language_id = 1";
    $result = $db->query($query) or die($db->error);
    $question = array_merge($question, $result->fetch_assoc());
    $result->free();

    return $question;
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return array();
  }
}

function getAdminSuggest($db, $name) {
  $query = "SELECT id, name, full_name FROM `cards`
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
  $question = json_decode(file_get_contents('php://input'));
  $id = 0;
  if(isset($question->id)) $id = intval($question->id);
  if(isset($user['role']) && (!$id || ($id && in_array($user['role'],array("admin", "editor"))))){
    if(!$id) {
      $query = "SELECT MAX(id)+1 id FROM questions";
      $result = $db->query($query) or die($db->error);
      $id = $result->fetch_assoc()['id'];
      $result->free();
      $question->live = 0;
      $question->minor = 0;
      if(!in_array($user['role'],array("admin", "editor"))) $question->author = $user['name'];
    }
    // question basics
    $parameters = array("id = '".$id."'");
    if(isset($question->live)) $parameters[] = "live = '".intval($question->live)."'";
    if(isset($question->author)) $parameters[] = "author = '".$db->real_escape_string($question->author)."'";
    if(isset($question->difficulty)) $parameters[] = "difficulty = '".intval($question->difficulty)."'";
    $query = join(",",$parameters);
    if(count($parameters)) $db->query("INSERT INTO questions SET $query ON DUPLICATE KEY UPDATE $query") or die($db->error);
    // english text
    if(isset($question->question)) {
      $query = "REPLACE INTO question_translations SET
        question_id = '".$id."', language_id = 1,
        question = '".$db->real_escape_string($question->question)."',
        answer = '".$db->real_escape_string($question->answer)."'";
      if(isset($question->minor) && $question->minor && isset($question->changedate)) {
        $query .= ", changedate = '".$db->real_escape_string($question->changedate)."'";
      }
      $db->query($query) or die($db->error);
    }
    // cards
    if(isset($question->cards)) {
      $db->query("DELETE FROM question_cards WHERE question_id = '".$id."'") or die($db->error);
      $cards = array();
      foreach($question->cards as $index=>$card) {
        if(intval($card->id)) $cards[] = "(".$id.",".intval($card->id).",".intval($index).")";
      }
      $query = "INSERT INTO question_cards (question_id, card_id, sort) VALUES ".join(",",$cards);
      $db->query($query) or die($db->error);
    }
    return "success";
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return "unauthorized";
  }
}

function deleteAdminQuestion($db, $id) {
  $user = auth($db);
  if($_SERVER['REQUEST_METHOD'] == "POST" && isset($user['role']) && in_array($user['role'],array("admin", "editor"))){
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
  $language = intval($language);
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor", "translator"))
     && (!count($user['languages']) || in_array($language,$user['languages']))) {
    $query = "SELECT qt.question_id, qt2.changedate, q.live, GROUP_CONCAT(IFNULL(ct.name, c.name) ORDER BY sort ASC SEPARATOR '|') cards,
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

function postAdminTranslate($db) {
  $user = auth($db);
  $translation = json_decode(file_get_contents('php://input'));
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor", "translator"))
       && (!count($user['languages']) || in_array(intval($translation->language_id),$user['languages']))) {
    if(intval($translation->id) && intval($translation->language_id)) {
      if(isset($translation->question) && $translation->question
         && isset($translation->answer) && $translation->answer) {
        // insert new translation
        $query = "REPLACE INTO question_translations SET
          question_id = '".$translation->id."', language_id = '".$translation->language_id."',
          question = '".$db->real_escape_string($translation->question)."',
          answer = '".$db->real_escape_string($translation->answer)."'";
        $db->query($query) or die($db->error);
      } else {
        // delete old translation
        $query = "DELETE FROM question_translations
          WHERE question_id = '".$translation->id."' AND language_id = '".$translation->language_id."' LIMIT 1";
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

function getAdminTranslation($db, $language, $id) {
  $user = auth($db);
  $language = intval($language);
  if(isset($user['role']) && in_array($user['role'],array("admin", "editor", "translator"))
     && (!count($user['languages']) || in_array($language,$user['languages']))) {
    $query = "SELECT q.*, qt.*, qt2.question question_translated, qt2.answer answer_translated,
       qt2.changedate changedate_translated,
       GROUP_CONCAT(IFNULL(ct.name, c.name) ORDER BY sort ASC SEPARATOR '|') cards,
       GROUP_CONCAT(IFNULL(ct.multiverseid, 0) ORDER BY sort ASC SEPARATOR '|') cardids
       FROM questions q
       LEFT JOIN question_cards qc ON qc.question_id = q.id
       LEFT JOIN question_translations qt ON qt.question_id = q.id
       LEFT JOIN question_translations qt2 ON qt2.question_id = q.id AND qt2.language_id = '$language'
       LEFT JOIN cards c ON c.id = qc.card_id
       LEFT JOIN card_translations ct ON ct.card_id = qc.card_id AND ct.language_id = '$language'
       WHERE q.id = '".intval($id)."' AND qt.language_id = 1
       GROUP BY q.id";
    $result = $db->query($query) or die($db->error);
    $question = $result->fetch_assoc();
    if($question) {
      $question['difficulty'] = intval($question['difficulty']);
      $question['language_id'] = intval($language);
      unset($question['question_id']);
      $question['id'] = intval($question['id']);
      $question['live'] = !!$question['live'];
      if(isset($question['cards'])) $question['cards'] = explode("|", $question['cards']);
      if(isset($question['cardids'])) $question['cardids'] = explode("|", $question['cardids']);
    }
    $result->free();
    return $question;
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return array();
  }
}

function getAdminUsers($db) {
  $user = auth($db);
  if(isset($user['role']) && $user['role']=="admin") {
    $query = "SELECT * FROM users ORDER BY role ASC, name ASC";
    $result = $db->query($query) or die($db->error);
    $users = array();
    while($row = $result->fetch_assoc()) {
      if(empty($row['languages'])) unset($row['languages']);
      else $row['languages'] = array_map("intval",explode(",", $row['languages']));
      $users[] = $row;
    }
    $result->free();
    return $users;
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return array();
  }
}

function postAdminUser($db) {
  $user = auth($db);
  $userObj = json_decode(file_get_contents('php://input'));
  if(isset($user['role']) && $user['role']=="admin" && isset($userObj->email) && isset($userObj->name) && isset($userObj->role)){
    $query = "REPLACE INTO users SET
      name = '".$db->real_escape_string($userObj->name)."',
      email = '".$db->real_escape_string($userObj->email)."',
      role = '".$db->real_escape_string($userObj->role)."'";
    if(isset($userObj->languages) && count($userObj->languages)) {
      $query .= ", languages = '".$db->real_escape_string(join(',',$userObj->languages))."'";
    }
    $db->query($query) or die($db->error);
    return "success";
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return "unauthorized";
  }
}

function deleteAdminUser($db, $email) {
  $user = auth($db);
  if($_SERVER['REQUEST_METHOD'] == "POST" && isset($user['role']) && $user['role']=="admin" && !empty($email)){
    $query = "DELETE FROM users WHERE email = '".$db->real_escape_string($email)."' LIMIT 1";
    $db->query($query) or die($db->error);
    return "success";
  } else {
    header('HTTP/1.0 401 Unauthorized');
    return "unauthorized";
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
    case "logout":
      $_SESSION['auth'] = "";
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
    case "admin-translation":
      if(!isset($_GET['id'])) $_GET['id'] = 0;
      if(!isset($_GET['lang'])) $_GET['lang'] = 0;
      echo json_encode(getAdminTranslation($db, $_GET['lang'], $_GET['id']));
      break;
    case "admin-translate":
      echo json_encode(postAdminTranslate($db));
      break;
    case "admin-users":
      echo json_encode(getAdminUsers($db));
      break;
    case "admin-saveuser":
      echo json_encode(postAdminUser($db));
      break;
    case "admin-deleteuser":
      if(!isset($_GET['email'])) $_GET['email'] = "";
      echo json_encode(deleteAdminUser($db, $_GET['email']));
      break;
    case "test-auth":
      if(strpos($_SERVER['HTTP_HOST'], 'localhost') === 0) {
        $_SESSION['auth'] = 'boothadmin@gmail.com';
      }
      break;
  }
}
