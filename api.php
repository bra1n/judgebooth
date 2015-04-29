<?php
$db = new mysqli('localhost', 'root', 'root', 'judgebooth');
$db->set_charset("utf8");

header("Content-type: application/json");

if(isset($_GET['action'])) {
  switch(strtolower($_GET['action'])) {
    case "questions":
      $query = "SELECT q.*, GROUP_CONCAT(DISTINCT set_id) sets, GROUP_CONCAT(DISTINCT qt.language_id) languages FROM questions q
        LEFT JOIN question_cards qc ON qc.question_id = q.id
        LEFT JOIN card_sets cs ON cs.card_id = qc.card_id
        LEFT JOIN sets s ON s.id = cs.set_id
        LEFT JOIN question_translations qt ON qt.question_id = q.id
        WHERE s.regular = 1 AND q.live = 1
        GROUP BY q.id, qc.card_id";
	    $result = $db->query($query) or die($db->error());
      $output = array();
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
      echo json_encode(array_values($questions));
      break;
    case "sets":
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
      echo json_encode($output);
      break;
    case "question":
      if(isset($_GET['id']) && isset($_GET['lang']) && intval($_GET['id']) && intval($_GET['lang'])) {
        $query = "SELECT c.*, IFNULL(ct.name, c.name) name, qt.question, qt.answer FROM question_cards qc
          LEFT JOIN cards c ON c.id = qc.card_id
          LEFT JOIN card_translations ct ON ct.card_id = qc.card_id AND ct.language_id = ".$db->real_escape_string($_GET['lang'])."
          LEFT JOIN question_translations qt ON qt.question_id = qc.question_id AND qt.language_id = ".$db->real_escape_string($_GET['lang'])."
          WHERE qc.question_id = ".$db->real_escape_string($_GET['id']);
        $result = $db->query($query) or die($db->error);
        $output = array("cards"=>array());
        while($row = $result->fetch_assoc()) {
          $output["question"] = $row["question"];
          $output["answer"] = $row["answer"];
          unset($row["question"]);
          unset($row["answer"]);
          foreach($row as $field=>$value) {
            if($value === "" || $value === null || $field == "id") unset($row[$field]);
          }
          array_push($output["cards"], $row);
        }
        $result->free();
        echo json_encode($output);
      }
      break;
  }
}