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
</center>
<table cols=3 width=800 align="center" >
	<tr>
		<td valign="top" width="171" ><img src="megaman.png"/></td>
		<td valign="top" >

<?php
$totalRows = 0;
$curPage = 0;
$rowsPerPage = 5;

if ( isset($_REQUEST["perpage"]) ) {
	$rowsPerPage = (int)$_REQUEST["perpage"];
}
if ( isset($_REQUEST["start"]) ) {
    $curPage = ((int)$_REQUEST["start"])/$rowsPerPage
}

$totalPages = $totalRows/$rowsPerPage;

$query = "SELECT COUNT(*) AS count FROM wilysays_highscores;"
$res = mysql_query($query, $db);
if ( $res ) {
	$row = mysql_fetch_row_assoc($res);
	$totalRows = $row["count"];
}

$query = "SELECT * FROM wilysays_highscores ORDER BY score, maxpattern, dtime, name ASC LIMIT " . $rowsPerPage . " OFFSET " . ($curPage*$rowsPerPage) . ";";

///printf($query);

$res = mysql_query($query, $db);
if ( $res ) {
	printf("\t\t\t<table align=center cols=4 width=379 border=1>\n");
	printf("\t\t\t\t<tr><td><b>Player<br/>Name</b></td><td><b>Total<br/>Score</b></td><td><b>Longest<br/>Pattern</b></td><td><b>When<br/>Recorded</b></td></tr>\n");
	while ( $row = mysql_fetch_array($res) ) {
		printf("\t\t\t\t<tr>\n");
		printf("\t\t\t\t\t<td>" . $row["name"] . "</td>\n");
		printf("\t\t\t\t\t<td>" . $row["score"] . "</td>\n");
		printf("\t\t\t\t\t<td>" . $row["maxpattern"] . "</td>\n");
		printf("\t\t\t\t\t<td>" . $row["dtime"] . "</td>\n");
		printf("\t\t\t\t</tr>\n");
	}
	printf("\t\t\t</table>\n");
}

?>

		</td>	
 		<td valign="top" ><img src="wily.png"/></td>
	</tr>
<?php

if ( $curPage < ($totalPages-1) ) {
	echo "<tr>";
	echo "    <td colspan=2><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?perpage=" . $rowsPerPage ."&start=". $curPage ."\"><< PREVIOUS</td>";
	echo "    <td colspan=2><a href=\"http://www.aklabs.net/~akesterson/wilysays/index.php?perpage=" . $rowsPerPage ."&start=". $curPage ."\">NEXT >></a></td>";
	echo "</tr>";
}

?>
</table>
</body>
</html>
