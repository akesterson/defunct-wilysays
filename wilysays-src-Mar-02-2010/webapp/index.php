<?php

$db = mysql_connect("localhost", "akesterson", "fadmin");
if ( !$db ) {
	die("Unable to connect to mysql database");
}

mysql_select_db("akesterson", $db);

if ( isset($_REQUEST["op"]) ) {
	if ( strcmp($_REQUEST["op"], "store") == 0 ) {
		$query = ("INSERT INTO wilysays_highscores (score, name, maxpattern, dtime) VALUES (" . 
					(int)$_REQUEST["score"] . ", \"" . mysql_real_escape_string($_REQUEST["name"]) . "\", " . (int)$_REQUEST["maxpattern"] . ", NOW() );");
		//printf($query);
		$res = mysql_query($query, $db);
		if ( !$res ) 
			die("Unable to insert into the database - WTF?. " . mysql_error($db));
		printf("<html><body>\n<center>Groovy</center>\n</body></html>");
	}
	die();
}
?>

<html>
<body bgcolor="black" text="white">
<center>
	<h1>MEGA MAN: Wily Says!</h1>
	<h3>Leaderboards</h3>
	<h4>Click <a href="http://www.aklabs.net/~akesterson/wilysays/game.html">HERE</a> to play the mega-hit game!</h4>
	<h4>Click <a href="http://www.aklabs.net/~akesterson/wilysays/help.html">HERE</a> for instructions on HOW to play the mega-hit game!</h4>
</center>
<table cols=3 align="center" >
	<tr>
		<td valign="top" width="171" ><img src="megaman.png"/></td>
		<td valign="top" >

<?php
$totalRows = 0;
$curPage = 0;
$rowsPerPage = 5;
$sortOrder = 1;

if ( isset($_REQUEST["perpage"]) ) {
	$rowsPerPage = (int)$_REQUEST["perpage"];
}
if ( isset($_REQUEST["start"]) ) {
    $curPage = ((int)$_REQUEST["start"])/$rowsPerPage;
}
if ( isset($_REQUEST["sort"]) ) {
	$sortOrder = (int)$_REQUEST["sort"];
}

$totalPages = $totalRows/$rowsPerPage;

$query = "SELECT COUNT(*) AS count FROM wilysays_highscores;";
$res = mysql_query($query, $db);
if ( $res ) {
	$row = mysql_fetch_array($res);
	$totalRows = $row["count"];
}

$query = "SELECT * FROM wilysays_highscores";

if ( $sortOrder == 0 ) {
	$query .= " ORDER BY name ASC";
} else if ( $sortOrder == 1 ) {
	$query .= " ORDER BY score DESC ";
} else if ( $sortOrder == 2 ) {
	$query .= " ORDER BY maxpattern DESC ";
} else if ( $sortOrder == 3 ) {
	$query .= " ORDER BY dtime DESC ";
}
 
$query .= " LIMIT " . $rowsPerPage . " OFFSET " . ($curPage*$rowsPerPage) . ";";

///printf($query);

$res = mysql_query($query, $db);
if ( $res ) {
	printf("\t\t\t<table align=center cols=4 width=440 border=1>\n");
	printf("<tr>\n");
	if ( $curPage > 0 )
		printf("    <td colspan=2 align=left><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?perpage=%d&start=%d\">&lt;&lt; PREVIOUS</td>\n", $rowsPerPage, (($curPage*$rowsPerPage)-$rowsPerPage));
	else
		printf("    <td colspan=2></td>\n");
	
	if ( $totalRows > ($curPage * $rowsPerPage) )
		printf("    <td colspan=2 align=right><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?perpage=%d&start=%d\">NEXT &gt;&gt;</a></td>\n", $rowsPerPage, (($curPage*$rowsPerPage)+$rowsPerPage));
	else
		printf("    <td colspan=2></td>\n");
	printf("</tr>\n");
	
	printf("\t\t\t\t<tr><td><b><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?start=%d&sort=0\">Player<br/>Name</a></b></td><td><b><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?start=%d&sort=1\">Total<br/>Score</a></b></td><td><b><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?start=%d&sort=2\">Longest<br/>Pattern</a></b></td><td><b><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?start=%d&sort=3\">When<br/>Recorded</a></b></td></tr>\n",
		   ($curPage*$rowsPerPage), ($curPage*$rowsPerPage), ($curPage*$rowsPerPage), ($curPage*$rowsPerPage));
	while ( $row = mysql_fetch_array($res) ) {
		printf("\t\t\t\t<tr>\n");
		printf("\t\t\t\t\t<td>" . $row["name"] . "</td>\n");
		printf("\t\t\t\t\t<td>" . $row["score"] . "</td>\n");
		printf("\t\t\t\t\t<td>" . $row["maxpattern"] . "</td>\n");
		printf("\t\t\t\t\t<td>" . $row["dtime"] . "</td>\n");
		printf("\t\t\t\t</tr>\n");
	}
	printf("<tr>\n");
	if ( $curPage > 0 )
		printf("    <td colspan=2 align=left><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?perpage=%d&start=%d\">&lt;&lt; PREVIOUS</td>\n", $rowsPerPage, (($curPage*$rowsPerPage)-$rowsPerPage));
	else
		printf("    <td colspan=2></td>\n");
	
	if ( $totalRows > ($curPage * $rowsPerPage) )
		printf("    <td colspan=2 align=right><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?perpage=%d&start=%d\">NEXT &gt;&gt;</a></td>\n", $rowsPerPage, (($curPage*$rowsPerPage)+$rowsPerPage));
	else
		printf("    <td colspan=2></td>\n");
	printf("</tr>\n");

	printf("\t\t\t</table>\n");
}

?>

		</td>	
 		<td valign="top" ><img src="wily.png"/></td>
	</tr>
</table>

<center>
<br/><br/><i>"A fabulous tour de force..." -- Game Misinformer Bragazine</i>
<br/><br/><i>"Quite possibly the most important thing to happen to 
<br/>video games since Shigeru Miyamoto." -- Protendo Trading Cards</i>
<br/><br/><i>"I believe we made the most beautiful thing in the world. Nobody 
<br/>would criticize a renowned architect's blueprint that the position 
<br/>of a gate is wrong. It's the same as that." --Ken Kutaragi</i>
</center>
</body>
</html>
