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
/backend/?action=questions
/backend/?action=sets
/backend/?action=offline
/fonts/ionicons.eot?v=2.0.1
/fonts/ionicons.woff?v=2.0.1
/fonts/ionicons.svg?v=2.0.1
/fonts/ionicons.ttf?v=2.0.1
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