<?php
$db = new mysqli('127.0.0.1', 'root', 'root', 'judgebooth');
$db->set_charset("utf8");

header("Content-type: application/json");

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
  }
}
