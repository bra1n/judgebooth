<?php
date_default_timezone_set("Europe/Berlin");
$version = date("Ymd");
header("Content-type: text/cache-manifest");
header("Cache-Control: no-cache, private");
?>
CACHE MANIFEST
# Version <?php echo $version; ?>

CACHE:
/
/index.html
/offline.html
/backend/?action=questions
/backend/?action=sets
/backend/?action=offline
https://fonts.googleapis.com/css?family=Roboto:400,700&subset=cyrillic,latin
<?php
// list all files
$dirs = array("css","fonts","images","js","views");
foreach($dirs as $dir) {
  if ($handle = opendir("../".$dir)) {
    while (false !== ($entry = readdir($handle))) {
      if(!is_dir("../".$dir."/".$entry)) echo "/$dir/$entry\n";
    }
    closedir($handle);
  }
}
?>

NETWORK:
*